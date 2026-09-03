import std/[os, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"
import "../lib/vault"

type ParsedArgs* = object
  vaultInput*: string
  size*: string
  missingFlagValue*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  var i = 0
  while i < args.len:
    case args[i]
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
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Resize-Vault <vault-name> --size SIZE

Grow a LUKS encrypted vault's underlying file, container, and ext4 filesystem.
Vault must be dismounted before resizing. Shrinking is not supported.

Options:
    -h, --help    Show this help message
    --size SIZE   New total target size (e.g., 5G) — must be larger than current size

Arguments:
    vault-name    Vault name (e.g., mydata) or full path to vault file

Examples:
    Resize-Vault mydata --size 5G
    Resize-Vault ~/Vaults/.mydata.vault --size 10G"""
    return 0

  let parsed = parseArgs(args)
  if parsed.missingFlagValue.len > 0:
    error("Missing value for " & parsed.missingFlagValue, errp)
    return 1
  if not requireArg(parsed.vaultInput, "vault name", errp): return 1
  if not requireArg(parsed.size, "--size", errp): return 1
  if not checkDeps(["fallocate", "cryptsetup", "resize2fs", "e2fsck", "blkid",
                     "stat", "numfmt"], errp): return 2

  let v = resolveVault(parsed.vaultInput)
  if not fileExists(v.vaultFile):
    error("Vault file not found: " & v.vaultFile, errp)
    return 1

  if mapperPresent(v.mapperName):
    error("Vault is currently mounted. Dismount first with:", errp)
    outp.writeLine("  dismount-vault " & v.vaultName)
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

  if targetBytes <= currentBytes:
    let currentIec = runner.capture("numfmt", @["--to=iec", $currentBytes]).output.strip()
    error("Resize-Vault does not support shrinking (current: " & currentIec &
          ", requested: " & parsed.size & ")", errp)
    return 1

  outp.writeLine("Growing vault file: " & v.vaultFile & " to " & parsed.size)
  if runner.runInherited("fallocate", @["--length", parsed.size, v.vaultFile]) != 0:
    return 1

  outp.writeLine("Opening encrypted vault...")
  if runner.runInherited("sudo",
      @["cryptsetup", "open", "--type", "luks", v.vaultFile, v.mapperName]) != 0:
    return 1

  let fsType = runner.capture("sudo",
      @["blkid", "--output", "value", "--match-tag", "TYPE",
        "/dev/mapper" / v.mapperName]).output.strip()
  if fsType != "ext4":
    error("Resize-Vault only supports ext4 filesystems (found: " &
          (if fsType.len > 0: fsType else: "unknown") & ")", errp)
    discard runner.runInherited("sudo", @["cryptsetup", "close", v.mapperName])
    return 1

  outp.writeLine("Resizing LUKS container...")
  if runner.runInherited("sudo", @["cryptsetup", "resize", v.mapperName]) != 0:
    discard runner.runInherited("sudo", @["cryptsetup", "close", v.mapperName])
    return 1

  outp.writeLine("Checking filesystem (required before growing metadata_csum/64bit ext4)...")
  let fsckCode = runner.runInherited("sudo", @["e2fsck", "-f", "/dev/mapper" / v.mapperName])
  if fsckCode > 1:
    error("Filesystem check failed — container was resized but filesystem was not grown", errp)
    discard runner.runInherited("sudo", @["cryptsetup", "close", v.mapperName])
    return 1

  outp.writeLine("Growing ext4 filesystem...")
  if runner.runInherited("sudo", @["resize2fs", "/dev/mapper" / v.mapperName]) != 0:
    discard runner.runInherited("sudo", @["cryptsetup", "close", v.mapperName])
    return 1

  outp.writeLine("Closing vault...")
  discard runner.runInherited("sudo", @["cryptsetup", "close", v.mapperName])

  outp.writeLine("Vault resized successfully: " & v.vaultFile & " is now " & parsed.size)
  outp.writeLine("Mount with: mount-vault " & v.vaultName)
  0

when isMainModule:
  cliMain(run(commandLineParams()))
