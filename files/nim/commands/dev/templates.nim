import std/os
import "../../lib/context"
import "../../lib/devenv"
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["dev", "templates"],
  kind: ckReport,
  summary: "list what ax dev create accepts",
  usage: "ax dev templates [-o table|plain|json]",
  dryRun: false
)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax dev templates [-o table|plain|json]

List the templates ax dev create accepts.

Options:
    -h, --help    Show this help message
    --raw         Deprecated alias for -o plain

Examples:
    ax dev templates
    ax dev templates -o json | jq -r '.[].template'"""
    return 0

  var ctx = ctxFromEnv()
  for arg in args:
    if arg == "--raw":
      ctx.output = omPlain

  var rows: seq[seq[string]] = @[]
  for t in devTemplates:
    rows.add @[t.name, t.description]

  if ctx.output == omTable:
    outp.writeLine("")
  discard render(@["Template", "Description"], rows, ctx, runner, outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return 0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
