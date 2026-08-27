import std/[unittest, os, strutils]
import "../EnterNixShell"

suite "Enter-NixShell buildInstallables":
  test "bare package name gets nixpkgs# prefixed":
    check buildInstallables(@["jq"]) == @["nixpkgs#jq"]

  test "arg containing # passes through unchanged":
    check buildInstallables(@["github:foo/bar#baz"]) == @["github:foo/bar#baz"]

  test "mix of bare names and flake refs":
    check buildInstallables(@["jq", "github:foo/bar#baz", "ripgrep"]) ==
      @["nixpkgs#jq", "github:foo/bar#baz", "nixpkgs#ripgrep"]

suite "Enter-NixShell buildShellName":
  test "uses original args, space-joined, not the nixpkgs#-prefixed installables":
    check buildShellName(@["jq", "github:foo/bar#baz"]) == "jq github:foo/bar#baz"

  test "single package":
    check buildShellName(@["jq"]) == "jq"

suite "Enter-NixShell run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_enter_nix_shell_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Enter-NixShell")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_enter_nix_shell_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Enter-NixShell")

  test "unknown option errors and exits 1":
    let tmp = getTempDir() / "test_enter_nix_shell_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Unknown option: --bogus")

  test "no packages given emits both error and info, exits 1":
    let tmp = getTempDir() / "test_enter_nix_shell_no_packages.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Usage: Enter-NixShell packages...")
    check content.contains("Use --help for more information")

  # The live `nix shell` invocation (env-augmented startProcess with
  # poParentStreams, an interactive nested shell) is not exercised here: it
  # would spawn a real interactive shell and hang waiting on user input, is
  # network-dependent, and inherits the caller's real stdio which can't be
  # meaningfully captured in a unit test. Covered by manual/production use
  # only, consistent with this backlog's accepted gap for un-mockable
  # interactive subprocess passthrough.
