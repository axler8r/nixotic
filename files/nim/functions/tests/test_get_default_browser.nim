import std/[unittest, os, strutils]
import "../GetDefaultBrowser"
import "../../lib/testing"

suite "Get-DefaultBrowser run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_default_browser_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-DefaultBrowser")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_get_default_browser_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-DefaultBrowser")

  test "unknown option is an error":
    let tmp = getTempDir() / "test_get_default_browser_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Unknown option: --bogus")

  test "a stray positional arg is silently ignored, not treated as an unknown option":
    # Unlike Get-Help, this function's flag loop never `break`s on the
    # first non-flag arg -- "foo" here must not trip the unknown-option
    # path (exit 1). `xdg-utils` is now a nativeBuildInput/devShell package
    # (flake.nix), so `checkDeps(["xdg-mime"])` is guaranteed to succeed
    # here, and `run()` never inspects the queried process's own exit code
    # -- it only captures stdout -- so this deterministically reaches the
    # final `return 0`, independent of whatever desktop-file config (or
    # lack thereof) `xdg-mime` finds. Verified directly: `xdg-mime query
    # default x-scheme-handler/http` exits 0 with empty output even under
    # a fully clean HOME/XDG_DATA_DIRS with no mimeapps.list at all.
    let tmp = getTempDir() / "test_get_default_browser_stray.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["foo"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check not content.contains("Unknown option")

  # The live xdg-mime query path's actual handler *values* are still not
  # asserted on: those depend on a live desktop session / mimeapps.list
  # configuration this sandbox doesn't reliably provide, consistent with
  # the conventions doc's accepted gaps for un-mockable subprocess
  # passthrough. Only the exit code and absence of an "Unknown option"
  # message are pinned above.

  test "characterization: queries http then https scheme handlers":
    let dir = getTempDir() / "char_get_default_browser"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "xdg-mime", fakeRecorder(log))
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw"], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check calls == @[
      "query default x-scheme-handler/http",
      "query default x-scheme-handler/https"
    ]
