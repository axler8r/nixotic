import std/[unittest, os, strutils, tempfiles]
import "../words"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/testing"

suite "ax fs words parseArgs":
  test "validated attached values and terminator retain their meaning":
    let args = @["-emd", "-e:txt", "-e=py", "-e=-suffix", "--top=2", "--", "--all"]
    check validateArgs(cmdSpec, args)
    let p = parseArgs(args)
    check p.unknownOption == ""
    check p.extensions == @["md", "txt", "py", "-suffix"]
    check p.topN == 2
    check p.directory == "--all"
    check not p.allFlag
    check parseArgs(@["-"]).directory == "-"

  test "no args: directory empty, topN defaults to 15":
    let p = parseArgs(@[])
    check p.directory == ""
    check p.topN == 15
    check p.allFlag == false
    check p.raw == false

  test "--top overrides the top-N count in split and attached forms":
    check parseArgs(@["--top", "5"]).topN == 5
    check parseArgs(@["--top=5"]).topN == 5

  test "invalid counts and extensions are rejected without subprocess calls":
    let f = open("/dev/null", fmWrite)
    defer: f.close()
    for args in @[@["--top", "0"], @["--top", "-2"], @["--top=oops"],
                  @["--top", "999999999999999999999999"], @["-n", "5"],
                  @["-e"], @["-e", ""], @["-e", "   "], @["one", "two"]]:
      let rec = newRecordingRunner()
      check run(args, f, f, rec.runner) == 64
      check rec.calls.len == 0

  test "attached extension is accepted":
    check parseArgs(@["-emd"]).extensions == @["md"]

  test "-e is repeatable and preserves order":
    check parseArgs(@["-e", "md", "-e", "txt"]).extensions == @["md", "txt"]

  test "an unrecognized flag stops parsing and is captured":
    let p = parseArgs(@["--bogus"])
    check p.unknownOption == "--bogus"

suite "ax fs words extractExtension":
  test "returns the extension without a leading dot":
    check extractExtension("foo.py") == "py"
    check extractExtension("archive.tar.gz") == "gz"

  test "returns empty string for a file with no extension":
    check extractExtension("Makefile") == ""

suite "ax fs words countWords":
  test "counts whitespace-separated tokens across the whole file":
    let dir = getTempDir() / "count_words"
    removeDir(dir)
    createDir(dir)
    let path = dir / "doc.txt"
    writeFile(path, "one two\nthree   four\nfive\n")
    let n = countWords(path)
    removeDir(dir)
    check n == 5

  test "missing file is an error rather than a zero count":
    expect IOError:
      discard countWords("/definitely/not/a/real/path.txt")

suite "ax fs words run":
  test "queued discovery or MIME failures cannot emit partial word totals":
    let dir = createTempDir("ax-words-scan-failure-", "")
    defer: removeDir(dir)
    writeFakeExe(dir, "fd", "")
    writeFakeExe(dir, "file", "")
    let first = dir / "first.txt"
    let second = dir / "second.txt"
    writeFile(first, "one two")
    writeFile(second, "three")
    for failedCall in 0 .. 2:
      var replies = @[
        CommandResult(exitCode: 0, output: first & "\0" & second & "\0"),
        CommandResult(exitCode: 0, output: "text/plain\n"),
        CommandResult(exitCode: 0, output: "text/plain\n")
      ]
      replies[failedCall].exitCode = 1
      replies[failedCall].error = "scanner failed"
      let rec = newRecordingRunner(replies = replies)
      let outPath = dir / "out"
      let errPath = dir / "err"
      let outf = open(outPath, fmWrite)
      let errf = open(errPath, fmWrite)
      var code: int
      withPath(dir):
        code = run(@[dir], outf, errf, rec.runner)
      outf.close()
      errf.close()
      check code == 1
      require rec.calls.len == failedCall + 1
      check rec.calls[0].cmd == "fd"
      if failedCall > 0:
        check rec.calls[^1].cmd == "file"
      check readFile(outPath) == ""
      let message = readFile(errPath)
      check message.contains("scanner failed")
      check not message.contains("No text files found")
      check not message.contains("No words found")

  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_measure_words_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax fs words")

  test "an unknown option is an error, exit 64":
    let tmp = getTempDir() / "test_measure_words_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
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
    writeFakeExe(dir, "fd", "printf '%s\\0%s\\0' " &
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
      ".py|3|1|60%\n.md|2|1|40%\nTotal|5|2|100%\n"

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
