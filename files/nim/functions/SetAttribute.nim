import std/[os, osproc]
import "../lib/output"
import "../lib/validation"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Set-Attribute [opts] <attribute> <value> <path>

Set an attribute on a file or directory.

Options:
    -h, --help    Show this help message

Arguments:
    <attribute>  The attribute to set.
    <value>      The value to set the attribute to.
    <path>       The path to the file or directory.

Examples:
    Set-Attribute comment "This is a test" /path/to/file
    Set-Attribute app.name "MyApp" /path/to/directory"""
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
      return 1
    elif attribute.len == 0:
      attribute = arg
    elif value.len == 0:
      value = arg
    elif path.len == 0:
      path = arg
    else:
      error("Too many arguments", errp)
      return 1
    inc i

  if not requireArg(attribute, "attribute", errp): return 1
  if not requireArg(value, "value", errp): return 1
  if not requireArg(path, "path", errp): return 1
  if not checkDeps(["setfattr"], errp): return 2
  if not requireWritablePathTarget(path, errp): return 1
  if not requireXattrName(attribute, errp): return 1

  let process = startProcess(findExe("setfattr"),
                              args = @["--name", "user." & attribute,
                                       "--value", value, path],
                              options = {poParentStreams})
  result = process.waitForExit()
  process.close()

when isMainModule:
  quit(run(commandLineParams()))
