import std/[unittest, os, osproc, strutils]
import "../drop"
import "../../../../lib/process"
import "../../../../lib/testing"

proc mkTmpDir(name: string): string =
  result = getTempDir() / name
  removeDir(result)
  createDir(result)

proc runGit(dir: string, args: varargs[string]) =
  let p = startProcess(findExe("git"), workingDir = dir, args = @args,
                        options = {poUsePath})
  discard p.waitForExit()
  p.close()

proc initRepoOnStable(dir: string) =
  runGit(dir, "init", "-q")
  runGit(dir, "config", "user.email", "test@example.invalid")
  runGit(dir, "config", "user.name", "Test")
  writeFile(dir / "README.md", "x")
  runGit(dir, "add", "README.md")
  runGit(dir, "commit", "-q", "-m", "feat: initial commit")
  runGit(dir, "branch", "-m", "stable")

suite "ax git wip drop run":
  test "leading and trailing terminators preserve the branch being deleted":
    let dir = mkTmpDir("ax_wip_drop_terminator")
    defer: removeDir(dir)
    writeFakeExe(dir, "git", "")
    let f = open("/dev/null", fmWrite)
    defer: f.close()
    for args in @[@["--", "wip/test"], @["wip/test", "--"]]:
      let rec = newRecordingRunner(replies = @[
        CommandResult(exitCode: 0),
        CommandResult(exitCode: 0),
        CommandResult(exitCode: 0),
        CommandResult(exitCode: 0, output: "stable\n"),
        CommandResult(exitCode: 0),
        CommandResult(exitCode: 0)
      ])
      withPath(dir):
        check run(args, f, f, rec.runner) == 0
      require rec.calls.len == 6
      check rec.calls[^1].args == @["branch", "-d", "wip/test"]

  test "invalid arguments cannot inspect or delete branches":
    let f = open("/dev/null", fmWrite)
    defer: f.close()
    for args in @[@["wip/test", "extra"], @["--force", "wip/test"],
                  @["--dry-run", "wip/test"], @["-n", "wip/test"]]:
      let rec = newRecordingRunner()
      check run(args, f, f, rec.runner) == 64
      check rec.calls.len == 0

  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_remove_git_wip_branch_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax git wip drop")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_remove_git_wip_branch_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax git wip drop")

  test "missing the branch name argument is a requireArg error":
    let tmp = getTempDir() / "test_remove_git_wip_branch_no_arg.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("branch")

  test "more than one argument is an error":
    let tmp = getTempDir() / "test_remove_git_wip_branch_extra.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["wip/x", "extra"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Unexpected argument: extra")

  test "a non-wip branch name is rejected":
    let dir = mkTmpDir("remove_git_wip_not_wip")
    initRepoOnStable(dir)
    runGit(dir, "branch", "feature/x")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "remove_git_wip_not_wip_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["feature/x"], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Branch must match wip/*: feature/x")

  test "the current branch cannot remove itself":
    let dir = mkTmpDir("remove_git_wip_current")
    initRepoOnStable(dir)
    runGit(dir, "checkout", "-q", "-b", "wip/self")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "remove_git_wip_current_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["wip/self"], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Refusing to operate on the current branch: wip/self")

  test "an unmerged wip branch is rejected":
    let dir = mkTmpDir("remove_git_wip_unmerged")
    initRepoOnStable(dir)
    runGit(dir, "checkout", "-q", "-b", "wip/unmerged")
    writeFile(dir / "new.txt", "x")
    runGit(dir, "add", "new.txt")
    runGit(dir, "commit", "-q", "-m", "feat: add new.txt")
    runGit(dir, "checkout", "-q", "stable")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "remove_git_wip_unmerged_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["wip/unmerged"], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Branch is not fully merged into stable: wip/unmerged")

  test "contract: a fully-merged wip branch is deleted":
    let dir = mkTmpDir("remove_git_wip_success")
    initRepoOnStable(dir)
    runGit(dir, "checkout", "-q", "-b", "wip/merged")
    runGit(dir, "checkout", "-q", "stable")
    runGit(dir, "merge", "-q", "--ff-only", "wip/merged")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "remove_git_wip_success_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["wip/merged"], f, f)
    f.close()
    var branchExists = true
    block:
      let p = startProcess(findExe("git"), workingDir = dir,
                            args = @["show-ref", "--verify", "--quiet",
                                     "refs/heads/wip/merged"],
                            options = {poUsePath})
      branchExists = p.waitForExit() == 0
      p.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check not branchExists
    check content.contains("Deleted wip/merged.")
