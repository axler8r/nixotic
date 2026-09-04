import std/[unittest, os, strutils]
import "../GetSwapUsage"
import "../../lib/testing"

suite "Get-SwapUsage readStatusFields":
  test "parses VmSwap and Name from a typical status file":
    let dir = getTempDir() / "read_status_fields_typical"
    removeDir(dir)
    createDir(dir)
    let path = dir / "status"
    writeFile(path, "Name:\tbash\nVmSwap:\t    1234 kB\n")
    let fields = readStatusFields(path)
    removeDir(dir)
    check fields.swapKb == 1234
    check fields.name == "bash"

  test "defaults to zero swap when VmSwap is missing":
    let dir = getTempDir() / "read_status_fields_noswap"
    removeDir(dir)
    createDir(dir)
    let path = dir / "status"
    writeFile(path, "Name:\tinit\n")
    let fields = readStatusFields(path)
    removeDir(dir)
    check fields.swapKb == 0
    check fields.name == "init"

  test "returns zero/empty for a missing file, matching grep's 2>/dev/null suppression":
    check readStatusFields("/definitely/not/a/real/path/status") == (0, "")

suite "Get-SwapUsage collectSwapRows":
  test "only includes numeric-named entries with VmSwap > 0":
    let dir = getTempDir() / "collect_swap_rows"
    removeDir(dir)
    createDir(dir)
    createDir(dir / "123")
    writeFile(dir / "123" / "status", "Name:\tfirefox\nVmSwap:\t    2048 kB\n")
    createDir(dir / "456")
    writeFile(dir / "456" / "status", "Name:\tinit\nVmSwap:\t       0 kB\n")
    createDir(dir / "self")
    writeFile(dir / "self" / "status", "Name:\tbogus\nVmSwap:\t    9999 kB\n")
    let rows = collectSwapRows(dir)
    removeDir(dir)
    check rows == @[(swapKb: 2048, pid: "123", name: "firefox")]

  test "returns an empty seq when nothing is using swap":
    let dir = getTempDir() / "collect_swap_rows_empty"
    removeDir(dir)
    createDir(dir)
    createDir(dir / "789")
    writeFile(dir / "789" / "status", "Name:\tinit\nVmSwap:\t       0 kB\n")
    let rows = collectSwapRows(dir)
    removeDir(dir)
    check rows.len == 0

suite "Get-SwapUsage run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_swap_usage_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-SwapUsage")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_get_swap_usage_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-SwapUsage")

  test "an unknown option is an error, exit 1":
    let tmp = getTempDir() / "test_get_swap_usage_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Unknown option: --bogus")

  test "prints an info message and returns 0 when nothing is using swap":
    let dir = getTempDir() / "run_no_swap"
    removeDir(dir)
    createDir(dir)
    createDir(dir / "1")
    writeFile(dir / "1" / "status", "Name:\tinit\nVmSwap:\t       0 kB\n")
    let outTmp = dir / "out.txt"
    let errTmp = dir / "err.txt"
    let outf = open(outTmp, fmWrite)
    let errf = open(errTmp, fmWrite)
    let code = run(@[], outf, errf, procDir = dir)
    outf.close()
    errf.close()
    let errContent = readFile(errTmp)
    removeDir(dir)
    check code == 0
    check errContent.contains("No processes currently using swap.")

  test "contract: rows are sorted by real swap usage descending, comma-formatted, rendered via table":
    let dir = getTempDir() / "run_contract"
    removeDir(dir)
    createDir(dir)
    createDir(dir / "111")
    writeFile(dir / "111" / "status", "Name:\tfoo\nVmSwap:\t    500 kB\n")
    createDir(dir / "222")
    writeFile(dir / "222" / "status", "Name:\tbar\nVmSwap:\t    12345 kB\n")
    let rec = newRecordingRunner(exitCode = 0)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["--raw"], f, f, rec.runner, dir)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "column"
    check rec.calls[0].input == "Swap|PID|Process\n12,345 KB|222|bar\n500 KB|111|foo"

  test "real invocation against the actual /proc always exits 0":
    let tmp = getTempDir() / "test_get_swap_usage_real.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    removeFile(tmp)
    check code == 0
