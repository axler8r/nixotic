# These tests need `git` on $PATH at runtime: fixtures shell out to a real
# `git init`/`git commit`/etc. (via runGit below) to build real
# repositories that requireGitRepo/gitCurrentBranch/etc. then inspect --
# see flake.nix's nimToolchain (already present, used today by
# InitializeClaudeProject.nim's tests).
import std/[unittest, os, osproc, streams, strutils]
import "../git"
import "../process"
import "../testing"

proc mkTmpDir(name: string): string =
  result = getTempDir() / name
  removeDir(result)
  createDir(result)

proc runGit(dir: string, args: varargs[string]) =
  let p = startProcess(findExe("git"), workingDir = dir, args = @args,
                        options = {poUsePath})
  let code = p.waitForExit()
  p.close()
  doAssert code == 0, "git fixture failed: " & $(@args)

proc initRepoOnStable(dir: string) =
  ## A one-commit repo whose current branch is explicitly named "stable",
  ## regardless of this git's init.defaultBranch config.
  runGit(dir, "init", "-q")
  runGit(dir, "config", "user.email", "test@example.invalid")
  runGit(dir, "config", "user.name", "Test")
  writeFile(dir / "README.md", "x")
  runGit(dir, "add", "README.md")
  runGit(dir, "commit", "-q", "-m", "feat: initial commit")
  runGit(dir, "branch", "-m", "stable")

suite "git.requireGitRepo":
  test "fails outside a git repository":
    let dir = mkTmpDir("git_requiregitrepo_not_repo")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "git_requiregitrepo_not_repo_out.txt"
    let f = open(outPath, fmWrite)
    let code = requireGitRepo(defaultRunner, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Not inside a Git repository.")

  test "succeeds inside a real git repository":
    let dir = mkTmpDir("git_requiregitrepo_repo")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let code = requireGitRepo()
    setCurrentDir(saved)
    removeDir(dir)
    check code == 0

  test "missing git is exit 2, checked before any repository probe":
    let dir = mkTmpDir("git_requiregitrepo_no_git")
    let outPath = getTempDir() / "git_requiregitrepo_no_git_out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = requireGitRepo(defaultRunner, f)
    f.close()
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands: git")

suite "git.gitCurrentBranch":
  test "returns the current branch name":
    let dir = mkTmpDir("git_currentbranch_named")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let branch = gitCurrentBranch()
    setCurrentDir(saved)
    removeDir(dir)
    check branch == "stable"

  test "returns empty with an error on a detached HEAD":
    let dir = mkTmpDir("git_currentbranch_detached")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    var sha: string
    block:
      let p = startProcess(findExe("git"), workingDir = dir,
                            args = @["rev-parse", "HEAD"],
                            options = {poUsePath, poStdErrToStdOut})
      sha = p.outputStream.readAll().strip()
      discard p.waitForExit()
      p.close()
    runGit(dir, "checkout", "-q", sha)
    let outPath = getTempDir() / "git_currentbranch_detached_out.txt"
    let f = open(outPath, fmWrite)
    let branch = gitCurrentBranch(defaultRunner, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check branch == ""
    check content.contains("Git HEAD is detached. Switch to a branch first.")

suite "git.requireCleanGitWorktree":
  test "failed status with empty stdout is not a clean worktree":
    let rec = newRecordingRunner()
    rec.runner.captureImpl = proc(cmd: string, args: seq[string], input: string): CommandResult =
      rec.calls.add(CallRecord(kind: "capture", cmd: cmd, args: args, input: input))
      if args[0] == "status":
        CommandResult(exitCode: 128, error: "index unreadable")
      else:
        CommandResult(exitCode: 0)
    let f = open("/dev/null", fmWrite)
    defer: f.close()
    check requireCleanGitWorktree(rec.runner, f) == 1
    check rec.calls.len == 2

  test "succeeds on a clean worktree":
    let dir = mkTmpDir("git_clean_ok")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let code = requireCleanGitWorktree()
    setCurrentDir(saved)
    removeDir(dir)
    check code == 0

  test "fails and prints the porcelain status when dirty":
    let dir = mkTmpDir("git_clean_dirty")
    initRepoOnStable(dir)
    writeFile(dir / "untracked.txt", "x")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "git_clean_dirty_out.txt"
    let f = open(outPath, fmWrite)
    let code = requireCleanGitWorktree(defaultRunner, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Git worktree must be clean.")
    check content.contains("untracked.txt")

  test "propagates requireGitRepo's own failure outside a repository":
    let dir = mkTmpDir("git_clean_not_repo")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let code = requireCleanGitWorktree()
    setCurrentDir(saved)
    removeDir(dir)
    check code == 1

suite "git.requireBranchExists":
  test "succeeds for a branch that exists":
    let dir = mkTmpDir("git_branchexists_yes")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let code = requireBranchExists("stable")
    setCurrentDir(saved)
    removeDir(dir)
    check code == 0

  test "fails for a branch that does not exist":
    let dir = mkTmpDir("git_branchexists_no")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "git_branchexists_no_out.txt"
    let f = open(outPath, fmWrite)
    let code = requireBranchExists("nonexistent", defaultRunner, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Branch does not exist: nonexistent")

  test "an empty branch name is a requireArg error":
    let outPath = getTempDir() / "git_branchexists_empty_out.txt"
    let f = open(outPath, fmWrite)
    let code = requireBranchExists("", defaultRunner, f)
    f.close()
    let content = readFile(outPath)
    removeFile(outPath)
    check code == 1
    check content.contains("Missing required argument: branch name")

suite "git.requireNotBranch":
  test "succeeds when the given branch is not the current one":
    let dir = mkTmpDir("git_notbranch_ok")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let code = requireNotBranch("wip/other")
    setCurrentDir(saved)
    removeDir(dir)
    check code == 0

  test "fails when the given branch is the current one":
    let dir = mkTmpDir("git_notbranch_fail")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "git_notbranch_fail_out.txt"
    let f = open(outPath, fmWrite)
    let code = requireNotBranch("stable", defaultRunner, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Refusing to operate on the current branch: stable")

suite "git.requireWipBranch":
  test "succeeds for an explicit wip/* branch name":
    check requireWipBranch("wip/20260101-abcdefg") == 0

  test "fails for a non-wip/ branch name":
    let outPath = getTempDir() / "git_wipbranch_bad_out.txt"
    let f = open(outPath, fmWrite)
    let code = requireWipBranch("feature/x", defaultRunner, f)
    f.close()
    let content = readFile(outPath)
    removeFile(outPath)
    check code == 1
    check content.contains("Branch must match wip/*: feature/x")

  test "an empty branch falls back to the current branch":
    let dir = mkTmpDir("git_wipbranch_fallback")
    initRepoOnStable(dir)
    runGit(dir, "checkout", "-q", "-b", "wip/fallback")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let code = requireWipBranch("")
    setCurrentDir(saved)
    removeDir(dir)
    check code == 0

  test "an empty branch falling back to a non-wip current branch fails":
    let dir = mkTmpDir("git_wipbranch_fallback_fail")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "git_wipbranch_fallback_fail_out.txt"
    let f = open(outPath, fmWrite)
    let code = requireWipBranch("", defaultRunner, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Branch must match wip/*: stable")

suite "git contract: exact argv":
  test "requireBranchExists queries refs/heads/<branch> via show-ref":
    let rec = newRecordingRunner(exitCode = 0)
    discard requireBranchExists("mybranch", rec.runner)
    check rec.calls.len == 1
    check rec.calls[0].cmd == "git"
    check rec.calls[0].args == @["show-ref", "--verify", "--quiet", "refs/heads/mybranch"]
