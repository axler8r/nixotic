import std/[os, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"

type ParsedArgs* = object
  raw*: bool
  server*: string
  unknownOption*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  result.server = "localhost"
  for arg in args:
    if arg == "--raw":
      result.raw = true
    elif arg.len > 0 and arg[0] == '-':
      result.unknownOption = arg
      return result
    else:
      result.server = arg

proc classifyShowmountError*(output, server: string): string =
  ## Mirrors the zsh original's case-statement substring matching, checked
  ## in this exact order.
  if output.contains("Connection refused"):
    "Connection refused. NFS server may not be running on '" & server & "'."
  elif output.contains("No route to host") or output.contains("Host is unreachable"):
    "Cannot reach host '" & server & "'. Check network connectivity."
  elif output.contains("Name or service not known") or output.contains("not known"):
    "Cannot resolve hostname '" & server & "'."
  elif output.contains("Permission denied") or output.contains("access denied"):
    "Permission denied when querying '" & server & "'."
  elif output.contains("timed out") or output.contains("Timed out"):
    "Connection to '" & server & "' timed out."
  else:
    "Failed to query NFS exports: " & output

proc splitFirstWhitespaceRun*(line: string): string =
  ## Mirrors `sed 's/[[:space:]]\+/|/'`: replaces only the FIRST run of
  ## whitespace with "|", leaving any later whitespace in the line as-is.
  var i = 0
  while i < line.len and line[i] notin Whitespace: inc i
  if i >= line.len: return line
  var j = i
  while j < line.len and line[j] in Whitespace: inc j
  line[0 ..< i] & "|" & line[j .. ^1]

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Get-NfsExports [opts] [server]

Check for exported NFS mounts on a server using showmount.
Displays all available NFS exports and their access permissions.

Options:
    -h, --help    Show this help message
    --raw         Display output in raw format

Arguments:
    server        NFS server hostname or IP (default: localhost)

Examples:
    Get-NfsExports
    Get-NfsExports 192.168.1.10
    Get-NfsExports nfs.example.com"""
    return 0

  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 1

  if not checkDeps(["showmount"], errp): return 2

  info("Querying NFS exports on '" & parsed.server & "'...", errp)

  let showmountResult = runner.capture("showmount", @["-e", parsed.server])
  if showmountResult.exitCode != 0:
    let combined = showmountResult.output & showmountResult.error
    error(classifyShowmountError(combined, parsed.server), errp)
    return 1

  let exports = showmountResult.output
  let trimmed = exports.strip()
  if trimmed.len == 0 or trimmed == "Export list for " & parsed.server & ":":
    warn("No NFS exports found on '" & parsed.server & "'.", errp)
    return 0

  var lineList = exports.splitLines()
  if lineList.len > 0: lineList = lineList[1 .. ^1]
  var dataLines: seq[string] = @[]
  for line in lineList:
    if line.len == 0: continue
    dataLines.add(splitFirstWhitespaceRun(line))

  outp.writeLine("")
  discard table("Export|Clients\n" & dataLines.join("\n"), parsed.raw, runner, outp, errp)
  outp.writeLine("")

  if dataLines.len > 0:
    info("\nFound " & $dataLines.len & " export(s) on '" & parsed.server & "'.", errp)

  return 0

when isMainModule:
  cliMain(run(commandLineParams()))
