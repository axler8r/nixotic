import std/[unittest, os, strutils]
import "../shell"
import "../../../lib/testing"

suite "ax dev shell buildInstallables":
  test "bare package name gets nixpkgs# prefixed":
    check buildInstallables(@["jq"]) == @["nixpkgs#jq"]

  test "arg containing # passes through unchanged":
    check buildInstallables(@["github:foo/bar#baz"]) == @["github:foo/bar#baz"]

  test "mix of bare names and flake refs":
    check buildInstallables(@["jq", "github:foo/bar#baz", "ripgrep"]) ==
      @["nixpkgs#jq", "github:foo/bar#baz", "nixpkgs#ripgrep"]

suite "ax dev shell buildShellName":
  test "uses original args, space-joined, not the nixpkgs#-prefixed installables":
    check buildShellName(@["jq", "github:foo/bar#baz"]) == "jq github:foo/bar#baz"

  test "single package":
    check buildShellName(@["jq"]) == "jq"

suite "ax dev shell run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_enter_nix_shell_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax dev shell")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_enter_nix_shell_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax dev shell")

  test "unknown option errors and exits 64":
    let tmp = getTempDir() / "test_enter_nix_shell_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Unknown option: --bogus")

  test "no packages given emits both error and info, exits 64":
    let tmp = getTempDir() / "test_enter_nix_shell_no_packages.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Missing required argument: packages")

  test "characterization: installables argv and IN_NIX_SHELL/name environment":
    let dir = getTempDir() / "char_enter_nix_shell"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "nix", "echo \"$@\" >> " & log.quoteShell &
                             "\necho \"IN_NIX_SHELL=$IN_NIX_SHELL\" >> " & log.quoteShell &
                             "\necho \"name=$name\" >> " & log.quoteShell)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["jq", "ripgrep"], f, f)
    f.close()
    let content = readFile(log)
    let lines = content.strip().splitLines()
    removeDir(dir)
    check code == 0
    # Exact-line equality on the argv line pins the full invocation --
    # `contains` would miss flags appended after the installables list.
    check lines[0] == "shell nixpkgs#jq nixpkgs#ripgrep"
    check content.contains("IN_NIX_SHELL=impure")
    check content.contains("name=" & buildShellName(@["jq", "ripgrep"]))

  test "contract: nix shell is called with nixpkgs#-prefixed installables":
    let rec = newRecordingRunner(exitCode = 0)
    let tmp = getTempDir() / "contract_enter_nix_shell.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["jq", "ripgrep"], f, f, rec.runner)
    f.close()
    removeFile(tmp)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "nix"
    check rec.calls[0].args == @["shell", "nixpkgs#jq", "nixpkgs#ripgrep"]
