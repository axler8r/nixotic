import std/[unittest, os, strutils]
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
