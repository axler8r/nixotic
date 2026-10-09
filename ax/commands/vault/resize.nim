import std/[os, strutils]
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"
import "../../lib/vault"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["vault", "resize"],
  kind: ckVerb,
  summary: "grow a LUKS vault's file, container, and filesystem",
  usage: "ax vault resize <name> --size SIZE",
  args: @[
    ArgSpec(name: "name", required: true,
            description: "vault name (e.g. mydata) or full path to the vault file")
  ],
  flags: @[
    FlagSpec(long: "size", takesValue: true,
             description: "new total target size (e.g. 5G); equal size resumes growth")
  ],
  deps: @["fallocate", "cryptsetup", "resize2fs", "e2fsck", "blkid", "stat",
          "numfmt", "losetup"],
  dryRun: false
)

type ParsedArgs* = object
  vaultInput*: string
  size*: string
  missingFlagValue*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  var i = 0
  var positionalOnly = false
  while i < args.len:
    if positionalOnly:
      result.vaultInput = args[i]
      inc i
      continue
    if args[i].startsWith("--size="):
      result.size = args[i][7 .. ^1]
      inc i
      continue
    case args[i]
    of "--":
      positionalOnly = true
      inc i
    of "--size":
      if i + 1 >= args.len:
        result.missingFlagValue = "--size"
        return result
      result.size = args[i + 1]
      i += 2
    else:
      result.vaultInput = args[i]
      inc i

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner,
  mapperProbe: MapperProbe = mapperPresent
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax vault resize <name> --size SIZE

Grow a LUKS encrypted vault's underlying file, container, and ext4 filesystem.
Vault must be dismounted before resizing. Shrinking is not supported.
Equal target size resumes interrupted growth. Do not concurrently open the vault.
Loop-device inspection requires non-interactive sudo permission; failure refuses growth.

Options:
    -h, --help    Show this help message
    --size SIZE   New total target size (e.g., 5G) — at least the current file size

Arguments:
    name    Vault name (e.g., mydata) or full path to vault file

Examples:
    ax vault resize mydata --size 5G
    ax vault resize ~/Vaults/.mydata.vault --size 10G"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64
  let parsed = parseArgs(args)
  if parsed.missingFlagValue.len > 0:
    error("Missing value for " & parsed.missingFlagValue, errp)
    return 64
  if not requireArg(parsed.vaultInput, "vault name", errp): return 64
  if not requireArg(parsed.size, "--size", errp): return 64
  if not checkDeps(cmdSpec.deps, errp): return 2

  let v = resolveVault(parsed.vaultInput)
  if not fileExists(v.vaultFile):
    error("Vault file not found: " & v.vaultFile, errp)
    return 1

  if mapperProbe(v.mapperName):
    error("Vault is currently mounted. Dismount first with:", errp)
    outp.writeLine("  ax vault unmount " & v.vaultName)
    return 1

  let statResult = runner.capture("stat", @["--format=%s", v.vaultFile])
  if statResult.exitCode != 0:
    return 1
  let currentBytes = parseInt(statResult.output.strip())

  let numfmtFrom = runner.capture("numfmt", @["--from=iec", parsed.size])
  if numfmtFrom.exitCode != 0:
    error("Invalid size: " & parsed.size, errp)
    return 1
  let targetBytes = parseInt(numfmtFrom.output.strip())

  if targetBytes < currentBytes:
    let currentIec = runner.capture("numfmt", @["--to=iec", $currentBytes])
    if currentIec.exitCode != 0: return 1
    error("ax vault resize does not support shrinking (current: " & currentIec.output.strip() &
          ", requested: " & parsed.size & ")", errp)
    return 1

  if not backingFileIdle(runner, v.vaultFile, errp): return 1
  outp.writeLine("Opening encrypted vault for filesystem validation...")
  if runner.runInherited("sudo",
      @["cryptsetup", "open", "--type", "luks", v.vaultFile, v.mapperName]) != 0:
    return 1

  result = 1
  try:
    let fs = runner.capture("sudo",
        @["blkid", "--output", "value", "--match-tag", "TYPE",
          "/dev/mapper" / v.mapperName])
    if fs.exitCode != 0:
      error("Cannot inspect vault filesystem", errp)
      return 1
    let fsType = fs.output.strip()
    if fsType != "ext4":
      error("ax vault resize only supports ext4 filesystems (found: " &
            (if fsType.len > 0: fsType else: "unknown") & ")", errp)
      return 1
    result = 0
  finally:
    if not closeVault(runner, v.mapperName, errp): result = 1
  if result != 0: return result

  # Close before growth, then reopen so the loop device sees the new size.
  # Inspect again after our own mapping has released the backing file.
  if not backingFileIdle(runner, v.vaultFile, errp): return 1
  if targetBytes > currentBytes:
    outp.writeLine("Growing vault file: " & v.vaultFile & " to " & parsed.size)
    if runner.runInherited("fallocate", @["--length", parsed.size, v.vaultFile]) != 0:
      return 1

  if runner.runInherited("sudo",
      @["cryptsetup", "open", "--type", "luks", v.vaultFile, v.mapperName]) != 0:
    return 1
  result = 1
  try:
    outp.writeLine("Resizing LUKS container...")
    if runner.runInherited("sudo", @["cryptsetup", "resize", v.mapperName]) != 0:
      return 1

    outp.writeLine("Checking filesystem before growing ext4...")
    let fsckCode = runner.runInherited("sudo", @["e2fsck", "-f", "/dev/mapper" / v.mapperName])
    if fsckCode notin [0, 1]:
      error("Filesystem check failed — filesystem was not grown; retry the same target size", errp)
      return 1

    outp.writeLine("Growing ext4 filesystem...")
    if runner.runInherited("sudo", @["resize2fs", "/dev/mapper" / v.mapperName]) != 0:
      return 1
    result = 0
  finally:
    if not closeVault(runner, v.mapperName, errp): result = 1
  if result != 0: return result

  outp.writeLine("Vault resized successfully: " & v.vaultFile & " is now " & parsed.size)
  outp.writeLine("Mount with: ax vault mount " & v.vaultName)

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
