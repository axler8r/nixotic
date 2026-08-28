import std/[unittest, os, posix, strutils]
import "../../lib/testing"
import "../GetHelp"

suite "Get-Help run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_help_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-Help")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_get_help_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-Help")

  test "unknown option before the command is an error":
    let tmp = getTempDir() / "test_get_help_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus", "true"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Unknown option: --bogus")

  test "missing command arg is an error":
    let tmp = getTempDir() / "test_get_help_missing.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Missing required argument: command")

  test "missing command arg after --raw is an error":
    let tmp = getTempDir() / "test_get_help_raw_missing.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--raw"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Missing required argument: command")

  test "command not found is an error":
    let tmp = getTempDir() / "test_get_help_notfound.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["__no_such_cmd_xyz"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Command not found: __no_such_cmd_xyz")

  test "--raw path returns the queried command's own exit code":
    # `true` is a dependency-free, always-present coreutils command whose
    # `--help` still exits 0 (GNU coreutils' `true --help` prints usage and
    # exits 0 rather than erroring on the unrecognised-looking flag).
    check run(@["--raw", "true"]) == 0

  test "non-TTY passthrough survives large output on both streams":
    # NOTE: this covers the --raw / non-TTY passthrough branch
    # (process.runInherited), NOT the bat pipeline. `run` reaches the bat
    # branch only when isatty(outp), and a file is never a TTY, so a
    # file-backed test lands here. That branch deliberately hands the child
    # the real terminal's fds rather than outp/errp (matching the zsh
    # original), so fo/fe alone would capture nothing -- fd 1 and 2 are
    # redirected to the files for the duration of the call instead.
    # The bat pipeline's concurrent-drain behaviour is covered by
    # lib/tests/test_process.nim; end-to-end it needs a real TTY.
    let dir = getTempDir() / "test_get_help_large"
    removeDir(dir)
    createDir(dir)
    # 300KB of help text on stdout, plus noise on stderr: past the pipe
    # buffer on both streams.
    writeFakeExe(dir, "verbose-tool", """
i=0
while [ $i -lt 4096 ]; do
  echo "usage line 0123456789012345678901234567890123456789012345678901234567890123"
  i=$((i + 1))
done
echo "a warning" >&2
exit 0
""")
    let outPath = dir / "out.txt"
    let errPath = dir / "err.txt"
    let fo = open(outPath, fmWrite)
    let fe = open(errPath, fmWrite)
    var code: int
    stdout.flushFile()
    stderr.flushFile()
    let savedOut = dup(1.cint)
    let savedErr = dup(2.cint)
    try:
      discard dup2(fo.getFileHandle(), 1.cint)
      discard dup2(fe.getFileHandle(), 2.cint)
      withPath(dir):
        code = run(@["verbose-tool"], fo, fe)
    finally:
      discard dup2(savedOut, 1.cint)
      discard dup2(savedErr, 2.cint)
      discard posix.close(savedOut)
      discard posix.close(savedErr)
    fo.close()
    fe.close()
    let outContent = readFile(outPath)
    let errContent = readFile(errPath)
    removeDir(dir)
    check code == 0
    check outContent.len >= 290_000
    check errContent.contains("a warning")
