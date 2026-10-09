import std/[os, strutils, posix]
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"
import "../../lib/vault"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["vault", "create"],
  kind: ckVerb,
  summary: "create a new LUKS vault",
  usage: "ax vault create <name> [--size SIZE] [--location DIR]",
  args: @[
    ArgSpec(name: "name", required: true,
            description: "vault name, e.g. mydata")
  ],
  flags: @[
    FlagSpec(long: "size", takesValue: true,
             description: "vault size (default: 1G)"),
    FlagSpec(long: "location", takesValue: true,
             description: "directory to store the vault file (default: ~/Vaults)")
  ],
  deps: @["fallocate", "cryptsetup", "mkfs.ext4", "mkdir", "rm"],
  dryRun: false
)

type ParsedArgs* = object
  vaultName*: string
  size*: string
  location*: string
  missingFlagValue*: string ## empty unless --size/--location had no value

proc parseArgs*(args: seq[string]): ParsedArgs =
  ## Mirrors the zsh original's while/case loop: --size and --location
  ## each consume the following token as their value (setting
  ## missingFlagValue and stopping if none follows); everything else
  ## overwrites vaultName, so with multiple stray positionals the LAST one
  ## wins.
  result.size = "1G"
  result.location = getHomeDir() / "Vaults"
  var i = 0
  var positionalOnly = false
  while i < args.len:
    if positionalOnly:
      result.vaultName = args[i]
      inc i
      continue
    if args[i].startsWith("--size="):
      result.size = args[i][7 .. ^1]
      inc i
      continue
    if args[i].startsWith("--location="):
      result.location = args[i][11 .. ^1]
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
    of "--location":
      if i + 1 >= args.len:
        result.missingFlagValue = "--location"
        return result
      result.location = args[i + 1]
      i += 2
    else:
      result.vaultName = args[i]
      inc i

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax vault create <name> [opts]

Create a new LUKS encrypted vault using fallocate, cryptsetup, and mkfs.
Specify a vault name (e.g., 'mydata') to create at ~/Vaults/.<name>.vault
Mount points are created at ~/Vaults/<name> by default.

Options:
    -h, --help          Show this help message
    --size SIZE         Vault size (default: 1G, minimum: 100M, examples: 1G, 5G, 10G)
    --location DIR      Directory to store vault file (default: ~/Vaults)

Examples:
    ax vault create mydata
    ax vault create secrets --size 1G
    ax vault create backup --size 5G
    ax vault create external --location /mnt/storage"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64
  let parsed = parseArgs(args)
  if parsed.missingFlagValue.len > 0:
    error("Missing value for " & parsed.missingFlagValue, errp)
    return 64
  if not requireArg(parsed.vaultName, "vault name", errp): return 64
  if '/' in parsed.vaultName:
    error("Vault name must be a bare name; use --location for its directory", errp)
    return 64
  if not checkDeps(cmdSpec.deps, errp): return 2

  let vaultFile = parsed.location / ("." & parsed.vaultName & ".vault")
  let mapperName = parsed.vaultName

  if not dirExists(parsed.location):
    outp.writeLine("Creating vault directory: " & parsed.location)
    if runner.runInherited("mkdir", @["--parents", parsed.location]) != 0:
      return 1

  if fileExists(vaultFile) or dirExists(vaultFile) or symlinkExists(vaultFile):
    error("Vault already exists: " & vaultFile, errp)
    return 1

  outp.writeLine("Creating vault: " & vaultFile & " (" & parsed.size & ")")
  if runner.runInherited("fallocate", @["--length", parsed.size, vaultFile]) != 0:
    return 1

  outp.writeLine("Encrypting vault with LUKS...")
  if runner.runInherited("cryptsetup",
      @["luksFormat", "--verify-passphrase", vaultFile]) != 0:
    discard runner.runInherited("rm", @["--force", vaultFile])
    return 1

  outp.writeLine("Opening encrypted vault...")
  if runner.runInherited("sudo",
      @["cryptsetup", "open", "--type", "luks", vaultFile, mapperName]) != 0:
    discard runner.runInherited("rm", @["--force", vaultFile])
    return 1

  var formatted = false
  result = 1
  try:
    outp.writeLine("Creating ext4 filesystem...")
    # Set only the new filesystem root owner. Ordinary mounting must never
    # rewrite existing file ownership, recursively or otherwise.
    let rootOwner = "root_owner=" & $getuid() & ":" & $getgid()
    formatted = runner.runInherited("sudo",
      @["mkfs.ext4", "-E", rootOwner, "-L", parsed.vaultName,
        "/dev/mapper" / mapperName]) == 0
    if formatted: result = 0
  finally:
    if not closeVault(runner, mapperName, errp):
      result = 1
    elif not formatted:
      try:
        if runner.runInherited("rm", @["--force", vaultFile]) != 0:
          warn("Could not remove failed vault creation: " & vaultFile, errp)
      except CatchableError as e:
        warn("Could not remove failed vault creation: " & e.msg, errp)

  if result != 0: return result

  outp.writeLine("Vault created successfully: " & vaultFile)
  outp.writeLine("Mount with: ax vault mount " & parsed.vaultName)

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
