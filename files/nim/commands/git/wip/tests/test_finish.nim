import std/[unittest, os, osproc, streams, strutils]
import "../finish"

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

suite "ax git wip finish run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_complete_git_wip_branch_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax git wip finish")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_complete_git_wip_branch_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax git wip finish")

  test "not on a wip/* branch is an error":
    let dir = mkTmpDir("complete_git_wip_not_wip")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "complete_git_wip_not_wip_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Branch must match wip/*: stable")

  test "a wip branch not descended from stable cannot fast-forward":
    let dir = mkTmpDir("complete_git_wip_diverged")
    initRepoOnStable(dir)
    # An orphan branch shares no history with stable, so stable can never
    # be fast-forwarded to it.
    runGit(dir, "checkout", "-q", "--orphan", "wip/diverged")
    runGit(dir, "commit", "-q", "--allow-empty", "-m", "feat: diverged")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "complete_git_wip_diverged_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("stable cannot be fast-forwarded to wip/diverged. Rebase onto stable first.")

  test "contract: full success fast-forwards stable and switches to it":
    let dir = mkTmpDir("complete_git_wip_success")
    initRepoOnStable(dir)
    runGit(dir, "checkout", "-q", "-b", "wip/feature")
    writeFile(dir / "new.txt", "x")
    runGit(dir, "add", "new.txt")
    runGit(dir, "commit", "-q", "-m", "feat: add new.txt")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "complete_git_wip_success_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[], f, f)
    f.close()
    var branchOut: string
    block:
      let p = startProcess(findExe("git"), workingDir = dir,
                            args = @["symbolic-ref", "--short", "HEAD"],
                            options = {poUsePath})
      branchOut = p.outputStream.readAll().strip()
      discard p.waitForExit()
      p.close()
    let newFileOnStable = fileExists(dir / "new.txt")
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check branchOut == "stable"
    check newFileOnStable
    check content.contains("Merged wip/feature into stable.")
