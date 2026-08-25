import std/[unittest, os]
import "../output"

suite "output.error":
  test "writes a plain-text prefixed message to a non-tty file":
    let tmp = getTempDir() / "test_output_error.txt"
    let f = open(tmp, fmWrite)
    error("boom", f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check content == "Error: boom\n"

suite "output.colorEnabled":
  test "is false for a plain file (never a tty)":
    let tmp = getTempDir() / "test_output_colorenabled.txt"
    let f = open(tmp, fmWrite)
    check colorEnabled(f) == false
    f.close()
    removeFile(tmp)
