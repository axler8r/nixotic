import std/[unittest, os, strutils]
import "../histogram"
import "../../../lib/testing"

suite "ax fs histogram parseArgs":
  test "no args: directory empty, no flags":
    let p = parseArgs(@[])
    check p.directory == ""
    check p.allFlag == false
    check p.unknownOption == ""

  test "--raw is not a recognized option — it's an unknown flag":
    let p = parseArgs(@["--raw"])
    check p.unknownOption == "--raw"

  test "-e is repeatable and preserves order":
    check parseArgs(@["-e", "jpg", "-e", "png"]).extensions == @["jpg", "png"]

suite "ax fs histogram binIndex":
  test "a size under the first limit lands in bin 0":
    check binIndex(500) == 0

  test "a size exactly at a limit lands in the NEXT bin (strictly-less comparison)":
    check binIndex(1024) == 1

  test "a size at or above the last limit lands in the overflow bin":
    check binIndex(1073741824) == 7
    check binIndex(999999999999) == 7

suite "ax fs histogram formatSizeLabel":
  test "bytes under 1KB print as a bare byte count":
    check formatSizeLabel(500) == "500 B"

  test "kilobytes, megabytes, and gigabytes print with one decimal place":
    check formatSizeLabel(2048) == "2.0 KB"
    check formatSizeLabel(1572864) == "1.5 MB"
    check formatSizeLabel(2147483648) == "2.0 GB"

suite "ax fs histogram run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_show_file_size_histogram_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax fs histogram")

  test "--raw is an unknown-option error, exit 64":
    let tmp = getTempDir() / "test_show_file_size_histogram_raw.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--raw"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Unknown option: --raw")

  test "a nonexistent directory is exit 1 with a Directory not found error":
    let tmp = getTempDir() / "test_show_file_size_histogram_nodir.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["/definitely/not/a/real/dir/xyz123"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Directory not found")

  test "missing fd is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_show_file_size_histogram"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[dir], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands: fd")

  test "contract: files are binned by size and rendered via table, always non-raw":
    # ax fs histogram never calls `file` (no MIME filtering), so
    # only one external answer varies — fd's listing — and a single
    # RecordingRunner canned output can safely serve that, since nothing
    # else routed through the same runner (the eventual `column` call)
    # depends on what it returns. getFileSize itself is a native os call,
    # not routed through the runner at all, so small.txt/bigger.txt must
    # still exist for real on disk with their real sizes.
    let dir = getTempDir() / "run_contract_histogram"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "fd", "")
    let scanDir = dir / "scan"
    createDir(scanDir)
    let smallPath = scanDir / "small.txt"
    let bigPath = scanDir / "bigger.txt"
    writeFile(smallPath, "x")
    writeFile(bigPath, "x".repeat(2000))
    let rec = newRecordingRunner(exitCode = 0, output = smallPath & "\n" & bigPath & "\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[scanDir], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 2
    check rec.calls[0].cmd == "fd"
    check rec.calls[1].cmd == "column"
    check rec.calls[1].input.startsWith("Range|Distribution|Files\n")
    # bin 0 ("0B-1KB") has 1 file, bin 1 ("1KB-10KB") has 1 file
    check rec.calls[1].input.contains("|1\n") or rec.calls[1].input.contains("|1")

  test "no files found is a warning, exit 0":
    let dir = getTempDir() / "run_no_files_histogram"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "fd", "")
    let scanDir = dir / "scan"
    createDir(scanDir)
    let outPath = dir / "out.txt"
    let errPath = dir / "err.txt"
    let outf = open(outPath, fmWrite)
    let errf = open(errPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[scanDir], outf, errf)
    outf.close()
    errf.close()
    let errContent = readFile(errPath)
    removeDir(dir)
    check code == 0
    check errContent.contains("No files found in '" & scanDir & "'")
