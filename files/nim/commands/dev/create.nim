import std/[os, strutils]
import "../../lib/devenv"
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["dev", "create"],
  kind: ckVerb,
  summary: "scaffold a direnv + Nix Flakes development environment",
  usage: "ax dev create <template> [--name NAME] [--target VERSION] [packages...]",
  args: @[
    ArgSpec(name: "template", required: true,
            description: "tool, python, dotnet, or elixir (see ax dev templates)"),
    ArgSpec(name: "packages", required: false, variadic: true,
            description: "additional Nix packages (bare names, e.g. jq ripgrep)")
  ],
  flags: @[
    FlagSpec(long: "name", takesValue: true,
             description: "project name (default: current directory name)"),
    FlagSpec(long: "target", takesValue: true,
             description: "language/SDK version; meaning depends on the template")
  ],
  deps: @["direnv", "nix"],
  dryRun: false
)

type ParsedArgs* = object
  templateName*: string
  name*: string
  target*: string
  packages*: seq[string]
  missingFlagValue*: string
  unknownOption*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  ## The first bare positional is the template; every later one is a
  ## package. --name and --target consume the following token, setting
  ## missingFlagValue and stopping if none follows, exactly like the
  ## retired per-language scaffolders.
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
      if result.templateName.len == 0:
        result.templateName = args[i]
      else:
        result.packages.add(args[i])
      inc i

proc isValidPythonTarget*(target: string): bool =
  let parts = target.split(".")
  parts.len == 2 and parts[0] == "3" and parts[1].len > 0 and
    parts[1].allCharsInSet({'0'..'9'})

proc isValidDotNetTarget*(target: string): bool =
  target in ["8", "9", "10"]

proc isValidElixirTarget*(target: string): bool =
  let parts = target.split(".")
  parts.len == 2 and parts[0].len > 0 and parts[0].allCharsInSet({'0'..'9'}) and
    parts[1].len > 0 and parts[1].allCharsInSet({'0'..'9'})

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
    outp.writeLine """Usage: ax dev create <template> [opts] [packages...]

Description:
    Create a new direnv + Nix Flakes development environment using
    flake-parts. The template picks the toolchain; `ax dev templates`
    lists what is available.

Templates:
    tool        Ad-hoc tool shell (packages required)
    python      Python + uv (--target 3.12)
    dotnet      .NET SDK (--target 8, 9 or 10; default all three)
    elixir      Elixir (--target 1.17)

Options:
    -h, --help              Show this help message
    --name NAME             Project name (default: current directory name)
    --target VERSION        Toolchain version; meaning depends on the template

Arguments:
    packages                Additional Nix packages (bare names, e.g. jq ripgrep)

Examples:
    ax dev create tool jq fd ripgrep
    ax dev create python --target 3.12
    ax dev create dotnet --target 9 jq
    ax dev create elixir --target 1.17"""
    return 0

  let parsed = parseArgs(args)
  if parsed.missingFlagValue.len > 0:
    error("Missing value for " & parsed.missingFlagValue, errp)
    return 64
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 64
  if parsed.templateName.len == 0:
    error("Missing template (tool, python, dotnet, elixir)", errp)
    return 64
  if not isDevTemplate(parsed.templateName):
    error("Unknown template: " & parsed.templateName &
          " (supported: tool, python, dotnet, elixir)", errp)
    return 64
  if not checkDeps(["direnv", "nix"], errp): return 2

  var packageLines: seq[string]
  var envAttrs = ""
  case parsed.templateName
  of "tool":
    if parsed.target.len > 0:
      error("--target is not supported for the tool template", errp)
      return 64
    if parsed.packages.len == 0:
      error("Usage: ax dev create tool [opts] packages...", errp)
      info("Use --help for more information", errp)
      return 64
    packageLines = formatPackageLines("pkgs.", parsed.packages)
  of "python":
    if parsed.target.len > 0 and not isValidPythonTarget(parsed.target):
      error("Invalid target: " & parsed.target & " (expected format: 3.12)", errp)
      return 64
    let langNames =
      if parsed.target.len > 0: @["python" & parsed.target.replace(".", ""), "uv"]
      else: @["python3", "uv"]
    packageLines = formatPackageLines("pkgs.", langNames & parsed.packages)
  of "dotnet":
    if parsed.target.len > 0 and not isValidDotNetTarget(parsed.target):
      error("Unknown target: " & parsed.target & " (supported: 8, 9, 10)", errp)
      return 64
    let sdkNames =
      if parsed.target.len > 0: @["dotnet-sdk_" & parsed.target]
      else: @["dotnet-sdk_8", "dotnet-sdk_9", "dotnet-sdk_10"]
    packageLines = formatPackageLines("pkgs.", sdkNames & parsed.packages)
    envAttrs = dotnetEnvAttrs
  of "elixir":
    if parsed.target.len > 0 and not isValidElixirTarget(parsed.target):
      error("Invalid target: " & parsed.target & " (expected format: 1.17)", errp)
      return 64
    let langNames =
      if parsed.target.len > 0: @["elixir_" & parsed.target.replace(".", "_")]
      else: @["elixir"]
    packageLines = formatPackageLines("pkgs.beamPackages.", langNames) &
                    formatPackageLines("pkgs.", parsed.packages)
  else:
    discard # unreachable: isDevTemplate already vetted the name

  let content = flakeNixContent(parsed.name, packageLines, envAttrs)
  scaffoldDevEnvironment(content, outp, errp, runner)

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
