import std/[os, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"

type ParsedArgs* = object
  raw*: bool

proc parseArgs*(args: seq[string]): ParsedArgs =
  ## Mirrors the zsh original's case statement, which has no catch-all: any
  ## argument that isn't --raw is silently ignored, including unrecognized
  ## flags.
  for arg in args:
    if arg == "--raw":
      result.raw = true

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Get-GitHubLicenses [--raw]

List all available GitHub licenses.

Options:
    -h, --help    Show this help message
    --raw         Plain text output

Examples:
    Get-GitHubLicenses
    Get-GitHubLicenses --raw | grep mit"""
    return 0

  let parsed = parseArgs(args)

  if not checkDeps(["curl", "jq"], errp): return 2

  # Neither curl's nor jq's exit code is checked here, matching the zsh
  # original: `_data=$(curl ... | jq ...)` never tested $? either, so a
  # failed fetch renders an empty/partial table rather than erroring out.
  let curlResult = runner.capture("curl", @["-s", "https://api.github.com/licenses"])
  let jqResult = runner.capture("jq", @["-r", ".[] | \"\\(.key)|\\(.name)\""],
                                curlResult.output)
  outp.writeLine("")
  discard table("Key|Name\n" & jqResult.output.strip(leading = false,
                trailing = true, chars = {'\n'}), parsed.raw, runner, outp, errp)
  outp.writeLine("")
  return 0

when isMainModule:
  cliMain(run(commandLineParams()))
