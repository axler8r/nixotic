import std/[os, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"
import "../lib/vault"

type ParsedArgs* = object
  vaultInput*: string
  mountPoint*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  ## Mirrors the zsh original: the first arg fills vaultInput; every arg
  ## after that overwrites mountPoint, so with 3+ args the LAST one wins.
  for a in args:
    if result.vaultInput.len == 0:
      result.vaultInput = a
    else:
      result.mountPoint = a

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Mount-Vault <vault-name> [mount-point]

Mount a LUKS encrypted vault using cryptsetup and mount.
Specify a vault name (e.g., 'mydata') to mount ~/Vaults/.<name>.vault
Default mount point is ~/Vaults/<name>

Options:
    -h, --help    Show this help message

Arguments:
    vault-name      Vault name (e.g., mydata) or full path to vault file
    mount-point     Optional mount point (default: ~/Vaults/<vault-name>)

Examples:
    Mount-Vault mydata
    Mount-Vault secrets ~/mnt/secrets
    Mount-Vault ~/Vaults/.mydata.vault      # Explicit path"""
    return 0

  let parsed = parseArgs(args)
  if not requireArg(parsed.vaultInput, "vault file", errp): return 1
  if not checkDeps(["cryptsetup", "mount", "umount", "chown", "mkdir"], errp): return 2

  let v = resolveVault(parsed.vaultInput)
  if not fileExists(v.vaultFile):
    error("Vault file not found: " & v.vaultFile, errp)
    return 1

  var mountPoint = parsed.mountPoint
  if mountPoint.len == 0:
    mountPoint = getHomeDir() / "Vaults" / v.vaultName

  let mountOutput = runner.capture("mount", @[]).output
  let mapperMarker = "/dev/mapper/" & v.mapperName
  if mountOutput.contains(mapperMarker):
    error("Vault already mounted", errp)
    for line in mountOutput.splitLines():
      if line.contains(mapperMarker):
        outp.writeLine(line)
    return 1

  outp.writeLine("Opening encrypted vault: " & v.vaultFile)
  if runner.runInherited("sudo",
      @["cryptsetup", "open", "--type", "luks", v.vaultFile, v.mapperName]) != 0:
    return 1

  if not dirExists(mountPoint):
    outp.writeLine("Creating mount point: " & mountPoint)
    if runner.runInherited("mkdir", @["--parents", mountPoint]) != 0:
      discard runner.runInherited("sudo", @["cryptsetup", "close", v.mapperName])
      return 1

  outp.writeLine("Mounting to: " & mountPoint)
  if runner.runInherited("sudo",
      @["mount", "/dev/mapper" / v.mapperName, mountPoint]) != 0:
    discard runner.runInherited("sudo", @["cryptsetup", "close", v.mapperName])
    return 1

  let uid = runner.capture("id", @["-u"]).output.strip()
  let gid = runner.capture("id", @["-g"]).output.strip()
  discard runner.runInherited("sudo", @["chown", "-R", uid & ":" & gid, mountPoint])

  outp.writeLine("Vault mounted successfully at: " & mountPoint)
  0

when isMainModule:
  cliMain(run(commandLineParams()))
