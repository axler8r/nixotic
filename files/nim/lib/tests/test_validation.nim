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
