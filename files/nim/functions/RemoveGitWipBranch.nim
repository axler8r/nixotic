import std/os
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"
import "../lib/git"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Remove-GitWIPBranch <wip-branch>

Delete a merged local wip/* branch.

Requirements:
  - Inside a Git repository
  - Branch name must be explicit
  - Branch must exist locally
  - Branch must already be merged into stable
  - Branch cannot be the current branch"""
    return 0

  let branch = if args.len > 0: args[0] else: ""
  if not requireArg(branch, "wip branch name", errp): return 1
  if args.len > 1:
    error("Too many arguments", errp)
    return 1

  var code = requireGitRepo(runner, errp)
  if code != 0: return code
  code = requireBranchExists("stable", runner, errp)
  if code != 0: return code
  code = requireBranchExists(branch, runner, errp)
  if code != 0: return code
  code = requireWipBranch(branch, runner, errp)
  if code != 0: return code
  code = requireNotBranch(branch, runner, errp)
  if code != 0: return code

  if runner.runQuiet("git", @["merge-base", "--is-ancestor", branch, "stable"]) != 0:
    error("Branch is not fully merged into stable: " & branch, errp)
    return 1

  if runner.runQuiet("git", @["branch", "-d", branch]) != 0:
    error("Could not delete branch: " & branch, errp)
    return 1

  success("Deleted " & branch & ".", errp)
  0

when isMainModule:
  cliMain(run(commandLineParams()))
