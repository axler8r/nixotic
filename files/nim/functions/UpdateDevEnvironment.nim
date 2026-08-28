import std/os
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Update-DevEnvironment

Description:
    Update a direnv + Nix Flakes development environment in the current
    directory. Advances flake.lock to the latest revisions of all inputs,
    then reloads the direnv environment.

Options:
    -h, --help    Show this help message

Examples:
    Update-DevEnvironment        # Update flake inputs and reload environment"""
    return 0

  if not checkDeps(["direnv", "nix"], errp): return 2

  if not fileExists("flake.nix"):
    error("No flake.nix found in current directory", errp)
    return 1

  let updateCode = runner.runInherited("nix", @["flake", "update"])
  if updateCode != 0:
    return 1

  return runner.runInherited("direnv", @["reload"])

when isMainModule:
  cliMain(run(commandLineParams()))
