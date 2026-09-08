import std/[unittest, os, strutils]
import "../list"
import "../../../lib/testing"

suite "ax attr list run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_attributes_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax attr list")

  test "fails when the path argument is missing":
    check run(@[]) == 64

  test "fails on an unknown option":
    check run(@["-x", "/tmp"]) == 64

  test "fails with too many positional arguments":
    check run(@["/tmp", "extra"]) == 64

  test "fails when the path does not exist":
    check run(@["/definitely/not/a/real/path/xyz123"]) == 1

  test "contract: getfattr is called with --dump <path>":
    let rec = newRecordingRunner(exitCode = 0)
    let tmpFile = getTempDir() / "contract_get_attributes.txt"
    writeFile(tmpFile, "x")
    let code = run(@[tmpFile], stdout, stderr, rec.runner)
    removeFile(tmpFile)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "getfattr"
    check rec.calls[0].args == @["--dump", "--", tmpFile]
