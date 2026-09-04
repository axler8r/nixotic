import std/os
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/git"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Complete-GitWIPBranch

Fast-forward stable to the current wip/* branch.

Requirements:
  - Inside a Git repository
  - Clean Git worktree
  - Currently on a wip/* branch
  - Local stable branch exists

Notes:
  - This does not rewrite WIP history first.
  - This does not delete the merged branch."""
    return 0

  var code = requireGitRepo(runner, errp)
  if code != 0: return code
  code = requireCleanGitWorktree(runner, errp)
  if code != 0: return code
  code = requireBranchExists("stable", runner, errp)
  if code != 0: return code

  let wipBranch = gitCurrentBranch(runner, errp)
  if wipBranch.len == 0: return 1
  code = requireWipBranch(wipBranch, runner, errp)
  if code != 0: return code

  if runner.runQuiet("git", @["merge-base", "--is-ancestor", "stable", wipBranch]) != 0:
    error("stable cannot be fast-forwarded to " & wipBranch & ". Rebase onto stable first.", errp)
    return 1

  if runner.runQuiet("git", @["checkout", "stable"]) != 0:
    error("Could not switch to stable.", errp)
    return 1

  if runner.runQuiet("git", @["merge", "--ff-only", wipBranch]) != 0:
    error("Could not fast-forward stable to " & wipBranch & ".", errp)
    return 1

  success("Merged " & wipBranch & " into stable.", errp)
  0

when isMainModule:
  cliMain(run(commandLineParams()))
