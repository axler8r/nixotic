# These tests need `git` and `parallel` on $PATH at test-compile-time — see
# flake.nix's nim-functions-tests nativeBuildInputs. The actual `parallel`
# invocation (pull + submodule update) is not exercised here — it would run
# real git network operations against whatever's on disk. That path is
# exercised by manual/production use only.
import std/[unittest, os, strutils]
import "../UpdateGitRepository"

proc mkTmpDir(name: string): string =
  result = getTempDir() / name
  removeDir(result)
  createDir(result)

let depsPresent = findExe("git").len > 0 and findExe("parallel").len > 0

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
    if depsPresent:
      let dir = mkTmpDir("ugr_no_git_dirs")
      let oldDir = getCurrentDir()
      setCurrentDir(dir)
      let tmp = getTempDir() / "test_ugr_no_git_dirs_out.txt"
      let f = open(tmp, fmWrite)
      let code = run(@[], f, f)
      f.close()
      setCurrentDir(oldDir)
      let content = readFile(tmp)
      removeFile(tmp)
      removeDir(dir)
      check code == 0
      check content.contains("Info: No git repositories found.")
      check not content.contains("Warning:")
    else:
      echo "skipping: git/parallel not present in this sandbox"

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
