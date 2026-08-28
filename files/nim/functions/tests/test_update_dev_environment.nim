import std/[unittest, os, strutils]
import "../UpdateDevEnvironment"
import "../../lib/testing"

suite "Update-DevEnvironment run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_update_dev_environment_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Update-DevEnvironment")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_update_dev_environment_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Update-DevEnvironment")

  test "no flake.nix in current directory is an error":
    # Real, deterministic logic that doesn't require nix/direnv to actually
    # run: point the current directory at an empty temp dir (no flake.nix)
    # and confirm the checkDeps-passed, flake.nix-missing branch fires. The
    # checkDeps-failed branch itself is covered separately below via
    # withPath, the same mechanism five sibling test files use for it.
    let savedDir = getCurrentDir()
    let tmpDir = getTempDir() / "test_update_dev_environment_no_flake"
    removeDir(tmpDir)
    createDir(tmpDir)
    setCurrentDir(tmpDir)

    let tmp = getTempDir() / "test_update_dev_environment_no_flake_out.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()

    setCurrentDir(savedDir)
    let content = readFile(tmp)
    removeFile(tmp)
    removeDir(tmpDir)

    check code == 1
    check content.contains("No flake.nix found in current directory")

  test "missing direnv/nix is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_update_dev_environment"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands: ")

  test "characterization: nix flake update then direnv reload, one call each":
    let dir = getTempDir() / "char_update_dev_environment"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "flake.nix", "")
    let nixLog = dir / "nix_calls.log"
    let direnvLog = dir / "direnv_calls.log"
    let sharedLog = dir / "shared_calls.log"
    # Per-command logs disambiguate which command received which args; the
    # shared log (each line prefixed with the command name) additionally
    # pins the ORDER between the two commands.
    writeFakeExe(dir, "nix", fakeRecorder(nixLog) &
      "\necho \"nix $@\" >> " & sharedLog.quoteShell)
    writeFakeExe(dir, "direnv", fakeRecorder(direnvLog) &
      "\necho \"direnv $@\" >> " & sharedLog.quoteShell)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    var code: int
    withPath(dir):
      code = run(@[], f, f)
    setCurrentDir(savedDir)
    f.close()
    let nixCalls = readFile(nixLog).strip().splitLines()
    let direnvCalls = readFile(direnvLog).strip().splitLines()
    let sharedCalls = readFile(sharedLog).strip().splitLines()
    removeDir(dir)
    check code == 0
    check nixCalls == @["flake update"]
    check direnvCalls == @["reload"]
    check sharedCalls == @["nix flake update", "direnv reload"]

  test "contract: a successful flake update is followed by direnv reload":
    let dir = getTempDir() / "contract_update_dev_environment"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "flake.nix", "")
    let rec = newRecordingRunner(exitCode = 0)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    var code: int
    code = run(@[], f, f, rec.runner)
    setCurrentDir(savedDir)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 2
    check rec.calls[0].cmd == "nix"
    check rec.calls[0].args == @["flake", "update"]
    check rec.calls[1].cmd == "direnv"
    check rec.calls[1].args == @["reload"]

  test "contract: a failed flake update does not run direnv reload":
    let dir = getTempDir() / "contract_update_dev_environment_fail"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "flake.nix", "")
    let rec = newRecordingRunner(exitCode = 1)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    var code: int
    code = run(@[], f, f, rec.runner)
    setCurrentDir(savedDir)
    f.close()
    removeDir(dir)
    check code == 1
    check rec.calls.len == 1
    check rec.calls[0].cmd == "nix"
