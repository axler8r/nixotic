import std/os
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Get-Attributes <path>

List all attributes on a file or directory.

Options:
    -h, --help    Show this help message

Arguments:
    <path>       The path to the file or directory.

Examples:
    Get-Attributes /path/to/file
    Get-Attributes /path/to/directory"""
    return 0

  var path = ""
  var i = 0
  while i < args.len:
    let arg = args[i]
    if arg == "-h" or arg == "--help":
      return 0
    elif arg == "--":
      break
    elif arg.len > 0 and arg[0] == '-':
      error("Unknown option: " & arg, errp)
      return 1
    elif path.len == 0:
      path = arg
    else:
      error("Too many arguments", errp)
      return 1
    inc i

  if not requireArg(path, "path", errp): return 1
  if not checkDeps(["getfattr"], errp): return 2
  if not requirePathTarget(path, errp): return 1

  result = runner.runInherited(
    "getfattr", @["--dump", path])

when isMainModule:
  cliMain(run(commandLineParams()))
