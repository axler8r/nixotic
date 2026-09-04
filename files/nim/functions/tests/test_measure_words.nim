import std/[unittest, os, strutils]
import "../MeasureWords"
import "../../lib/testing"

suite "Measure-Words parseArgs":
  test "no args: directory empty, topN defaults to 15":
    let p = parseArgs(@[])
    check p.directory == ""
    check p.topN == 15
    check p.allFlag == false
    check p.raw == false

  test "-n overrides the top-N count":
    check parseArgs(@["-n", "5"]).topN == 5

  test "-e is repeatable and preserves order":
    check parseArgs(@["-e", "md", "-e", "txt"]).extensions == @["md", "txt"]

  test "an unrecognized flag stops parsing and is captured":
    let p = parseArgs(@["--bogus"])
    check p.unknownOption == "--bogus"

suite "Measure-Words extractExtension":
  test "returns the extension without a leading dot":
    check extractExtension("foo.py") == "py"
    check extractExtension("archive.tar.gz") == "gz"

  test "returns empty string for a file with no extension":
    check extractExtension("Makefile") == ""

suite "Measure-Words countWords":
  test "counts whitespace-separated tokens across the whole file":
    let dir = getTempDir() / "count_words"
    removeDir(dir)
    createDir(dir)
    let path = dir / "doc.txt"
    writeFile(path, "one two\nthree   four\nfive\n")
    let n = countWords(path)
    removeDir(dir)
    check n == 5

  test "returns zero for a missing file":
    check countWords("/definitely/not/a/real/path.txt") == 0

suite "Measure-Words run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_measure_words_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Measure-Words")

  test "an unknown option is an error, exit 1":
    let tmp = getTempDir() / "test_measure_words_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Unknown option: --bogus")

  test "a nonexistent directory is exit 1 with a Directory not found error":
    let tmp = getTempDir() / "test_measure_words_nodir.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["/definitely/not/a/real/dir/xyz123"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Directory not found")

  test "missing fd/file is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_measure_words"
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
    check content.contains("Missing commands:")

  test "contract: words are aggregated per extension, sorted descending, plus a total row":
    # Same reasoning as Find-MixedIndentation's equivalent test: fd and file
    # need genuinely different answers, so this drives the real
    # defaultRunner against fake scripts and captures column's stdin.
    let dir = getTempDir() / "run_contract_measure_words"
    removeDir(dir)
    createDir(dir)
    let scanDir = dir / "scan"
    createDir(scanDir)
    writeFile(scanDir / "a.py", "one two three")
    writeFile(scanDir / "b.md", "four five")
    writeFakeExe(dir, "fd", "printf '%s\\n%s\\n' " &
      (scanDir / "a.py").quoteShell & " " & (scanDir / "b.md").quoteShell)
    writeFakeExe(dir, "file", "echo text/plain")
    let stdinLog = dir / "column_stdin.log"
    writeFakeExe(dir, "column", "cat > " & stdinLog.quoteShell)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw", scanDir], f, f)
    f.close()
    let stdinContent = readFile(stdinLog)
    removeDir(dir)
    check code == 0
    check stdinContent == "Extension|Words|Files|Share\n" &
      ".py|3|1|60%\n.md|2|1|40%\nTotal|5|2|100%"

  test "no text files found is a warning, exit 0":
    let dir = getTempDir() / "run_no_text_files"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "fd", "")
    writeFakeExe(dir, "file", "")
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
    check errContent.contains("No text files found in '" & scanDir & "'")
