import std/[unittest, os, osproc, streams, strutils]
import "../create"
import "../../../../lib/testing"

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

proc initRepoWithCommit(dir: string, subject: string) =
  runGit(dir, "init", "-q")
  runGit(dir, "config", "user.email", "test@example.invalid")
  runGit(dir, "config", "user.name", "Test")
  writeFile(dir / "README.md", "x")
  runGit(dir, "add", "README.md")
  runGit(dir, "commit", "-q", "-m", subject)

suite "ax git tag create extractCommitType":
  test "a plain type with no scope or bang":
    check extractCommitType("feat: add x") == "feat"

  test "a type with a parenthesized context":
    check extractCommitType("defect(nim): fix x") == "defect"

  test "a type with a bang, no scope":
    check extractCommitType("feat!: breaking change") == "feat"

  test "a type with both a bang and a scope, in that order":
    check extractCommitType("feat!(nim): breaking change") == "feat"

  test "an uppercase subject (e.g. a GitHub merge commit) has no type":
    check extractCommitType("Merge pull request #5") == ""

  test "no colon at all has no type":
    check extractCommitType("just a plain message") == ""

  test "an unclosed parenthesis has no type":
    check extractCommitType("feat(nim: add x") == ""

suite "ax git tag create parseLastTag":
  test "a well-formed tag parses its major/minor":
    let p = parseLastTag("v1.2.0+20260101120000")
    check p.valid == true
    check p.major == 1
    check p.minor == 2

  test "an empty tag is invalid":
    check parseLastTag("").valid == false

  test "a tag with a non-zero patch component is invalid":
    check parseLastTag("v1.2.3+20260101120000").valid == false

  test "a tag with a short timestamp is invalid":
    check parseLastTag("v1.2.0+2026").valid == false

  test "a tag missing the v prefix is invalid":
    check parseLastTag("1.2.0+20260101120000").valid == false

suite "ax git tag create run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_new_git_tag_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax git tag create")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_new_git_tag_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax git tag create")

  test "HEAD already tagged is an error":
    let dir = mkTmpDir("new_git_tag_already_tagged")
    initRepoWithCommit(dir, "feat: add x")
    runGit(dir, "tag", "-m", "test", "v0.1.0")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "new_git_tag_already_tagged_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("HEAD is already tagged: v0.1.0")

  test "--dry-run for a feat commit with no prior tags prints v1.0.0+<timestamp>":
    let dir = mkTmpDir("new_git_tag_dry_run_first")
    initRepoWithCommit(dir, "feat: add x")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "new_git_tag_dry_run_first_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["--dry-run"], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath).strip()
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check content.startsWith("v1.0.0+")
    check content.len == "v1.0.0+".len + 14

  test "--dry-run for a defect commit bumps minor from the last matching tag":
    let dir = mkTmpDir("new_git_tag_dry_run_minor")
    initRepoWithCommit(dir, "feat: add x")
    runGit(dir, "tag", "-m", "test", "v1.0.0+20260101000000")
    writeFile(dir / "fix.txt", "x")
    runGit(dir, "add", "fix.txt")
    runGit(dir, "commit", "-q", "-m", "defect: fix x")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "new_git_tag_dry_run_minor_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["--dry-run"], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath).strip()
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check content.startsWith("v1.1.0+")

  test "a feat commit after a minor bump resets minor to 0 and bumps major":
    let dir = mkTmpDir("new_git_tag_dry_run_major")
    initRepoWithCommit(dir, "feat: add x")
    runGit(dir, "tag", "-m", "test", "v1.3.0+20260101000000")
    writeFile(dir / "feature2.txt", "x")
    runGit(dir, "add", "feature2.txt")
    runGit(dir, "commit", "-q", "-m", "feat: add another feature")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "new_git_tag_dry_run_major_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["--dry-run"], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath).strip()
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check content.startsWith("v2.0.0+")

  test "an untaggable commit type prints 'No tag needed' and returns 0, even with --dry-run":
    let dir = mkTmpDir("new_git_tag_no_tag_needed")
    initRepoWithCommit(dir, "doc: update readme")
    let saved = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "new_git_tag_no_tag_needed_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["--dry-run"], f, f)
    f.close()
    setCurrentDir(saved)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check content.contains("No tag needed for type: doc.")

  test "characterization: full success computes, then creates, a signed tag":
    # `git tag -s` needs a GPG key this sandbox has no way to provision,
    # and a single RecordingRunner answer can't serve the three
    # differently-shaped capture() calls this flow makes before reaching
    # it (tag --points-at, log -1, tag -l all need different output to
    # even get this far) -- so this uses a real fake `git` that branches
    # on its own arguments, the same technique Resize-Vault (Wave 2) used
    # for its stat/numfmt/blkid chain.
    let dir = getTempDir() / "char_new_git_tag_success"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "git", """
""" & fakeRecorder(log) & """

case "$1 $2" in
  "rev-parse --is-inside-work-tree") exit 0 ;;
  "tag --points-at") echo "" ;;
  "log -1") echo "feat(nim): add a thing" ;;
  "tag -l") echo "" ;;
  "tag -s") exit 0 ;;
esac
""")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, f)
    f.close()
    let content = readFile(outPath)
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check content.contains("Tagged v1.0.0+")
    check calls[0] == "rev-parse --is-inside-work-tree"
    check calls[1] == "tag --points-at HEAD"
    check calls[2] == "log -1 --format=%s"
    check calls[3] == "tag -l v*.*.0+* --sort=-v:refname"
    check calls[4].startsWith("tag -s -a v1.0.0+")
    check calls[4].contains("-m 1.0.0")
