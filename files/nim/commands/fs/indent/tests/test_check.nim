import std/[unittest, os, strutils, tempfiles]
import "../check"
import "../../../../lib/process"
import "../../../../lib/spec"
import "../../../../lib/testing"

suite "ax fs indent check parseArgs":
  test "validated attached values and terminator retain their meaning":
    let args = @["-epy", "-e:js", "-e=nim", "-e=-suffix", "--", "--raw"]
    check validateArgs(cmdSpec, args)
    let p = parseArgs(args)
    check p.unknownOption == ""
    check p.extensions == @["py", "js", "nim", "-suffix"]
    check p.directory == "--raw"
    check not p.raw
    check parseArgs(@["-"]).directory == "-"

  test "no args: directory empty, no flags":
    let p = parseArgs(@[])
    check p.directory == ""
    check p.allFlag == false
    check p.raw == false
    check p.extensions.len == 0
    check p.unknownOption == ""

  test "-e is repeatable and preserves order":
    check parseArgs(@["-e", "py", "-e", "js"]).extensions == @["py", "js"]

  test "--all and --raw set their flags":
    let p = parseArgs(@["--all", "--raw"])
    check p.allFlag == true
    check p.raw == true

  test "a second directory is rejected instead of overwriting the first":
    check parseArgs(@["/tmp", "/var"]).unknownOption.len > 0

  test "an unrecognized flag stops parsing and is captured":
    let p = parseArgs(@["--bogus", "/tmp"])
    check p.unknownOption == "--bogus"
    check p.directory == ""

suite "ax fs indent check countTabSpaceLines":
  test "counts lines starting with a tab separately from lines starting with a space":
    let dir = getTempDir() / "count_tab_space_lines"
    removeDir(dir)
    createDir(dir)
    let path = dir / "mixed.txt"
    writeFile(path, "\tfoo\n bar\n\tbaz\nqux\n")
    let counts = countTabSpaceLines(path)
    removeDir(dir)
    check counts.tabLines == 2
    check counts.spaceLines == 1

  test "missing file raises rather than looking clean":
    expect IOError:
      discard countTabSpaceLines("/definitely/not/a/real/path.txt")

suite "ax fs indent check stripDirPrefix":
  test "strips the directory plus a slash from a matching file path":
    check stripDirPrefix("./foo.py", ".") == "foo.py"
    check stripDirPrefix("/tmp/proj/src/foo.py", "/tmp/proj") == "src/foo.py"

  test "strips a trailing slash on dir before matching":
    check stripDirPrefix("/tmp/proj/foo.py", "/tmp/proj/") == "foo.py"

  test "returns the file unchanged when it doesn't start with the prefix":
    check stripDirPrefix("other/foo.py", "/tmp/proj") == "other/foo.py"

suite "ax fs indent check run":
  test "queued discovery or MIME failures never report a clean or partial scan":
    let dir = createTempDir("ax-indent-scan-failure-", "")
    defer: removeDir(dir)
    writeFakeExe(dir, "fd", "")
    writeFakeExe(dir, "file", "")
    let first = dir / "first.py"
    let second = dir / "second.py"
    writeFile(first, "\tfoo\n bar\n")
    writeFile(second, " baz\n")
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
      check not message.contains("No files found")
      check not message.contains("No mixed indentation found")

  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_find_mixed_indentation_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax fs indent check")

  test "an unknown option is an error, exit 64":
    let tmp = getTempDir() / "test_find_mixed_indentation_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Unknown option: --bogus")

  test "a nonexistent directory is exit 1 with a Directory not found error":
    let tmp = getTempDir() / "test_find_mixed_indentation_nodir.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["/definitely/not/a/real/dir/xyz123"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Directory not found")

  test "missing fd/file is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_find_mixed_indentation"
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

  # `fd` is driven by a dedicated fake script (its output must differ from
  # `file`'s), while `file`'s own answer and the table render both go
  # through a RecordingRunner (which answers every capture call
  # identically) — this still exercises the full filter/aggregate/render
  # pipeline deterministically.

  test "contract: reports files where BOTH tab- and space-indented lines are found":
    # A RecordingRunner answers every capture call identically, which can't
    # express "fd returns a path, file returns a mime type" — this test
    # instead runs the real defaultRunner against fake fd/file/column
    # scripts on a fixture $PATH, and captures column's stdin (the table
    # data) to a log file via a `cat > log` fake body.
    let dir = getTempDir() / "run_contract_mixed_indent"
    removeDir(dir)
    createDir(dir)
    let scanDir = dir / "scan"
    createDir(scanDir)
    writeFile(scanDir / "mixed.py", "\tfoo\n bar\n")
    writeFakeExe(dir, "fd", "printf '%s\\0' " & (scanDir / "mixed.py").quoteShell)
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
    check code == 1
    check stdinContent == "File|Tabs|Spaces\nmixed.py|1|1\n"

  test "files where file --mime-type isn't text/* are skipped entirely":
    # Here a single RecordingRunner canned answer is fine: it only needs to
    # serve as BOTH fd's one-file listing AND that same file's mime type,
    # and a real filesystem path is never going to look like "text/*" — the
    # skip we're testing for falls out naturally either way.
    let dir = getTempDir() / "run_contract_mixed_indent_binary"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "fd", "")
    writeFakeExe(dir, "file", "")
    let scanDir = dir / "scan"
    createDir(scanDir)
    let filePath = scanDir / "mixed.bin"
    writeFile(filePath, "\tfoo\n bar\n")
    let rec = newRecordingRunner(exitCode = 0, output = filePath)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[scanDir], f, f, rec.runner)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 0
    check content.contains("No mixed indentation found (0 files checked, 1 skipped)")
