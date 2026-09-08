# Every test below that reaches checkDeps stubs `git` and `parallel` on a
# fixture $PATH via testing.writeFakeExe/withPath, so this file is
# environment-independent and cannot silently skip regardless of whether
# this sandbox has the real binaries — see flake.nix's nimToolchain for
# where they'd come from if a stub were ever missing.
# The `parallel` invocation (the gc/fetch/fsck chain) is characterized below
# against a fake `parallel` that records its argv, and pinned exactly by the
# contract test using a RecordingRunner -- real git maintenance commands are
# never run by either.
import std/[unittest, os, strutils]
import "../optimize"
import "../../../../lib/testing"

proc mkTmpDir(name: string): string =
  result = getTempDir() / name
  removeDir(result)
  createDir(result)

suite "ax git repo optimize run":
  test "--help short-circuits before checkDeps, returns 0":
    let tmp = getTempDir() / "test_igro_help_dashdash.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax git repo optimize")

  test "-h does NOT short-circuit before checkDeps (asymmetry vs --help)":
    # git/parallel are stubbed on a fixture $PATH via withPath, so checkDeps
    # succeeds regardless of this sandbox's real binaries and -h reaches
    # the option loop's own -h|--help handling, which also returns 0 --
    # proving the two help paths are separate, not unified. Neither stub is
    # ever actually run: -h returns before run() reaches `parallel`.
    let dir = getTempDir() / "deps_igro_dash_h"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "git", "")
    writeFakeExe(dir, "parallel", "")
    let tmp = getTempDir() / "test_igro_help_dash_h.txt"
    let f = open(tmp, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    removeDir(dir)
    check code == 0
    check content.contains("Usage: ax git repo optimize")

  test "missing directory arg fails with exit 64":
    # git/parallel are stubbed on a fixture $PATH so checkDeps passes and
    # the missing-arg check below it is what's under test; neither stub is
    # ever run.
    let dir = getTempDir() / "deps_igro_missing_dir"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "git", "")
    writeFakeExe(dir, "parallel", "")
    var code: int
    withPath(dir):
      code = run(@[])
    removeDir(dir)
    check code == 64

  test "unknown option fails with exit 64":
    let dir = getTempDir() / "deps_igro_unknown_opt"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "git", "")
    writeFakeExe(dir, "parallel", "")
    var code: int
    withPath(dir):
      code = run(@["--bogus"])
    removeDir(dir)
    check code == 64

  test "--log with no path following it fails with exit 64":
    let dir = getTempDir() / "deps_igro_log_no_path"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "git", "")
    writeFakeExe(dir, "parallel", "")
    var code: int
    withPath(dir):
      code = run(@["--log"])
    removeDir(dir)
    check code == 64

  test "empty git-dir filter result warns and returns 0 without invoking parallel":
    let dir = getTempDir() / "deps_igro_no_git_dirs"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "git", "")
    writeFakeExe(dir, "parallel", "")
    let repoArg = mkTmpDir("igro_no_git_dirs")
    let tmp = getTempDir() / "test_igro_no_git_dirs_out.txt"
    let f = open(tmp, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[repoArg], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    removeDir(repoArg)
    removeDir(dir)
    check code == 0
    check content.contains("No git repositories found in the provided directories.")

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
