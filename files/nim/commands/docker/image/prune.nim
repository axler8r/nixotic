import std/[os, strutils]
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["docker", "image", "prune"],
  kind: ckVerb,
  summary: "remove all dangling Docker images",
  usage: "ax docker image prune",
  deps: @["docker"],
  dryRun: false
)

proc parseDockerList*(output: string): seq[string] =
  ## Splits `docker ... list` output on newlines, dropping the empty
  ## trailing line `splitLines` produces for a final "\n" (and any other
  ## blank lines, matching zsh's `${(f)_ids}` word-split-on-newline, which
  ## never yields empty words from a well-formed docker listing).
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
    outp.writeLine """Usage: ax docker image prune

Remove all dangling Docker images (images without a tag).

Options:
    -h, --help    Show this help message

Examples:
    ax docker image prune"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  if not checkDeps(["docker"], errp): return 2

  let listing = runner.capture(
    "docker",
    @["image", "list", "--filter=dangling=true", "--format={{.ID}}"]
  )
  if listing.exitCode != 0:
    error("Cannot list Docker images: " & listing.error.strip(), errp)
    return 1
  let ids = parseDockerList(listing.output)

  if ids.len == 0:
    info("No dangling images to remove.", errp)
    return 0

  for id in ids:
    info("Removing image: " & id, errp)
    let code = runner.runInherited("docker", @["rmi", id])
    if code != 0:
      return 1

  return 0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
