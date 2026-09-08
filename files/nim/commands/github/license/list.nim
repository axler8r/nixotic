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
  unknownOption*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  for arg in args:
    if arg == "--raw":
      result.raw = true
    elif arg != "--":
      result.unknownOption = arg
      return

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

  if not validateArgs(cmdSpec, args, errp): return 64

  let parsed = parseArgs(args)
  var ctx = ctxFromEnv()
  if parsed.raw:
    ctx.output = omPlain

  if not checkDeps(["curl", "jq"], errp): return 2

  let curlResult = runner.capture("curl", @["-fsS", "https://api.github.com/licenses"])
  if curlResult.exitCode != 0:
    error("Cannot fetch GitHub licenses: " & curlResult.error.strip(), errp)
    return 1
  let jqResult = runner.capture("jq", @["-r", ".[] | \"\\(.key)|\\(.name)\""],
                                curlResult.output)
  if jqResult.exitCode != 0:
    error("Cannot parse GitHub licenses: " & jqResult.error.strip(), errp)
    return 1
  var rows: seq[seq[string]] = @[]
  for line in jqResult.output.splitLines():
    if line.len == 0: continue
    rows.add line.split("|", maxsplit = 1)

  if ctx.output == omTable:
    outp.writeLine("")
  let renderCode = render(@["Key", "Name"], rows, ctx, runner, outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return renderCode

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
