import std/[unittest, os, strutils]
import "../RemoveAttribute"
import "../../lib/testing"

suite "Remove-Attribute run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_remove_attribute_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Remove-Attribute")

  test "fails when the attribute argument is missing":
    check run(@[]) == 1

  test "fails when the path argument is missing":
    check run(@["comment"]) == 1

  test "fails on an unknown option":
    check run(@["-x", "comment", "/tmp"]) == 1

  test "fails with too many positional arguments":
    check run(@["comment", "/tmp", "extra"]) == 1

  test "fails on an invalid attribute name":
    check run(@["bad name!", getTempDir()]) == 1

  test "fails when the path does not exist":
    check run(@["comment", "/definitely/not/a/real/path/xyz123"]) == 1

  test "fails when the path is not writable":
    let tmp = getTempDir() / "test_remove_attribute_readonly"
    writeFile(tmp, "x")
    setFilePermissions(tmp, {fpUserRead})
    let code = run(@["comment", tmp])
    setFilePermissions(tmp, {fpUserRead, fpUserWrite})
    removeFile(tmp)
    check code == 1

  test "contract: setfattr is called with --remove user.<attribute> <path>":
    let rec = newRecordingRunner(exitCode = 0)
    let tmpFile = getTempDir() / "contract_remove_attribute.txt"
    writeFile(tmpFile, "x")
    let code = run(@["colour", tmpFile], stdout, stderr, rec.runner)
    removeFile(tmpFile)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "setfattr"
    check rec.calls[0].args == @["--remove", "user.colour", tmpFile]
