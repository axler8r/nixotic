import std/[unittest, os, strutils]
import "../root"
import "../../../../lib/testing"

suite "ax git repo root isGitRepo":
  test "true when git rev-parse succeeds":
    let rec = newRecordingRunner(exitCode = 0)
    check isGitRepo("/some/dir", rec.runner) == true
    check rec.calls[0].args == @["-C", "/some/dir", "rev-parse", "--git-dir"]

  test "false when git rev-parse fails":
    let rec = newRecordingRunner(exitCode = 1)
    check isGitRepo("/some/dir", rec.runner) == false

suite "ax git repo root gitRemoteFetchUrl":
  test "returns origin's fetch URL when origin is present among several remotes":
    let rec = newRecordingRunner(exitCode = 0, output = "upstream\tgit@github.com:other/repo.git (fetch)\n" &
      "upstream\tgit@github.com:other/repo.git (push)\n" &
      "origin\tgit@github.com:me/repo.git (fetch)\n" &
      "origin\tgit@github.com:me/repo.git (push)\n")
    check gitRemoteFetchUrl("/some/dir", rec.runner) == "git@github.com:me/repo.git"

  test "falls back to the first remote's fetch URL when there is no origin":
    let rec = newRecordingRunner(exitCode = 0, output = "upstream\tgit@github.com:other/repo.git (fetch)\n" &
      "upstream\tgit@github.com:other/repo.git (push)\n")
    check gitRemoteFetchUrl("/some/dir", rec.runner) == "git@github.com:other/repo.git"

  test "returns empty string when there are no remotes at all":
    let rec = newRecordingRunner(exitCode = 0, output = "")
    check gitRemoteFetchUrl("/some/dir", rec.runner) == ""

suite "ax git repo root collectRepoRows":
  test "considers only non-hidden subdirectories, sorted":
    let dir = getTempDir() / "collect_repo_rows"
    removeDir(dir)
    createDir(dir)
    createDir(dir / "b-repo")
    createDir(dir / "a-repo")
    createDir(dir / ".hidden")
    writeFile(dir / "a-file.txt", "not a directory")
    let rec = newRecordingRunner(exitCode = 0, output = "")
    let rows = collectRepoRows(dir, rec.runner)
    removeDir(dir)
    check rows.len == 2
    check rows[0].path == dir / "a-repo"
    check rows[1].path == dir / "b-repo"

  test "a directory where rev-parse fails is excluded":
    let dir = getTempDir() / "collect_repo_rows_notrepo"
    removeDir(dir)
    createDir(dir)
    createDir(dir / "plain-dir")
    let rec = newRecordingRunner(exitCode = 1)
    let rows = collectRepoRows(dir, rec.runner)
    removeDir(dir)
    check rows.len == 0

suite "ax git repo root run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_resolve_git_repository_path_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax git repo root")

  test "missing git is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_resolve_git_repo_path"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands: git")

  test "contract: renders one row per discovered git subdirectory, via table":
    let dir = getTempDir() / "run_contract_resolve_git"
    removeDir(dir)
    createDir(dir)
    createDir(dir / "repo-a")
    writeFakeExe(dir, "git", "")
    let rec = newRecordingRunner(exitCode = 0,
      output = "origin\tgit@github.com:me/repo-a.git (fetch)\n" &
               "origin\tgit@github.com:me/repo-a.git (push)\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw"], f, f, rec.runner, dir)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls[^1].cmd == "column"
    check rec.calls[^1].input == "Remote|Path\ngit@github.com:me/repo-a.git|" & (dir / "repo-a") & "\n"
