import std/os
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"
import "../lib/devenv"

type ParsedArgs* = object
  name*: string
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
    else:
      if args[i].len > 0 and args[i][0] == '-':
        result.unknownOption = args[i]
        return result
      result.packages.add(args[i])
      inc i

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: New-ToolDevEnvironment [opts] packages...

Description:
    Create a new direnv + Nix Flakes ad-hoc tool environment using flake-parts.

Options:
    -h, --help              Show this help message
    --name NAME             Project name (default: current directory name)

Arguments:
    packages                Nix packages (bare names, e.g. jq ripgrep)

Examples:
    New-ToolDevEnvironment jq fd ripgrep               # Ad-hoc shell with tools"""
    return 0

  let parsed = parseArgs(args)
  if parsed.missingFlagValue.len > 0:
    error("Missing value for " & parsed.missingFlagValue, errp)
    return 1
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 1
  if not checkDeps(["direnv", "nix"], errp): return 2

  if parsed.packages.len == 0:
    error("Usage: New-ToolDevEnvironment [opts] packages...", errp)
    info("Use --help for more information", errp)
    return 1

  let packageLines = formatPackageLines("pkgs.", parsed.packages)
  let content = flakeNixContent(parsed.name, packageLines)
  scaffoldDevEnvironment(content, outp, errp, runner)

when isMainModule:
  cliMain(run(commandLineParams()))
