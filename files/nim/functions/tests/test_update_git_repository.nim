# Every test below that reaches checkDeps stubs `git` and `parallel` on a
# fixture $PATH via testing.writeFakeExe/withPath, so this file is
# environment-independent and cannot silently skip regardless of whether
# this sandbox has the real binaries — see flake.nix's nimToolchain for
# where they'd come from if a stub were ever missing.
# The `parallel` invocation (pull + submodule update) is characterized below
# against a fake `parallel` that records its argv, and pinned exactly by the
# contract test using a RecordingRunner -- real git network operations are
# never run by either.
import std/[unittest, os, strutils]
import "../UpdateGitRepository"
import "../../lib/testing"

proc mkTmpDir(name: string): string =
  result = getTempDir() / name
  removeDir(result)
  createDir(result)

suite "Update-GitRepository run":
  test "-h/--help prints usage and returns 0, checked before checkDeps":
    for flag in ["-h", "--help"]:
      let tmp = getTempDir() / ("test_ugr_help_" & flag.replace("-", "") & ".txt")
      let f = open(tmp, fmWrite)
      let code = run(@[flag], f, f)
      f.close()
      let content = readFile(tmp)
      removeFile(tmp)
      check code == 0
      check content.contains("Usage: Update-GitRepository")

  test "empty result (no args, no git dirs found) uses info, not warn, and returns 0":
    # git/parallel are stubbed on a fixture $PATH via withPath so checkDeps
    # passes regardless of this sandbox's real binaries; neither stub is
    # ever run, since an empty scan returns before `parallel` is reached.
    let depsDir = getTempDir() / "deps_ugr_no_git_dirs"
    removeDir(depsDir)
    createDir(depsDir)
    writeFakeExe(depsDir, "git", "")
    writeFakeExe(depsDir, "parallel", "")
    let dir = mkTmpDir("ugr_no_git_dirs")
    let oldDir = getCurrentDir()
    setCurrentDir(dir)
    let tmp = getTempDir() / "test_ugr_no_git_dirs_out.txt"
    let f = open(tmp, fmWrite)
    var code: int
    withPath(depsDir):
      code = run(@[], f, f)
    f.close()
    setCurrentDir(oldDir)
    let content = readFile(tmp)
    removeFile(tmp)
    removeDir(dir)
    removeDir(depsDir)
    check code == 0
    check content.contains("Info: No git repositories found.")
    check not content.contains("Warning:")

  test "characterization: parallel receives the pull+submodule-update command per repo":
    let dir = getTempDir() / "char_update_git_repository"
    removeDir(dir)
    createDir(dir)
    createDir(dir / "repoA" / ".git")
    let log = dir / "calls.log"
    writeFakeExe(dir, "git", "")
    writeFakeExe(dir, "parallel", fakeRecorder(log))
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    var code: int
    withPath(dir):
      code = run(@["repoA"], f, f)
    setCurrentDir(savedDir)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check calls == @["echo {} && git -C {} pull && git -C {} submodule update ::: repoA"]

  test "contract: parallel receives the pull+submodule-update command and repo dir":
    # `git`/`parallel` are stubbed on a fixture $PATH via withPath, same as
    # the docker/zfs contract tests, so this test is environment-independent
    # and cannot silently skip: checkDeps only needs the stubs to exist,
    # and rec.runner intercepts the actual invocation so their (empty)
    # bodies are never run.
    let dir = getTempDir() / "contract_update_git_repository"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "git", "")
    writeFakeExe(dir, "parallel", "")
    let repoDir = dir / "repo"
    createDir(repoDir / ".git")
    let rec = newRecordingRunner(exitCode = 0)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[repoDir], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "parallel"
    check rec.calls[0].args == @[
      "echo {} && git -C {} pull && git -C {} submodule update",
      ":::", repoDir
    ]

suite "stripTrailingSlash":
  test "removes a single trailing slash":
    check stripTrailingSlash("foo/") == "foo"

  test "removes at most one trailing slash":
    check stripTrailingSlash("foo//") == "foo/"

  test "leaves a path with no trailing slash unchanged":
    check stripTrailingSlash("foo") == "foo"

  test "handles empty string":
    check stripTrailingSlash("") == ""

suite "resolveGivenDirs":
  test "keeps stripped path when <stripped>/.git is a directory":
    let root = mkTmpDir("ugr_resolve_ok")
    let repo = root / "repo"
    createDir(repo / ".git")
    let tmp = getTempDir() / "test_ugr_resolve_ok_out.txt"
    let f = open(tmp, fmWrite)
    let result = resolveGivenDirs(@[repo & "/"], f)
    f.close()
    removeFile(tmp)
    removeDir(root)
    check result == @[repo]

  test "warns using the ORIGINAL arg (not slash-stripped) when not a git repo":
    let root = mkTmpDir("ugr_resolve_not_git")
    let notRepo = root / "plain"
    createDir(notRepo)
    let tmp = getTempDir() / "test_ugr_resolve_not_git_out.txt"
    let f = open(tmp, fmWrite)
    let result = resolveGivenDirs(@[notRepo & "/"], f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    removeDir(root)
    check result.len == 0
    check content.contains("Not a git repository: " & notRepo & "/")

suite "scanCurrentDirGitRepos":
  test "one-level-only scan finds immediate subdirectories containing .git":
    let root = mkTmpDir("ugr_scan")
    let gitDir = root / "repo"
    let nestedGitDir = root / "plain" / "nested-repo"
    createDir(gitDir / ".git")
    createDir(nestedGitDir / ".git")
    let result = scanCurrentDirGitRepos(root)
    removeDir(root)
    check result == @[gitDir]

  test "returns empty when no subdirectory contains .git":
    let root = mkTmpDir("ugr_scan_empty")
    createDir(root / "plain")
    let result = scanCurrentDirGitRepos(root)
    removeDir(root)
    check result.len == 0
