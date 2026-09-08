import std/[os, strutils]
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"
import "../../lib/vault"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["vault", "unmount"],
  kind: ckVerb,
  summary: "unmount a LUKS vault and close its mapping",
  usage: "ax vault unmount <name>",
  args: @[
    ArgSpec(name: "name", required: true,
            description: "vault name (e.g. mydata) or mount point path")
  ],
  deps: @["mount", "umount", "cryptsetup"],
  dryRun: false
)

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
  runner: Runner = defaultRunner,
  mapperProbe: MapperProbe = mapperPresent
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax vault unmount <name>

Description:
    Unmount a LUKS encrypted vault and close the cryptsetup mapping.
    Specify a vault name (e.g., 'mydata') or mount point path.

Arguments:
    name    Vault name (e.g., mydata) or mount point (e.g., ~/Vaults/mydata)

Examples:
    ax vault unmount mydata
    ax vault unmount ~/Vaults/mydata"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64
  if args.len == 0 or args[0].len == 0:
    error("Mount point or vault name required", errp)
    outp.writeLine("Usage: ax vault unmount <name>")
    return 64
  let target = if args[0] == "--": args[1] else: args[0]

  if not checkDeps(cmdSpec.deps, errp): return 2
  let mounted = runner.capture("mount", @[])
  if mounted.exitCode != 0:
    error("Cannot inspect mounted vaults", errp)
    return 1
  let resolved = resolveTarget(target, mounted.output)
  if resolved.invalid:
    error("Invalid mount point or vault not mounted: " & target, errp)
    return 1

  if not mapperProbe(resolved.mapperName):
    error("Vault mapper not found: " & resolved.mapperName, errp)
    return 1

  # A live, unmounted mapping is a recovery case: close it without umount "".
  var canClose = resolved.mountPoint.len == 0
  result = 1
  try:
    if not canClose:
      outp.writeLine("Unmounting: " & resolved.mountPoint)
      if runner.runInherited("sudo", @["umount", resolved.mountPoint]) != 0:
        return 1
      canClose = true
    result = 0
  finally:
    # Do not close a mapping whose filesystem is still mounted.
    if canClose and not closeVault(runner, resolved.mapperName, errp):
      result = 1

  if result != 0: return result
  outp.writeLine("Vault dismounted successfully")

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
