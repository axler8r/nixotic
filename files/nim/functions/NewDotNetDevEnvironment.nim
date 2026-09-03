import std/os
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

proc isValidDotNetTarget*(target: string): bool =
  target in ["8", "9", "10"]

const dotnetEnvAttrs =
  "\n          DOTNET_CLI_TELEMETRY_OPTOUT = \"1\";" &
  "\n          DOTNET_NOLOGO = \"1\";"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: New-DotNetDevEnvironment [opts] [packages...]

Description:
    Create a new direnv + Nix Flakes .NET development environment using flake-parts.
    Use dotnet CLI to manage project dependencies.

Options:
    -h, --help              Show this help message
    --name NAME             Project name (default: current directory name)
    --target VERSION        .NET SDK version: 8, 9, 10 (default: all three)

Arguments:
    packages                Additional Nix packages (bare names, e.g. jq ripgrep)

Examples:
    New-DotNetDevEnvironment                             # .NET 8, 9 and 10
    New-DotNetDevEnvironment --target 9                  # .NET 9 only
    New-DotNetDevEnvironment --target 9 jq ripgrep       # .NET 9 + extra tools"""
    return 0

  let parsed = parseArgs(args)
  if parsed.missingFlagValue.len > 0:
    error("Missing value for " & parsed.missingFlagValue, errp)
    return 1
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 1
  if not checkDeps(["direnv", "nix"], errp): return 2

  if parsed.target.len > 0 and not isValidDotNetTarget(parsed.target):
    error("Unknown target: " & parsed.target & " (supported: 8, 9, 10)", errp)
    return 1

  let sdkNames =
    if parsed.target.len > 0: @["dotnet-sdk_" & parsed.target]
    else: @["dotnet-sdk_8", "dotnet-sdk_9", "dotnet-sdk_10"]
  let packageLines = formatPackageLines("pkgs.", sdkNames & parsed.packages)
  let content = flakeNixContent(parsed.name, packageLines, dotnetEnvAttrs)
  scaffoldDevEnvironment(content, outp, errp, runner)

when isMainModule:
  cliMain(run(commandLineParams()))
