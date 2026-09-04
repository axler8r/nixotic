import std/[unittest, os, osproc, streams, strutils]
import "../UpdateGitStableBranch"

proc mkTmpDir(name: string): string =
  result = getTempDir() / name
  removeDir(result)
  createDir(result)

proc runGit(dir: string, args: varargs[string]) =
  let p = startProcess(findExe("git"), workingDir = dir, args = @args,
                        options = {poUsePath, poStdErrToStdOut})
  let output = p.outputStream.readAll()
  let code = p.waitForExit()
  p.close()
  doAssert code == 0, "git " & $(@args) & " failed in " & dir & ":\n" & output

proc initRepoOnStable(dir: string) =
  runGit(dir, "init", "-q")
  runGit(dir, "config", "user.email", "test@example.invalid")
  runGit(dir, "config", "user.name", "Test")
  writeFile(dir / "README.md", "x")
  runGit(dir, "add", "README.md")
  runGit(dir, "commit", "-q", "-m", "feat: initial commit")
  runGit(dir, "branch", "-m", "stable")

suite "Update-GitStableBranch run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_update_git_stable_branch_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Update-GitStableBranch")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_update_git_stable_branch_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Update-GitStableBranch")

  test "no origin remote is an error, checked before switching branches":
    let dir = mkTmpDir("update_git_stable_no_origin")
    initRepoOnStable(dir)
    runGit(dir, "checkout", "-q", "-b", "other")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "update_git_stable_no_origin_out.txt"
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
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Remote not found: origin")
    check branchOut == "other" # never switched to stable

  test "contract: full success checks out stable and fast-forwards it from a real origin":
    # A second bare repo stands in for "origin": init a clone-like setup
    # by cloning the fixture repo into a bare "origin", then adding a
    # commit to the bare copy's stable branch directly is impractical, so
    # instead this pushes stable to a bare origin, advances origin
    # separately via a second working clone, then verifies the update
    # pulls that advance in.
    let originDir = mkTmpDir("update_git_stable_origin")
    runGit(originDir, "init", "-q", "--bare")

    let seedDir = mkTmpDir("update_git_stable_seed")
    initRepoOnStable(seedDir)
    runGit(seedDir, "remote", "add", "origin", originDir)
    runGit(seedDir, "push", "-q", "origin", "stable")
    # A freshly created bare repo's HEAD does not necessarily follow the
    # first branch pushed to it (depends on git version); point it at
    # stable explicitly so the clone below checks that branch out.
    runGit(originDir, "symbolic-ref", "HEAD", "refs/heads/stable")

    # Advance origin's stable branch via a second clone, independent of
    # the fixture repository under test.
    let advanceDir = mkTmpDir("update_git_stable_advance")
    runGit(advanceDir, "clone", "-q", originDir, ".")
    runGit(advanceDir, "config", "user.email", "test@example.invalid")
    runGit(advanceDir, "config", "user.name", "Test")
    writeFile(advanceDir / "advanced.txt", "x")
    runGit(advanceDir, "add", "advanced.txt")
    runGit(advanceDir, "commit", "-q", "-m", "feat: advance origin")
    runGit(advanceDir, "push", "-q", "origin", "stable")

    let dir = seedDir
    runGit(dir, "checkout", "-q", "-b", "other")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "update_git_stable_success_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let advancedPresent = fileExists(dir / "advanced.txt")
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    removeDir(originDir)
    removeDir(advanceDir)
    check code == 0
    check advancedPresent
    check content.contains("Updated stable.")
