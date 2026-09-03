import std/os
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"

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
  while i < args.len:
    case args[i]
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
    outp.writeLine """Usage: New-Vault <vault-name> [opts]

Create a new LUKS encrypted vault using fallocate, cryptsetup, and mkfs.
Specify a vault name (e.g., 'mydata') to create at ~/Vaults/.<name>.vault
Mount points are created at ~/Vaults/<name> by default.

Options:
    -h, --help          Show this help message
    --size SIZE         Vault size (default: 1G, minimum: 100M, examples: 1G, 5G, 10G)
    --location DIR      Directory to store vault file (default: ~/Vaults)

Examples:
    New-Vault mydata
    New-Vault secrets --size 1G
    New-Vault backup --size 5G
    New-Vault external --location /mnt/storage"""
    return 0

  let parsed = parseArgs(args)
  if parsed.missingFlagValue.len > 0:
    error("Missing value for " & parsed.missingFlagValue, errp)
    return 1
  if not requireArg(parsed.vaultName, "vault name", errp): return 1
  if not checkDeps(["fallocate", "cryptsetup", "mkdir", "rm"], errp): return 2

  let vaultFile = parsed.location / ("." & parsed.vaultName & ".vault")
  let mapperName = parsed.vaultName

  if not dirExists(parsed.location):
    outp.writeLine("Creating vault directory: " & parsed.location)
    if runner.runInherited("mkdir", @["--parents", parsed.location]) != 0:
      return 1

  if fileExists(vaultFile):
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

  outp.writeLine("Creating ext4 filesystem...")
  if runner.runInherited("sudo",
      @["mkfs.ext4", "-L", parsed.vaultName, "/dev/mapper" / mapperName]) != 0:
    discard runner.runInherited("sudo", @["cryptsetup", "close", mapperName])
    discard runner.runInherited("rm", @["--force", vaultFile])
    return 1

  outp.writeLine("Closing vault...")
  discard runner.runInherited("sudo", @["cryptsetup", "close", mapperName])

  outp.writeLine("Vault created successfully: " & vaultFile)
  outp.writeLine("Mount with: mount-vault " & vaultFile)
  0

when isMainModule:
  cliMain(run(commandLineParams()))
