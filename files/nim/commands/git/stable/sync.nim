import std/os
import "../../../lib/git"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["git", "stable", "sync"],
  kind: ckVerb,
  summary: "fast-forward stable from origin/stable",
  usage: "ax git stable sync",
  deps: @["git"],
  dryRun: false
)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax git stable sync

Switch to stable and fast-forward it from origin/stable.

Requirements:
  - Inside a Git repository
  - Clean Git worktree
  - Local stable branch exists
  - origin remote exists"""
    return 0

  var code = requireGitRepo(runner, errp)
  if code != 0: return code
  code = requireCleanGitWorktree(runner, errp)
  if code != 0: return code
  code = requireBranchExists("stable", runner, errp)
  if code != 0: return code

  if runner.runQuiet("git", @["remote", "get-url", "origin"]) != 0:
    error("Remote not found: origin", errp)
    return 1

  if runner.runQuiet("git", @["checkout", "stable"]) != 0:
    error("Could not switch to stable.", errp)
    return 1

  if runner.runInherited("git", @["pull", "--ff-only", "origin", "stable"]) != 0:
    error("Could not fast-forward stable from origin/stable.", errp)
    return 1

  success("Updated stable.", errp)
  0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
