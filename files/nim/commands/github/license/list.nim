import std/[os, strutils]
import "../../../lib/context"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["github", "license", "list"],
  kind: ckVerb,
  summary: "list the licenses GitHub offers",
  usage: "ax github license list",
  deps: @["curl", "jq"],
  dryRun: false
)

type ParsedArgs* = object
  raw*: bool

proc parseArgs*(args: seq[string]): ParsedArgs =
  ## Mirrors the zsh original's case statement, which has no catch-all: any
  ## argument that isn't --raw is silently ignored, including unrecognized
  ## flags.
  for arg in args:
    if arg == "--raw":
      result.raw = true

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax github license list

List all available GitHub licenses.

Options:
    -h, --help    Show this help message
    --raw         Deprecated alias for -o plain

Examples:
    ax github license list
    ax github license list -o plain | grep mit"""
    return 0

  let parsed = parseArgs(args)
  var ctx = ctxFromEnv()
  if parsed.raw:
    ctx.output = omPlain

  if not checkDeps(["curl", "jq"], errp): return 2

  # Neither curl's nor jq's exit code is checked here, matching the zsh
  # original: `_data=$(curl ... | jq ...)` never tested $? either, so a
  # failed fetch renders an empty/partial table rather than erroring out.
  let curlResult = runner.capture("curl", @["-s", "https://api.github.com/licenses"])
  let jqResult = runner.capture("jq", @["-r", ".[] | \"\\(.key)|\\(.name)\""],
                                curlResult.output)
  var rows: seq[seq[string]] = @[]
  for line in jqResult.output.splitLines():
    if line.len == 0: continue
    rows.add line.split("|", maxsplit = 1)

  if ctx.output == omTable:
    outp.writeLine("")
  discard render(@["Key", "Name"], rows, ctx, runner, outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return 0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
