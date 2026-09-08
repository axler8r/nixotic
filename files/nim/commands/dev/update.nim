import std/os
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["dev", "update"],
  kind: ckVerb,
  summary: "advance flake.lock and reload the direnv environment",
  usage: "ax dev update",
  deps: @["direnv", "nix"],
  dryRun: false
)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax dev update

Description:
    Update a direnv + Nix Flakes development environment in the current
    directory. Advances flake.lock to the latest revisions of all inputs,
    then reloads the direnv environment.

Options:
    -h, --help    Show this help message

Examples:
    ax dev update        # Update flake inputs and reload environment"""
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
  axMain(cmdSpec):
    run(commandLineParams())
