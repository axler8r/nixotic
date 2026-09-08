import std/[unittest, os, strutils]
import "../get"
import "../../../lib/testing"

suite "ax attr get run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_attribute_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax attr get")

  test "fails when the attribute argument is missing":
    check run(@[]) == 64

  test "fails when the path argument is missing":
    check run(@["user.comment"]) == 64

  test "fails on an unknown option":
    check run(@["-x", "user.comment", "/tmp"]) == 64

  test "fails with too many positional arguments":
    check run(@["user.comment", "/tmp", "extra"]) == 64

  test "fails on an invalid attribute name":
    check run(@["bad name!", getTempDir()]) == 64

  test "fails when the path does not exist":
    check run(@["user.comment", "/definitely/not/a/real/path/xyz123"]) == 1

  test "contract: getfattr is called with --name user.<attribute> <path>":
    let rec = newRecordingRunner(exitCode = 0)
    let tmpFile = getTempDir() / "contract_get_attribute.txt"
    writeFile(tmpFile, "x")
    let code = run(@["colour", tmpFile], stdout, stderr, rec.runner)
    removeFile(tmpFile)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "getfattr"
    check rec.calls[0].args == @["--name", "user.colour", "--", tmpFile]
