import std/[os, terminal]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Get-Help [--raw] <command>

Display a command's --help output with bat syntax highlighting.

Options:
    -h, --help    Show this help message
    --raw         Plain output, no syntax highlighting

Arguments:
    <command>     Command to query

Examples:
    Get-Help git
    Get-Help --raw fd | grep pattern"""
    return 0

  var rawFlag = false
  var idx = 0
  while idx < args.len:
    let a = args[idx]
    if a == "--raw":
      rawFlag = true
      idx.inc
    elif a.len > 0 and a[0] == '-':
      error("Unknown option: " & a, errp)
      return 1
    else:
      break

  let rest = if idx < args.len: args[idx .. ^1] else: newSeq[string]()
  let cmdName = if rest.len > 0: rest[0] else: ""

  if not requireArg(cmdName, "command", errp): return 1
  if findExe(cmdName).len == 0:
    error("Command not found: " & cmdName, errp)
    return 1

  let cmdArgs = (if rest.len > 1: rest[1 .. ^1] else: newSeq[string]()) & @["--help"]

  if rawFlag or not isatty(outp):
    # Connects the queried command's own stdout/stderr directly to the real
    # terminal rather than to outp/errp, so this branch can't be redirected
    # through the test hook — this matches the zsh original, which also
    # doesn't respect any captured stream here.
    return defaultRunner.runInherited(cmdName, cmdArgs)

  if not checkDeps(["bat"], errp): return 2

  let queried = defaultRunner.capture(cmdName, cmdArgs)

  # The zsh pipeline only pipes the queried command's stdout into bat; its
  # stderr flows straight to the terminal. We capture stderr too and relay it
  # through errp (real stderr by default) to reproduce that behaviour.
  if queried.error.len > 0:
    errp.write(queried.error)

  # bat auto-detects colour from its OWN stdout being a tty; since we pipe
  # bat's stdout back through us (to relay it via outp) rather than handing
  # bat the real terminal fd, that auto-detection would see a pipe and
  # disable colour regardless of NO_COLOR. We already know the true
  # destination (outp) is a tty at this point (checked above), so defer to
  # output.colorEnabled for the NO_COLOR-aware decision instead of forcing
  # colour unconditionally — this keeps NO_COLOR honoured per the project's
  # output contract (docs/nim-functions-conventions.md).
  let colorArg = if colorEnabled(outp): "--color=always" else: "--color=never"
  let highlighted = defaultRunner.capture(
    "bat", @[colorArg, "--plain", "--language=help"], queried.output)
  outp.write(highlighted.output)
  errp.write(highlighted.error)
  result = highlighted.exitCode

when isMainModule:
  cliMain(run(commandLineParams()))
