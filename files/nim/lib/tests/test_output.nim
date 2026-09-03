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

suite "output.warn":
  test "writes a plain-text prefixed message to a non-tty file":
    let tmp = getTempDir() / "test_output_warn.txt"
    let f = open(tmp, fmWrite)
    warn("careful", f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check content == "Warning: careful\n"

suite "output.colorEnabled":
  test "is false for a plain file (never a tty)":
    let tmp = getTempDir() / "test_output_colorenabled.txt"
    let f = open(tmp, fmWrite)
    check colorEnabled(f) == false
    f.close()
    removeFile(tmp)

suite "output.confirm":
  test "returns true for a bare y":
    let tmp = getTempDir() / "test_output_confirm_in_y.txt"
    writeFile(tmp, "y\n")
    let inp = open(tmp, fmRead)
    let outTmp = getTempDir() / "test_output_confirm_out_y.txt"
    let outf = open(outTmp, fmWrite)
    let ok = confirm("Are you sure?", inp, outf)
    inp.close()
    outf.close()
    removeFile(tmp)
    removeFile(outTmp)
    check ok == true

  test "returns true for YeS in any case":
    let tmp = getTempDir() / "test_output_confirm_in_yes.txt"
    writeFile(tmp, "YeS\n")
    let inp = open(tmp, fmRead)
    let outTmp = getTempDir() / "test_output_confirm_out_yes.txt"
    let outf = open(outTmp, fmWrite)
    let ok = confirm("Are you sure?", inp, outf)
    inp.close()
    outf.close()
    removeFile(tmp)
    removeFile(outTmp)
    check ok == true

  test "returns false for n":
    let tmp = getTempDir() / "test_output_confirm_in_n.txt"
    writeFile(tmp, "n\n")
    let inp = open(tmp, fmRead)
    let outTmp = getTempDir() / "test_output_confirm_out_n.txt"
    let outf = open(outTmp, fmWrite)
    let ok = confirm("Are you sure?", inp, outf)
    inp.close()
    outf.close()
    removeFile(tmp)
    removeFile(outTmp)
    check ok == false

  test "returns false for an empty line (bare Enter)":
    let tmp = getTempDir() / "test_output_confirm_in_empty.txt"
    writeFile(tmp, "\n")
    let inp = open(tmp, fmRead)
    let outTmp = getTempDir() / "test_output_confirm_out_empty.txt"
    let outf = open(outTmp, fmWrite)
    let ok = confirm("Are you sure?", inp, outf)
    inp.close()
    outf.close()
    removeFile(tmp)
    removeFile(outTmp)
    check ok == false

  test "returns false at EOF with no data at all":
    let tmp = getTempDir() / "test_output_confirm_in_eof.txt"
    writeFile(tmp, "")
    let inp = open(tmp, fmRead)
    let outTmp = getTempDir() / "test_output_confirm_out_eof.txt"
    let outf = open(outTmp, fmWrite)
    let ok = confirm("Are you sure?", inp, outf)
    inp.close()
    outf.close()
    removeFile(tmp)
    removeFile(outTmp)
    check ok == false

  test "writes the message and (y/N) suffix to outp with no trailing newline":
    let tmp = getTempDir() / "test_output_confirm_in_prompt.txt"
    writeFile(tmp, "y\n")
    let inp = open(tmp, fmRead)
    let outTmp = getTempDir() / "test_output_confirm_out_prompt.txt"
    let outf = open(outTmp, fmWrite)
    discard confirm("Delete this?", inp, outf)
    inp.close()
    outf.close()
    let prompted = readFile(outTmp)
    removeFile(tmp)
    removeFile(outTmp)
    check prompted == "Delete this? (y/N): "
