# These tests need `git` and `parallel` on $PATH at test-compile-time — see
# flake.nix's nim-functions-tests nativeBuildInputs. The `parallel`
# invocation (the gc/fetch/fsck chain) is characterized below against a fake
# `parallel` on a fixture $PATH (see testing.writeFakeExe/withPath) and
# pinned exactly by the contract test using a RecordingRunner -- real git
# maintenance commands are never run by either.
import std/[unittest, os, strutils]
import "../InvokeGitRepositoryOptimization"
import "../../lib/testing"

proc mkTmpDir(name: string): string =
  result = getTempDir() / name
  removeDir(result)
  createDir(result)

let depsPresent = findExe("git").len > 0 and findExe("parallel").len > 0

suite "Invoke-GitRepositoryOptimization run":
  test "--help short-circuits before checkDeps, returns 0":
    let tmp = getTempDir() / "test_igro_help_dashdash.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Invoke-GitRepositoryOptimization")

  test "-h does NOT short-circuit before checkDeps (asymmetry vs --help)":
    if depsPresent:
      # git/parallel are present in this sandbox, so checkDeps succeeds and
      # -h reaches the option loop's own -h|--help handling, which also
      # returns 0 — proving the two help paths are separate, not unified.
      let tmp = getTempDir() / "test_igro_help_dash_h.txt"
      let f = open(tmp, fmWrite)
      let code = run(@["-h"], f, f)
      f.close()
      let content = readFile(tmp)
      removeFile(tmp)
      check code == 0
      check content.contains("Usage: Invoke-GitRepositoryOptimization")
    else:
      echo "skipping -h asymmetry assertion: git/parallel not present in this sandbox"

  test "missing directory arg fails with exit 1":
    if depsPresent:
      check run(@[]) == 1
    else:
      echo "skipping: git/parallel not present in this sandbox"

  test "unknown option fails with exit 1":
    if depsPresent:
      check run(@["--bogus"]) == 1
    else:
      echo "skipping: git/parallel not present in this sandbox"

  test "--log with no path following it fails with exit 1":
    if depsPresent:
      check run(@["--log"]) == 1
    else:
      echo "skipping: git/parallel not present in this sandbox"

  test "empty git-dir filter result warns and returns 0 without invoking parallel":
    if depsPresent:
      let dir = mkTmpDir("igro_no_git_dirs")
      let tmp = getTempDir() / "test_igro_no_git_dirs_out.txt"
      let f = open(tmp, fmWrite)
      let code = run(@[dir], f, f)
      f.close()
      let content = readFile(tmp)
      removeFile(tmp)
      removeDir(dir)
      check code == 0
      check content.contains("No git repositories found in the provided directories.")
    else:
      echo "skipping: git/parallel not present in this sandbox"

  test "characterization: parallel receives jobs/progress flags and the gc command":
    let dir = getTempDir() / "char_invoke_git_repository_optimization"
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
    # gcCommand is a private (non-exported) const at
    # InvokeGitRepositoryOptimization.nim:8, so it's inlined here verbatim.
    let gcCommand = "git -C {} fetch --prune && git -C {} fsck --full && " &
      "git -C {} reflog expire --expire=90.days.ago && git -C {} gc --prune=90.days.ago"
    check code == 0
    check calls == @["--jobs 4 --progress " & gcCommand & " ::: repoA"]

  test "contract: parallel receives --jobs/--progress/--joblog and the gc command":
    # `git`/`parallel` are stubbed on a fixture $PATH via withPath, same as
    # the docker/zfs contract tests, so this test is environment-independent
    # and cannot silently skip: checkDeps only needs the stubs to exist,
    # and rec.runner intercepts the actual invocation so their (empty)
    # bodies are never run.
    let dir = getTempDir() / "contract_igro"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "git", "")
    writeFakeExe(dir, "parallel", "")
    let repoDir = dir / "repo"
    createDir(repoDir / ".git")
    let logPath = dir / "joblog.txt"
    let rec = newRecordingRunner(exitCode = 0)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--log", logPath, repoDir], f, f, rec.runner)
    f.close()
    removeDir(dir)
    # gcCommand is a private (non-exported) const at
    # InvokeGitRepositoryOptimization.nim:8, so it's inlined here verbatim.
    let gcCommand = "git -C {} fetch --prune && git -C {} fsck --full && " &
      "git -C {} reflog expire --expire=90.days.ago && git -C {} gc --prune=90.days.ago"
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "parallel"
    check rec.calls[0].args == @[
      "--jobs", "4", "--progress", "--joblog", logPath, gcCommand,
      ":::", repoDir
    ]

suite "filterGitDirs":
  test "keeps only directories that exist and contain .git":
    let root = mkTmpDir("igro_filter")
    let gitDir = root / "repo"
    let plainDir = root / "plain"
    let missingDir = root / "missing"
    createDir(gitDir / ".git")
    createDir(plainDir)
    let result = filterGitDirs(@[gitDir, plainDir, missingDir])
    removeDir(root)
    check result == @[gitDir]

  test "returns empty for no qualifying directories":
    let root = mkTmpDir("igro_filter_empty")
    let plainDir = root / "plain"
    createDir(plainDir)
    let result = filterGitDirs(@[plainDir, root / "missing"])
    removeDir(root)
    check result.len == 0
