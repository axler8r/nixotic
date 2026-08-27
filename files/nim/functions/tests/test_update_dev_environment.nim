import std/[unittest, os, strutils]
import "../UpdateDevEnvironment"

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
    # and confirm the checkDeps-passed, flake.nix-missing branch fires.
    # `direnv`/`nix` are both genuinely present in this sandbox's $PATH, so
    # the checkDeps failure path (return 2) isn't constructible here without
    # artificially hiding a real binary -- that branch is left untested per
    # the task brief's guidance to only cover it if one of the deps is
    # genuinely absent.
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

  # The live `nix flake update` / `direnv reload` calls are not exercised
  # here: no guarantee of a real flake project or a mutable,
  # network-reachable environment in a test sandbox. That path is covered
  # by manual/production use only, consistent with the conventions doc's
  # accepted gaps for un-mockable subprocess passthrough.
