import std/[os, strutils]
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["docker", "volume", "prune"],
  kind: ckVerb,
  summary: "remove all dangling Docker volumes",
  usage: "ax docker volume prune",
  deps: @["docker"],
  dryRun: false
)

proc parseDockerList*(output: string): seq[string] =
  ## Splits `docker ... list` output on newlines, dropping the empty
  ## trailing line `splitLines` produces for a final "\n" (and any other
  ## blank lines, matching zsh's `${(f)_volumes}` word-split-on-newline,
  ## which never yields empty words from a well-formed docker listing).
  result = @[]
  for line in output.splitLines():
    if line.len == 0: continue
    result.add(line)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax docker volume prune

Remove all dangling Docker volumes (volumes not attached to any container).

Options:
    -h, --help    Show this help message

Examples:
    ax docker volume prune"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  if not checkDeps(["docker"], errp): return 2

  let listing = runner.capture(
    "docker",
    @["volume", "list", "--quiet", "--filter=dangling=true"]
  )
  if listing.exitCode != 0:
    error("Cannot list Docker volumes: " & listing.error.strip(), errp)
    return 1
  let volumes = parseDockerList(listing.output)

  if volumes.len == 0:
    info("No dangling volumes to remove.", errp)
    return 0

  for volume in volumes:
    info("Removing volume: " & volume, errp)
    let code = runner.runInherited("docker", @["volume", "rm", volume])
    if code != 0:
      return 1

  return 0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
