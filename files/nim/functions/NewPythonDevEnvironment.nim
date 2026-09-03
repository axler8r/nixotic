import std/[os, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"
import "../lib/devenv"

type ParsedArgs* = object
  name*: string
  target*: string
  packages*: seq[string]
  missingFlagValue*: string
  unknownOption*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  result.name = lastPathPart(getCurrentDir())
  var i = 0
  while i < args.len:
    case args[i]
    of "--name":
      if i + 1 >= args.len:
        result.missingFlagValue = "--name"
        return result
      result.name = args[i + 1]
      i += 2
    of "--target":
      if i + 1 >= args.len:
        result.missingFlagValue = "--target"
        return result
      result.target = args[i + 1]
      i += 2
    else:
      if args[i].len > 0 and args[i][0] == '-':
        result.unknownOption = args[i]
        return result
      result.packages.add(args[i])
      inc i

proc isValidPythonTarget*(target: string): bool =
  let parts = target.split(".")
  parts.len == 2 and parts[0] == "3" and parts[1].len > 0 and
    parts[1].allCharsInSet({'0'..'9'})

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: New-PythonDevEnvironment [opts] [packages...]

Description:
    Create a new direnv + Nix Flakes Python development environment using flake-parts.
    Use uv to manage project dependencies.

Options:
    -h, --help              Show this help message
    --name NAME             Project name (default: current directory name)
    --target VERSION        Python version, e.g. 3.12 (default: python3)

Arguments:
    packages                Additional Nix packages (bare names, e.g. jq ripgrep)

Examples:
    New-PythonDevEnvironment                             # Latest Python + uv
    New-PythonDevEnvironment --target 3.12               # Python 3.12 + uv
    New-PythonDevEnvironment --target 3.13 jq ripgrep    # Python 3.13 + extra tools"""
    return 0

  let parsed = parseArgs(args)
  if parsed.missingFlagValue.len > 0:
    error("Missing value for " & parsed.missingFlagValue, errp)
    return 1
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 1
  if not checkDeps(["direnv", "nix"], errp): return 2

  if parsed.target.len > 0 and not isValidPythonTarget(parsed.target):
    error("Invalid target: " & parsed.target & " (expected format: 3.12)", errp)
    return 1

  let langNames =
    if parsed.target.len > 0: @["python" & parsed.target.replace(".", ""), "uv"]
    else: @["python3", "uv"]
  let packageLines = formatPackageLines("pkgs.", langNames & parsed.packages)
  let content = flakeNixContent(parsed.name, packageLines)
  scaffoldDevEnvironment(content, outp, errp, runner)

when isMainModule:
  cliMain(run(commandLineParams()))
