import std/[unittest, os, strutils]
import "../GetDefaultBrowser"

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
    # path (exit 1). What happens after is either a successful query
    # (exit 0) or a checkDeps failure (exit 2) depending on whether
    # xdg-mime is on $PATH in this sandbox -- both are acceptable outcomes
    # here; only exit 1 / an "Unknown option" message would indicate a bug.
    let tmp = getTempDir() / "test_get_default_browser_stray.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["foo"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code != 1
    check not content.contains("Unknown option")

  # The live xdg-mime query path (checkDeps success, actual handler values)
  # is not asserted on here: it depends on a live desktop session /
  # mimeapps.list configuration that this sandbox doesn't reliably provide,
  # consistent with the conventions doc's accepted gaps for un-mockable
  # subprocess passthrough. Whether checkDeps itself can be forced to fail
  # (asserting exit 2) depends on whether xdg-mime is genuinely absent from
  # $PATH in a given run -- it is present via /run/current-system/sw/bin in
  # this interactive sandbox, so that specific assertion is intentionally
  # left out rather than pinned to an environment-dependent outcome.
