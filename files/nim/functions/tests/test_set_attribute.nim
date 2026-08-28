import std/[unittest, os, strutils]
import "../SetAttribute"
import "../../lib/testing"

suite "Set-Attribute run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_set_attribute_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Set-Attribute")

  test "fails when the attribute argument is missing":
    check run(@[]) == 1

  test "fails when the value argument is missing":
    check run(@["comment"]) == 1

  test "fails when the path argument is missing":
    check run(@["comment", "hello"]) == 1

  test "fails on an unknown option":
    check run(@["-x", "comment", "hello", "/tmp"]) == 1

  test "fails with too many positional arguments":
    check run(@["comment", "hello", "/tmp", "extra"]) == 1

  test "fails on an invalid attribute name":
    check run(@["bad name!", "hello", getTempDir()]) == 1

  test "fails when the path does not exist":
    check run(@["comment", "hello", "/definitely/not/a/real/path/xyz123"]) == 1

  test "fails when the path is not writable":
    let tmp = getTempDir() / "test_set_attribute_readonly"
    writeFile(tmp, "x")
    setFilePermissions(tmp, {fpUserRead})
    let code = run(@["comment", "hello", tmp])
    setFilePermissions(tmp, {fpUserRead, fpUserWrite})
    removeFile(tmp)
    check code == 1

  test "contract: setfattr is called with --name user.<attribute> --value <value> <path>":
    let rec = newRecordingRunner(exitCode = 0)
    let tmpFile = getTempDir() / "contract_set_attribute.txt"
    writeFile(tmpFile, "x")
    let code = run(@["colour", "red", tmpFile], stdout, stderr, rec.runner)
    removeFile(tmpFile)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "setfattr"
    check rec.calls[0].args == @["--name", "user.colour", "--value", "red", tmpFile]
