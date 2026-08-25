import std/[unittest, os, strutils]
import "../GetAttribute"

suite "Get-Attribute run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_attribute_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-Attribute")

  test "fails when the attribute argument is missing":
    check run(@[]) == 1

  test "fails when the path argument is missing":
    check run(@["user.comment"]) == 1

  test "fails on an unknown option":
    check run(@["-x", "user.comment", "/tmp"]) == 1

  test "fails with too many positional arguments":
    check run(@["user.comment", "/tmp", "extra"]) == 1

  test "fails on an invalid attribute name":
    check run(@["bad name!", getTempDir()]) == 1

  test "fails when the path does not exist":
    check run(@["user.comment", "/definitely/not/a/real/path/xyz123"]) == 1
