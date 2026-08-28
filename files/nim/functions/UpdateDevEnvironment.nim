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

  var updateProc = startProcess(
    "nix",
    args = @["flake", "update"],
    options = {poUsePath, poParentStreams}
  )
  let updateCode = updateProc.waitForExit()
  updateProc.close()
  if updateCode != 0:
    return 1

  var reloadProc = startProcess(
    "direnv",
    args = @["reload"],
    options = {poUsePath, poParentStreams}
  )
  let reloadCode = reloadProc.waitForExit()
  reloadProc.close()
  return reloadCode

when isMainModule:
  cliMain(run(commandLineParams()))
