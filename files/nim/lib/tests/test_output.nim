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

suite "output.info":
  test "writes a plain-text prefixed message to a non-tty file":
    let tmp = getTempDir() / "test_output_info.txt"
    let f = open(tmp, fmWrite)
    info("reconciling", f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check content == "Info: reconciling\n"

suite "output.success":
  test "writes a plain-text prefixed message to a non-tty file":
    let tmp = getTempDir() / "test_output_success.txt"
    let f = open(tmp, fmWrite)
    success("done", f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check content == "Success: done\n"

suite "output.colorEnabled":
  test "is false for a plain file (never a tty)":
    let tmp = getTempDir() / "test_output_colorenabled.txt"
    let f = open(tmp, fmWrite)
    check colorEnabled(f) == false
    f.close()
    removeFile(tmp)
