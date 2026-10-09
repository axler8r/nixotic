import std/[os, strutils]
import "../../lib/context"
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["sys", "browser"],
  kind: ckReport,
  summary: "default browser handlers for HTTP and HTTPS",
  usage: "ax sys browser",
  deps: @["xdg-mime"],
  dryRun: false
)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax sys browser

Display default browser handlers for HTTP and HTTPS.

Options:
    -h, --help    Show this help message
    --raw         Print handler values only, one per line (no labels);
                  deprecated alias for -o plain

Examples:
    ax sys browser
    ax sys browser -o plain | head -1"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  var ctx = ctxFromEnv()
  for arg in args:
    if arg == "--raw":
      ctx.output = omPlain

  if not checkDeps(["xdg-mime"], errp):
    return 2

  let httpHandler = runner.capture(
    "xdg-mime",
    @["query", "default", "x-scheme-handler/http"]
  )
  if httpHandler.exitCode != 0:
    error("Cannot query HTTP handler: " & httpHandler.error.strip(), errp)
    return 1
  let httpsHandler = runner.capture(
    "xdg-mime",
    @["query", "default", "x-scheme-handler/https"]
  )
  if httpsHandler.exitCode != 0:
    error("Cannot query HTTPS handler: " & httpsHandler.error.strip(), errp)
    return 1

  if ctx.output == omPlain:
    outp.writeLine httpHandler.output.strip()
    outp.writeLine httpsHandler.output.strip()
    return 0
  render(@["Scheme", "Handler"],
         @[@["http", httpHandler.output.strip()],
           @["https", httpsHandler.output.strip()]], ctx, runner, outp, errp)

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
