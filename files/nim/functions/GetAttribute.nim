import std/[os, osproc]
import "../lib/cli"
import "../lib/output"
import "../lib/validation"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Get-Attribute [opts] <attribute> <path>

Get an attribute on a file or directory.

Options:
    -h, --help    Show this help message

Arguments:
    <attribute>  The attribute to get.
    <path>       The path to the file or directory.

Examples:
    Get-Attribute comment /path/to/file
    Get-Attribute app.name /path/to/directory"""
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
      return 1
    elif attribute.len == 0:
      attribute = arg
    elif path.len == 0:
      path = arg
    else:
      error("Too many arguments", errp)
      return 1
    inc i

  if not requireArg(attribute, "attribute", errp): return 1
  if not requireArg(path, "path", errp): return 1
  if not checkDeps(["getfattr"], errp): return 2
  if not requirePathTarget(path, errp): return 1
  if not requireXattrName(attribute, errp): return 1

  let process = startProcess(findExe("getfattr"),
                              args = @["--name", "user." & attribute, path],
                              options = {poParentStreams})
  result = process.waitForExit()
  process.close()

when isMainModule:
  cliMain(run(commandLineParams()))
