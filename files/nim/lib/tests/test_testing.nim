import std/[unittest, os, osproc, strutils]
import "../testing"

suite "testing helpers":
  test "writeFakeExe creates an executable that records its arguments":
    let dir = getTempDir() / "test_testing_fake"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "faketool", fakeRecorder(log))
    let code = execCmd(dir / "faketool" & " alpha beta")
    check code == 0
    check readFile(log).strip() == "alpha beta"
    removeDir(dir)

  test "withPath swaps PATH for the body and restores it after":
    let dir = getTempDir() / "test_testing_path"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "onlyhere", "exit 0")
    let before = getEnv("PATH")
    withPath(dir):
      check findExe("onlyhere").len > 0
    check getEnv("PATH") == before
    check findExe("onlyhere").len == 0
    removeDir(dir)

  test "withPath restores PATH even when the body raises":
    let dir = getTempDir() / "test_testing_path_raise"
    removeDir(dir)
    createDir(dir)
    let before = getEnv("PATH")
    expect ValueError:
      withPath(dir):
        raise newException(ValueError, "boom")
    check getEnv("PATH") == before
    removeDir(dir)

  test "a fake's body can call a real external utility while PATH is replaced":
    # Regression test for the brief's defect: withPath replaces $PATH
    # entirely with the fixture dir, so a fake whose body calls a real
    # utility (cat) must have the pristine $PATH baked in by writeFakeExe,
    # or that utility becomes unresolvable and the fake fails to run.
    let dir = getTempDir() / "test_testing_pristine_path"
    removeDir(dir)
    createDir(dir)
    let dataFile = dir / "data.txt"
    writeFile(dataFile, "hello from a real utility\n")
    writeFakeExe(dir, "catwrapper", "cat " & dataFile.quoteShell)
    withPath(dir):
      # Inside this block, $PATH is only `dir` — cat is not on it. If the
      # fake's baked-in PATH were missing, the shell could not find `cat`
      # and execProcess would fail or return empty output.
      let (output, code) = execCmdEx(dir / "catwrapper")
      check code == 0
      check output.strip() == "hello from a real utility"
    removeDir(dir)
