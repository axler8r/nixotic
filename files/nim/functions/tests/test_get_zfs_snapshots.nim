import std/[unittest, os, strutils]
import "../GetZfsSnapshots"
import "../../lib/testing"

suite "Get-ZfsSnapshots parseArgs":
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

  test "last-non-flag-arg-wins when multiple dataset-like args are given":
    # Matches the zsh original's while/case loop, which never breaks on the
    # first non-flag arg -- it keeps consuming every remaining token, and
    # each non-flag token overwrites `_dataset`. So the LAST one wins.
    let p = parseArgs(@["foo", "bar"])
    check p.dataset == "bar"
    check p.unknownOption == ""

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

suite "Get-ZfsSnapshots run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_zfs_snapshots_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-ZfsSnapshots")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_get_zfs_snapshots_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-ZfsSnapshots")

  test "unknown option is an error, exit 1, before checkDeps(zfs) is ever reached":
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
    check code == 1
    check content.contains("Unknown option: --bogus")

  # checkDeps(["zfs"]) itself is NOT asserted on either way here: zfs is
  # present on $PATH in this interactive/devShell sandbox (it's a host
  # system package on this NixOS machine), so a "checkDeps returns 2"
  # assertion would be false in that environment; it is also not declared
  # as a nativeBuildInput/devShell package for this migration (zfs isn't a
  # realistic pure-sandbox build input -- see the migration report), so a
  # "checkDeps returns true" assertion would be false in the pure
  # `nix flake check` sandbox. Asserting either direction would make this
  # test environment-dependent and flaky. No test in this file reaches past
  # the checkDeps(["zfs"]) call in run().
  #
  # The live `zfs list` invocation (base args, conditional -H for --raw or
  # non-TTY stdout, optional trailing dataset positional, live passthrough
  # via poParentStreams, and propagating zfs's own exit code) is not
  # exercised here either: it requires a real ZFS pool, which this sandbox
  # does not have. Covered by manual/production use only, consistent with
  # the conventions doc's accepted gaps for un-mockable subprocess
  # passthrough.

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
