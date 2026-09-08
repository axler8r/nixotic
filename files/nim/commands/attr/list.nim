import std/os
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["attr", "list"],
  kind: ckVerb,
  summary: "list every extended attribute",
  usage: "ax attr list <path>",
  args: @[
    ArgSpec(name: "path", required: true,
            description: "the file or directory to read")
  ],
  deps: @["getfattr"],
  dryRun: false
)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax attr list <path>

List all attributes on a file or directory.

Options:
    -h, --help    Show this help message

Arguments:
    <path>       The path to the file or directory.

Examples:
    ax attr list /path/to/file
    ax attr list /path/to/directory"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  var path = ""
  var positionalOnly = false
  var i = 0
  while i < args.len:
    let arg = args[i]
    if not positionalOnly and (arg == "-h" or arg == "--help"):
      return 0
    elif not positionalOnly and arg == "--":
      positionalOnly = true
    elif not positionalOnly and arg.len > 1 and arg[0] == '-':
      error("Unknown option: " & arg, errp)
      return 64
    elif path.len == 0:
      path = arg
    else:
      error("Too many arguments", errp)
      return 64
    inc i

  if not requireArg(path, "path", errp): return 64
  if not checkDeps(["getfattr"], errp): return 2
  if not requirePathTarget(path, errp): return 1

  result = runner.runInherited(
    "getfattr", @["--dump", "--", path])

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
