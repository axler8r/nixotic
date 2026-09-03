import std/[os, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"
import "../lib/vault"

type ResolvedTarget* = object
  mapperName*: string
  mountPoint*: string
  invalid*: bool ## true when target is neither a mounted dir nor a bare name

proc resolveTarget*(target: string, mountOutput: string): ResolvedTarget =
  ## Mirrors the zsh original: an existing directory that appears as a
  ## mount point in `mount`'s output resolves its mapper name from that
  ## line's source-device column; a target with no leading "/" is treated
  ## as the mapper/vault name directly and its mount point is looked up
  ## the same way, in reverse. Anything else is invalid. On multiple
  ## matching lines (a degenerate, unrealistic case for a single mapper),
  ## only the first match is used -- a simplification over the zsh
  ## original's `$(...)`, which would concatenate every match's field into
  ## one multi-line string that later commands could not use correctly
  ## either.
  if dirExists(target):
    for line in mountOutput.splitLines():
      if line.contains(" on " & target & " "):
        let fields = line.splitWhitespace()
        if fields.len > 0:
          result.mapperName = fields[0].replace("/dev/mapper/", "")
          result.mountPoint = target
        return result
  if not target.startsWith("/"):
    result.mapperName = target
    for line in mountOutput.splitLines():
      if line.contains("/dev/mapper/" & target & " "):
        let fields = line.splitWhitespace()
        if fields.len > 2:
          result.mountPoint = fields[2]
        return result
    return result
  result.invalid = true
  result

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Dismount-Vault <vault-name-or-mount-point>

Description:
    Unmount a LUKS encrypted vault and close the cryptsetup mapping.
    Specify a vault name (e.g., 'mydata') or mount point path.

Arguments:
    vault-name-or-mount-point    Vault name (e.g., mydata) or mount point (e.g., ~/Vaults/mydata)

Examples:
    Dismount-Vault mydata
    Dismount-Vault ~/Vaults/mydata"""
    return 0

  if args.len == 0 or args[0].len == 0:
    error("Mount point or vault name required", errp)
    outp.writeLine("Usage: Dismount-Vault <mount-point-or-vault-name>")
    return 1
  let target = args[0]

  let mountOutput = runner.capture("mount", @[]).output
  let resolved = resolveTarget(target, mountOutput)
  if resolved.invalid:
    error("Invalid mount point or vault not mounted: " & target, errp)
    return 1

  if not mapperPresent(resolved.mapperName):
    error("Vault mapper not found: " & resolved.mapperName, errp)
    return 1

  if not checkDeps(["mount", "umount", "cryptsetup"], errp): return 2

  outp.writeLine("Unmounting: " & resolved.mountPoint)
  if runner.runInherited("sudo", @["umount", resolved.mountPoint]) != 0:
    return 1

  outp.writeLine("Closing vault: " & resolved.mapperName)
  if runner.runInherited("sudo", @["cryptsetup", "close", resolved.mapperName]) != 0:
    return 1

  outp.writeLine("Vault dismounted successfully")
  0

when isMainModule:
  cliMain(run(commandLineParams()))
