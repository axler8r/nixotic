import std/os
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["attr", "set"],
  kind: ckVerb,
  summary: "set one extended attribute",
  usage: "ax attr set <attribute> <value> <path>",
  args: @[
    ArgSpec(name: "attribute", required: true,
            description: "the attribute to set"),
    ArgSpec(name: "value", required: true,
            description: "the value to store"),
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
    outp.writeLine """Usage: ax attr set [opts] <attribute> <value> <path>

Set an attribute on a file or directory.

Options:
    -h, --help    Show this help message

Arguments:
    <attribute>  The attribute to set.
    <value>      The value to set the attribute to.
    <path>       The path to the file or directory.

Examples:
    ax attr set comment "This is a test" /path/to/file
    ax attr set app.name "MyApp" /path/to/directory"""
    return 0

  var attribute = ""
  var value = ""
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
    elif value.len == 0:
      value = arg
    elif path.len == 0:
      path = arg
    else:
      error("Too many arguments", errp)
      return 64
    inc i

  if not requireArg(attribute, "attribute", errp): return 64
  if not requireArg(value, "value", errp): return 64
  if not requireArg(path, "path", errp): return 64
  if not checkDeps(["setfattr"], errp): return 2
  if not requireWritablePathTarget(path, errp): return 1
  if not requireXattrName(attribute, errp): return 64

  result = runner.runInherited(
    "setfattr", @["--name", "user." & attribute, "--value", value, path])

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
