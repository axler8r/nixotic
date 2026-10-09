import std/[unittest, os, osproc, strtabs, strutils]
import "../process"
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

suite "recording runner":
  test "records inherited calls and returns the canned exit code":
    let rec = newRecordingRunner(exitCode = 5)
    let code = rec.runner.runInherited("docker", @["pull", "alpine"])
    check code == 5
    check rec.calls.len == 1
    check rec.calls[0].kind == "inherited"
    check rec.calls[0].cmd == "docker"
    check rec.calls[0].args == @["pull", "alpine"]

  test "records capture calls including stdin and returns canned output":
    let rec = newRecordingRunner(output = "canned", error = "warned")
    let r = rec.runner.capture("bat", @["--plain"], "piped in")
    check r.output == "canned"
    check r.error == "warned"
    check rec.calls[0].kind == "capture"
    check rec.calls[0].input == "piped in"

  test "accumulates calls in invocation order":
    let rec = newRecordingRunner()
    discard rec.runner.runInherited("a", @["1"])
    discard rec.runner.capture("b", @["2"])
    check rec.calls.len == 2
    check rec.calls[0].cmd == "a"
    check rec.calls[1].cmd == "b"

  test "queued replies are consumed in order across every runner shape":
    let rec = newRecordingRunner(exitCode = 9, output = "fallback", error = "default",
      replies = @[
        CommandResult(exitCode: 1, output: "first", error: "first error"),
        CommandResult(exitCode: 2), CommandResult(exitCode: 3)])
    let first = rec.runner.capture("a", @[])
    check first.exitCode == 1
    check first.output == "first"
    check first.error == "first error"
    check rec.runner.runInherited("b", @[]) == 2
    check rec.runner.runQuiet("c", @[]) == 3
    let fallback = rec.runner.capture("d", @[])
    check fallback.exitCode == 9
    check fallback.output == "fallback"
    check fallback.error == "default"
    check rec.replies.len == 0
    check rec.calls.len == 4
    check rec.calls[2].kind == "capture"

  test "queues can be refilled and defaults remain mutable":
    let rec = newRecordingRunner()
    check rec.runner.runInherited("a", @[]) == 0
    rec.replies.add CommandResult(exitCode: 4, output: "queued")
    check rec.runner.capture("b", @[]).output == "queued"
    rec.exitCode = 7
    rec.output = "changed"
    check rec.runner.capture("c", @[]).output == "changed"
    check rec.runner.runInherited("d", @[]) == 7

  test "explicit environment replaces inherited values and is snapshotted":
    let env = newStringTable({"AX_RECORDING_TEST": "original"}, modeCaseSensitive)
    let rec = newRecordingRunner()
    discard rec.runner.runInherited("tool", @[], env)
    env["AX_RECORDING_TEST"] = "changed"
    check rec.calls[0].env["AX_RECORDING_TEST"] == "original"
    check rec.calls[0].env.len == 1
    discard rec.runner.runInherited("tool", @[], newStringTable(modeCaseSensitive))
    check rec.calls[1].env.len == 0

  test "default inherited and captured environments are snapshots at call time":
    let existed = existsEnv("AX_RECORDING_TEST")
    let before = getEnv("AX_RECORDING_TEST")
    try:
      let rec = newRecordingRunner()
      putEnv("AX_RECORDING_TEST", "inherited")
      discard rec.runner.runInherited("tool", @[])
      putEnv("AX_RECORDING_TEST", "captured")
      discard rec.runner.capture("tool", @[])
      delEnv("AX_RECORDING_TEST")
      check rec.calls[0].env["AX_RECORDING_TEST"] == "inherited"
      check rec.calls[1].env["AX_RECORDING_TEST"] == "captured"
    finally:
      if existed: putEnv("AX_RECORDING_TEST", before)
      else: delEnv("AX_RECORDING_TEST")
