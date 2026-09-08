import std/[unittest, os, strutils]
import "../remove"
import "../../../lib/process"
import "../../../lib/testing"

suite "ax dev remove parseArgs":
  test "no args: gc false, no errors":
    let p = parseArgs(@[])
    check p.gc == false
    check p.unknownOption == ""
    check p.unexpectedArg == ""

  test "--gc sets the flag":
    let p = parseArgs(@["--gc"])
    check p.gc == true

  test "an unknown option is captured and stops parsing":
    let p = parseArgs(@["--bogus"])
    check p.unknownOption == "--bogus"

  test "a bare positional argument is an unexpected-argument error":
    let p = parseArgs(@["extra"])
    check p.unexpectedArg == "extra"

  test "--gc keeps looping, so a later bad token is still caught":
    let p = parseArgs(@["--gc", "extra"])
    check p.gc == true
    check p.unexpectedArg == "extra"

suite "ax dev remove run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_remove_dev_environment_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax dev remove")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_remove_dev_environment_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax dev remove")

  test "an unknown option is an error":
    let tmp = getTempDir() / "test_remove_dev_environment_unknown.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Unknown option: --bogus")

  test "an unexpected positional argument is an error":
    let tmp = getTempDir() / "test_remove_dev_environment_unexpected.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["extra"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Unexpected argument: extra")

  test "no flake.nix in the current directory is an error":
    let dir = getTempDir() / "test_remove_dev_environment_no_flake"
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "test_remove_dev_environment_no_flake_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[], f, f)
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("No flake.nix found in current directory")

  test "declining the confirmation prompt removes nothing and returns 0":
    let dir = getTempDir() / "test_remove_dev_environment_decline"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "flake.nix", "content")
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    let inTmp = getTempDir() / "test_remove_dev_environment_decline_in.txt"
    writeFile(inTmp, "n\n")
    let inp = open(inTmp, fmRead)
    let outPath = getTempDir() / "test_remove_dev_environment_decline_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[], f, f, defaultRunner, inp)
    inp.close()
    f.close()
    setCurrentDir(savedDir)
    let stillThere = fileExists(dir / "flake.nix")
    removeFile(inTmp)
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check stillThere == true

  test "accepting removes flake.nix/.envrc/.direnv and returns 0 even when .direnv never existed (the fixed quirk)":
    # The zsh original's exit code accidentally depended on whether
    # .direnv existed when --gc wasn't passed (see plan Global
    # Constraints); this pins the fix: 0 regardless.
    let dir = getTempDir() / "test_remove_dev_environment_accept_no_direnv"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "flake.nix", "content")
    writeFile(dir / ".envrc", "use flake\n")
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    let inTmp = getTempDir() / "test_remove_dev_environment_accept_no_direnv_in.txt"
    writeFile(inTmp, "y\n")
    let inp = open(inTmp, fmRead)
    let outPath = getTempDir() / "test_remove_dev_environment_accept_no_direnv_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[], f, f, defaultRunner, inp)
    inp.close()
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    let flakeGone = not fileExists(dir / "flake.nix")
    let envrcGone = not fileExists(dir / ".envrc")
    removeFile(inTmp)
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check flakeGone
    check envrcGone
    check content.contains("Removed flake.nix")
    check content.contains("Removed .envrc")
    check not content.contains("Removed .direnv/")

  test "accepting with .direnv present removes it too and prints the message":
    let dir = getTempDir() / "test_remove_dev_environment_accept_with_direnv"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "flake.nix", "content")
    createDir(dir / ".direnv")
    writeFile(dir / ".direnv" / "marker", "x")
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    let inTmp = getTempDir() / "test_remove_dev_environment_accept_with_direnv_in.txt"
    writeFile(inTmp, "y\n")
    let inp = open(inTmp, fmRead)
    let outPath = getTempDir() / "test_remove_dev_environment_accept_with_direnv_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[], f, f, defaultRunner, inp)
    inp.close()
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    let direnvGone = not dirExists(dir / ".direnv")
    removeFile(inTmp)
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check direnvGone
    check content.contains("Removed .direnv/")

  test "contract: --gc runs nix store gc and returns its real exit code":
    let dir = getTempDir() / "test_remove_dev_environment_gc"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "flake.nix", "content")
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    let inTmp = getTempDir() / "test_remove_dev_environment_gc_in.txt"
    writeFile(inTmp, "y\n")
    let inp = open(inTmp, fmRead)
    let rec = newRecordingRunner(exitCode = 1)
    let outPath = getTempDir() / "test_remove_dev_environment_gc_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["--gc"], f, f, rec.runner, inp)
    inp.close()
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    removeFile(inTmp)
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Collecting unreachable Nix store paths...")
    check rec.calls.len == 1
    check rec.calls[0].cmd == "nix"
    check rec.calls[0].args == @["store", "gc"]
