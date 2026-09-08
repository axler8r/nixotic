import std/[unittest, os, strutils]
import "../output"
import "../process"
import "../testing"

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

suite "output.table":
  test "plain path is used when outp is not a tty, regardless of raw":
    let outTmp = getTempDir() / "test_output_table_nontty.txt"
    let outf = open(outTmp, fmWrite)
    let rec = newRecordingRunner(exitCode = 0, output = "Name  Size\n")
    let code = table("Name|Size", raw = false, runner = rec.runner, outp = outf)
    outf.close()
    removeFile(outTmp)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].kind == "capture"
    check rec.calls[0].cmd == "column"
    check rec.calls[0].args == @["-t", "-s|"]
    check rec.calls[0].input == "Name|Size"

  test "raw=true also selects column, same as the non-tty default":
    let outTmp = getTempDir() / "test_output_table_raw.txt"
    let outf = open(outTmp, fmWrite)
    let rec = newRecordingRunner(exitCode = 0)
    let code = table("Name|Size\nfoo.txt|1.2 KB", raw = true, runner = rec.runner,
                     outp = outf)
    outf.close()
    removeFile(outTmp)
    check code == 0
    check rec.calls[0].cmd == "column"
    check rec.calls[0].input == "Name|Size\nfoo.txt|1.2 KB"

  test "writes the runner's captured stdout to outp":
    let outTmp = getTempDir() / "test_output_table_stdout.txt"
    let outf = open(outTmp, fmWrite)
    let rec = newRecordingRunner(exitCode = 0, output = "Name  Size\nfoo.txt  1.2 KB\n")
    discard table("Name|Size\nfoo.txt|1.2 KB", raw = true, runner = rec.runner,
                  outp = outf)
    outf.close()
    let content = readFile(outTmp)
    removeFile(outTmp)
    check content == "Name  Size\nfoo.txt  1.2 KB\n"

  test "forwards a nonzero exit code and writes the runner's captured stderr to errp":
    let outTmp = getTempDir() / "test_output_table_err_out.txt"
    let errTmp = getTempDir() / "test_output_table_err_err.txt"
    let outf = open(outTmp, fmWrite)
    let errf = open(errTmp, fmWrite)
    let rec = newRecordingRunner(exitCode = 1, error = "column: bad option\n")
    let code = table("Name|Size", raw = true, runner = rec.runner, outp = outf,
                     errp = errf)
    outf.close()
    errf.close()
    let errContent = readFile(errTmp)
    removeFile(outTmp)
    removeFile(errTmp)
    check code == 1
    check errContent == "column: bad option\n"

  test "real invocation: column -t -s| actually aligns pipe-delimited rows":
    # Requires util-linux's `column` for real, past the runner seam — see
    # flake.nix's nimToolchain.
    let outTmp = getTempDir() / "test_output_table_real.txt"
    let outf = open(outTmp, fmWrite)
    let code = table("Name|Size\nfoo.txt|1.2 KB", raw = true, outp = outf)
    outf.close()
    let content = readFile(outTmp)
    removeFile(outTmp)
    check code == 0
    check content.contains("Name")
    check content.contains("foo.txt")
    check not content.contains("|")
