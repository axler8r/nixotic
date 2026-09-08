import std/os
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["attr", "remove"],
  kind: ckVerb,
  summary: "remove one extended attribute",
  usage: "ax attr remove <attribute> <path>",
  args: @[
    ArgSpec(name: "attribute", required: true,
            description: "the attribute to remove"),
    ArgSpec(name: "path", required: true,
            description: "the file or directory to write")
  ],
  deps: @["setfattr"],
  dryRun: false
)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax attr remove [opts] <attribute> <path>

Remove an attribute on a file or directory.

Options:
    -h, --help    Show this help message

Arguments:
    <attribute>  The attribute to remove.
    <path>       The path to the file or directory.

Examples:
    ax attr remove comment /path/to/file
    ax attr remove app.name /path/to/directory"""
    return 0

  var attribute = ""
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
      return 64
    elif attribute.len == 0:
      attribute = arg
    elif path.len == 0:
      path = arg
    else:
      error("Too many arguments", errp)
      return 64
    inc i

  if not requireArg(attribute, "attribute", errp): return 64
  if not requireArg(path, "path", errp): return 64
  if not checkDeps(["setfattr"], errp): return 2
  if not requireWritablePathTarget(path, errp): return 1
  if not requireXattrName(attribute, errp): return 64

  result = runner.runInherited(
    "setfattr", @["--remove", "user." & attribute, path])

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
