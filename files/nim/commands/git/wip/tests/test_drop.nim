import std/[unittest, os, osproc, strutils]
import "../drop"

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
    check content.contains("Missing required argument: wip branch name")

  test "more than one argument is an error":
    let tmp = getTempDir() / "test_remove_git_wip_branch_extra.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["wip/x", "extra"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Too many arguments")

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
