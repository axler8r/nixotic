import std/[os, strutils, terminal]
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

  var raw = ctxFromEnv().output == omPlain
  for arg in args:
    if arg == "--raw":
      raw = true
    elif arg.len > 0 and arg[0] == '-':
      error("Unknown option: " & arg, errp)
      return 64
    # else: a non-flag positional arg is silently ignored, matching the
    # zsh original's while/case loop, which never `break`s on the first
    # unmatched arg -- it keeps consuming every remaining arg via `shift`.

  if not checkDeps(["xdg-mime"], errp):
    return 2

  let httpHandler = runner.capture(
    "xdg-mime",
    @["query", "default", "x-scheme-handler/http"]
  ).output.strip()
  let httpsHandler = runner.capture(
    "xdg-mime",
    @["query", "default", "x-scheme-handler/https"]
  ).output.strip()

  if raw or not isatty(outp):
    outp.writeLine httpHandler
    outp.writeLine httpsHandler
  else:
    outp.writeLine "HTTP:   " & httpHandler
    outp.writeLine "HTTPS:  " & httpsHandler
  0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
