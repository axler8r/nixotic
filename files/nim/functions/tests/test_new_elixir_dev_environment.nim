import std/[unittest, os, strutils]
import "../NewElixirDevEnvironment"
import "../../lib/testing"

suite "New-ElixirDevEnvironment isValidElixirTarget":
  test "1.17 is valid":
    check isValidElixirTarget("1.17") == true
  test "a bare major version with no dot is invalid":
    check isValidElixirTarget("1") == false
  test "a non-numeric component is invalid":
    check isValidElixirTarget("1.x") == false

suite "New-ElixirDevEnvironment parseArgs":
  test "a trailing --target with no value sets missingFlagValue, not a hang":
    let p = parseArgs(@["--target"])
    check p.missingFlagValue == "--target"

suite "New-ElixirDevEnvironment run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_new_elixir_dev_environment_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: New-ElixirDevEnvironment")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_new_elixir_dev_environment_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: New-ElixirDevEnvironment")

  test "an invalid --target is an error":
    let dir = getTempDir() / "test_new_elixir_invalid_target"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--target", "notaversion"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Invalid target: notaversion (expected format: 1.17)")

  test "missing deps is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_new_elixir_dev_environment"
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
    check content.contains("Missing commands:")

  test "contract: no --target defaults to pkgs.beamPackages.elixir":
    let dir = getTempDir() / "test_new_elixir_default"
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = getTempDir() / "test_new_elixir_default_out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--name", "app"], f, f)
    f.close()
    setCurrentDir(savedDir)
    let flakeContent = readFile(dir / "flake.nix")
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check flakeContent.contains("            pkgs.beamPackages.elixir")

  test "contract: --target 1.17 becomes pkgs.beamPackages.elixir_1_17, extras stay plain pkgs.":
    let dir = getTempDir() / "test_new_elixir_target"
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = getTempDir() / "test_new_elixir_target_out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--name", "app", "--target", "1.17", "jq"], f, f)
    f.close()
    setCurrentDir(savedDir)
    let flakeContent = readFile(dir / "flake.nix")
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check flakeContent.contains("            pkgs.beamPackages.elixir_1_17")
    check flakeContent.contains("            pkgs.jq")
    check not flakeContent.contains("pkgs.beamPackages.jq")
