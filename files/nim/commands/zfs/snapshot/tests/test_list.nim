import std/[unittest, os, strutils]
import "../list"
import "../../../../lib/testing"

suite "ax zfs snapshot list parseArgs":
  test "no args: raw false, dataset empty, no unknown option":
    let p = parseArgs(@[])
    check p.raw == false
    check p.dataset == ""
    check p.unknownOption == ""

  test "--raw sets the raw flag":
    let p = parseArgs(@["--raw"])
    check p.raw == true
    check p.dataset == ""
    check p.unknownOption == ""

  test "a single non-flag arg becomes the dataset":
    let p = parseArgs(@["dpool/data"])
    check p.dataset == "dpool/data"
    check p.unknownOption == ""

  test "multiple datasets are rejected instead of overwriting the first":
    let p = parseArgs(@["foo", "bar"])
    check p.dataset == "foo"
    check p.unknownOption.len > 0
    let rec = newRecordingRunner()
    check run(@["foo", "bar"], runner = rec.runner) == 64
    check rec.calls.len == 0

  test "--raw combined with a dataset arg, in either order":
    let p1 = parseArgs(@["--raw", "dpool/data"])
    check p1.raw == true
    check p1.dataset == "dpool/data"
    let p2 = parseArgs(@["dpool/data", "--raw"])
    check p2.raw == true
    check p2.dataset == "dpool/data"

  test "an unknown option is captured and stops further parsing":
    # Mirrors the zsh original's `return 1` from inside the loop: anything
    # after the unknown option is never consumed. Here, "later" would have
    # become the dataset if parsing had continued past "--bogus" -- it
    # must not.
    let p = parseArgs(@["--bogus", "later"])
    check p.unknownOption == "--bogus"
    check p.dataset == ""

  test "unknown option encountered after a dataset arg still overrides it":
    let p = parseArgs(@["dpool/data", "--bogus"])
    check p.unknownOption == "--bogus"
    check p.dataset == "dpool/data"

suite "ax zfs snapshot list run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_zfs_snapshots_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax zfs snapshot list")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_get_zfs_snapshots_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax zfs snapshot list")

  test "unknown option is an error, exit 64, before checkDeps(zfs) is ever reached":
    # run() checks parsed.unknownOption and returns 1 before calling
    # checkDeps(["zfs"]), so this test's outcome does not depend on whether
    # zfs is on $PATH -- deliberately, per the migration backlog's standing
    # rule against tests that need checkDeps(["zfs"]) to succeed.
    let tmp = getTempDir() / "test_get_zfs_snapshots_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Unknown option: --bogus")

  test "missing zfs is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_get_zfs_snapshots"
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
    check content.contains("Missing commands: zfs")

  test "characterization: zfs list flags and dataset filter":
    let dir = getTempDir() / "char_get_zfs_snapshots"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "zfs", fakeRecorder(log))
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["dpool/data"], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check calls == @[
      "list -r -t snapshot -S creation -o name,used,referenced,creation -H dpool/data"
    ]

  test "contract: zfs list receives the sort/format flags, no dataset":
    # `zfs` is not a nativeBuildInput of the test sandbox (flake.nix), so
    # checkDeps(["zfs"]) needs a stand-in on $PATH to succeed; its actual
    # invocation is intercepted by rec.runner, so the stub's content is
    # never run.
    let dir = getTempDir() / "contract_get_zfs_snapshots"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "zfs", "")
    let rec = newRecordingRunner(exitCode = 0)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "zfs"
    check rec.calls[0].args == @["list", "-r", "-t", "snapshot", "-S",
                                  "creation", "-o",
                                  "name,used,referenced,creation", "-H"]

  test "contract: zfs list appends the dataset positional when given":
    let dir = getTempDir() / "contract_get_zfs_snapshots_dataset"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "zfs", "")
    let rec = newRecordingRunner(exitCode = 0)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["dpool/data"], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].args == @["list", "-r", "-t", "snapshot", "-S",
                                  "creation", "-o",
                                  "name,used,referenced,creation", "-H",
                                  "dpool/data"]
