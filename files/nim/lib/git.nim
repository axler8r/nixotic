## Port of files/zsh/lib/git.zsh. Unlike lib/vault.nim and lib/devenv.nim,
## the zsh source stays in the repo: Update-GitWIPBranchHistory (excluded
## from migration -- its body is `git rebase --interactive`) keeps
## sourcing it indefinitely, the same way lib/output.zsh/validation.zsh
## persist for the zsh functions that haven't migrated yet.
import std/strutils
import output
import validation
import process

proc requireGitRepo*(runner: Runner = defaultRunner, errp: File = stderr): int =
  ## 0 inside a git repo; 2 if `git` itself is missing (matching
  ## validation.checkDeps's convention); 1 otherwise. Callers propagate
  ## this code verbatim, mirroring the zsh original's `|| return $?`.
  if not checkDeps(["git"], errp): return 2
  if runner.runQuiet("git", @["rev-parse", "--is-inside-work-tree"]) != 0:
    error("Not inside a Git repository.", errp)
    return 1
  0

proc gitCurrentBranch*(runner: Runner = defaultRunner, errp: File = stderr): string =
  ## The current branch name, or "" (with an error already printed) on a
  ## detached HEAD. Callers must check for an empty result themselves,
  ## same as the zsh original's `|| return 1` after each call site.
  let res = runner.capture("git", @["symbolic-ref", "--quiet", "--short", "HEAD"])
  if res.exitCode != 0:
    error("Git HEAD is detached. Switch to a branch first.", errp)
    return ""
  res.output.strip()

proc requireCleanGitWorktree*(runner: Runner = defaultRunner, errp: File = stderr): int =
  let repoCode = requireGitRepo(runner, errp)
  if repoCode != 0: return repoCode
  let status = runner.capture("git", @["status", "--porcelain"]).output.strip()
  if status.len > 0:
    error("Git worktree must be clean.", errp)
    errp.writeLine(status)
    return 1
  0

proc requireBranchExists*(branch: string, runner: Runner = defaultRunner, errp: File = stderr): int =
  if not requireArg(branch, "branch name", errp): return 1
  if runner.runQuiet("git", @["show-ref", "--verify", "--quiet", "refs/heads/" & branch]) != 0:
    error("Branch does not exist: " & branch, errp)
    return 1
  0

proc requireNotBranch*(branch: string, runner: Runner = defaultRunner, errp: File = stderr): int =
  if not requireArg(branch, "branch name", errp): return 1
  let current = gitCurrentBranch(runner, errp)
  if current.len == 0: return 1
  if current == branch:
    error("Refusing to operate on the current branch: " & branch, errp)
    return 1
  0

proc requireWipBranch*(branch: string, runner: Runner = defaultRunner, errp: File = stderr): int =
  ## Mirrors __ax_require_wip_branch: an empty branch defaults to the
  ## current branch. The zsh original delegates to a general
  ## __ax_require_branch_pattern helper; that helper has no other caller
  ## anywhere in this codebase, so its "wip/*" prefix check is folded in
  ## directly here instead of being ported as its own proc.
  var b = branch
  if b.len == 0:
    b = gitCurrentBranch(runner, errp)
    if b.len == 0: return 1
  if not b.startsWith("wip/"):
    error("Branch must match wip/*: " & b, errp)
    return 1
  0
