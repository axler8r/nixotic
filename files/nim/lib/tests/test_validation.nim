import std/[unittest, os]
import "../validation"

suite "validation.requireArg":
  test "fails on empty value":
    check requireArg("", "attribute") == false

  test "succeeds on non-empty value":
    check requireArg("foo", "attribute") == true

suite "validation.checkDeps":
  test "fails when a command is missing":
    check checkDeps(["definitely-not-a-real-command-xyz123"]) == false

  test "succeeds when all commands exist":
    check checkDeps(["nim"]) == true

suite "validation.requirePathTarget":
  test "fails when path does not exist":
    check requirePathTarget("/definitely/not/a/real/path/xyz123") == false

  test "succeeds for an existing directory":
    check requirePathTarget(getTempDir()) == true

  test "fails when path exists but is not a file or directory":
    check requirePathTarget("/dev/null") == false

suite "validation.requireXattrName":
  test "fails on invalid characters":
    check requireXattrName("bad name!") == false

  test "fails on empty string":
    check requireXattrName("") == false

  test "succeeds on a valid name":
    check requireXattrName("user.comment") == true

suite "validation.requireFile":
  test "fails when the file does not exist":
    check requireFile("/definitely/not/a/real/path/xyz123") == false

  test "fails when the path is a directory, not a file":
    check requireFile(getTempDir()) == false

  test "succeeds for an existing file":
    let tmp = getTempDir() / "test_require_file_exists"
    writeFile(tmp, "x")
    let ok = requireFile(tmp)
    removeFile(tmp)
    check ok == true

suite "validation.requireWritablePathTarget":
  test "fails when path does not exist":
    check requireWritablePathTarget("/definitely/not/a/real/path/xyz123") == false

  test "succeeds for a writable existing directory":
    check requireWritablePathTarget(getTempDir()) == true

  test "fails when path exists but is not writable":
    let tmp = getTempDir() / "test_require_writable_readonly"
    writeFile(tmp, "x")
    setFilePermissions(tmp, {fpUserRead})
    let ok = requireWritablePathTarget(tmp)
    setFilePermissions(tmp, {fpUserRead, fpUserWrite})
    removeFile(tmp)
    check ok == false
