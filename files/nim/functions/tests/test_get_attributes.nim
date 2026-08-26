import std/[unittest, os, strutils]
import "../GetAttributes"

suite "Get-Attributes run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_attributes_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-Attributes")

  test "fails when the path argument is missing":
    check run(@[]) == 1

  test "fails on an unknown option":
    check run(@["-x", "/tmp"]) == 1

  test "fails with too many positional arguments":
    check run(@["/tmp", "extra"]) == 1

  test "fails when the path does not exist":
    check run(@["/definitely/not/a/real/path/xyz123"]) == 1
