import std/[os, strutils]
import "../../../lib/context"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["docker", "volume", "list"],
  kind: ckVerb,
  summary: "list Docker volumes",
  usage: "ax docker volume list [--dangling]",
  flags: @[
    FlagSpec(long: "dangling", takesValue: false,
             description: "only dangling volumes (not attached to any container)")
  ],
  deps: @["docker"],
  dryRun: false
)

proc parseDockerList*(output: string): seq[string] =
  ## Splits `docker ... list` output on newlines, dropping the empty
  ## trailing line `splitLines` produces for a final "\n" (and any other
  ## blank lines) — matches the identical helper in the image commands.
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
    outp.writeLine """Usage: ax docker volume list [--dangling]

List Docker volumes. --dangling lists only volumes not attached to any
container.

Options:
    -h, --help    Show this help message
    --dangling    Only dangling volumes
    --raw         Deprecated alias for -o plain

Examples:
    ax docker volume list
    ax docker volume list --dangling"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  var ctx = ctxFromEnv()
  var dangling = false
  for arg in args:
    if arg == "--raw":
      ctx.output = omPlain
    elif arg == "--dangling":
      dangling = true

  if not checkDeps(["docker"], errp): return 2

  var dockerArgs = @["volume", "list"]
  if dangling:
    dockerArgs.add("--filter=dangling=true")
  dockerArgs.add("--format={{.Driver}}|{{.Name}}")
  let listing = runner.capture("docker", dockerArgs)
  if listing.exitCode != 0:
    error("Cannot list Docker volumes: " & listing.error.strip(), errp)
    return 1
  let volumes = parseDockerList(listing.output)

  if volumes.len == 0:
    info((if dangling: "No dangling volumes found." else: "No volumes found."), errp)
    if ctx.output != omJson: return 0

  var rows: seq[seq[string]] = @[]
  for line in volumes:
    rows.add line.split("|")

  if ctx.output == omTable:
    outp.writeLine("")
  let renderCode = render(@["Driver", "Volume Name"], rows, ctx, runner, outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return renderCode

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
