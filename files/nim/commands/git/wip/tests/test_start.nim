# See test_git.nim's header note: these tests need `git` on $PATH (already
# in flake.nix's nimToolchain).
import std/[unittest, os, osproc, streams, strutils]
import "../start"

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

suite "ax git wip start randomAlnum":
  test "produces a string of the requested length from A-Za-z0-9":
    let s = randomAlnum(7)
    check s.len == 7
    for c in s:
      check c in {'A'..'Z', 'a'..'z', '0'..'9'}

suite "ax git wip start generateWipBranchName":
  test "accepts the first candidate when nothing collides":
    let name = generateWipBranchName(proc(n: string): bool = false)
    check name.startsWith("wip/")
    check name.len == "wip/".len + 8 + 1 + 7 # wip/ + YYYYMMDD + - + 7 chars

  test "retries past a collision":
    var calls = 0
    let name = generateWipBranchName(proc(n: string): bool =
      inc calls
      calls < 3
    )
    check calls == 3
    check name.startsWith("wip/")

  test "gives up after 10 collisions, returning empty":
    var calls = 0
    let name = generateWipBranchName(proc(n: string): bool =
      inc calls
      true
    )
    check calls == 10
    check name == ""

suite "ax git wip start run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_new_git_wip_branch_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax git wip start")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_new_git_wip_branch_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax git wip start")

  test "outside a git repository is an error":
    let dir = mkTmpDir("new_git_wip_branch_not_repo")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let code = run(@[])
    setCurrentDir(saved)
    removeDir(dir)
    check code == 1

  test "a dirty worktree is an error":
    let dir = mkTmpDir("new_git_wip_branch_dirty")
    initRepoOnStable(dir)
    writeFile(dir / "untracked.txt", "x")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let code = run(@[])
    setCurrentDir(saved)
    removeDir(dir)
    check code == 1

  test "not currently on stable is an error":
    let dir = mkTmpDir("new_git_wip_branch_not_stable")
    initRepoOnStable(dir)
    runGit(dir, "checkout", "-q", "-b", "other")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "new_git_wip_branch_not_stable_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Current branch must be stable: other")

  test "contract: full success creates and checks out a wip/YYYYMMDD-<7 chars> branch":
    let dir = mkTmpDir("new_git_wip_branch_success")
    initRepoOnStable(dir)
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "new_git_wip_branch_success_out.txt"
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
    check code == 0
    check branchOut.startsWith("wip/")
    check content.contains("Created " & branchOut & ".")
