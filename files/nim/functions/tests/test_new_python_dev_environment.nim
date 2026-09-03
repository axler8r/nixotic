import std/[unittest, os, strutils]
import "../NewPythonDevEnvironment"
import "../../lib/testing"

suite "New-PythonDevEnvironment isValidPythonTarget":
  test "3.12 is valid":
    check isValidPythonTarget("3.12") == true
  test "3.9 is valid":
    check isValidPythonTarget("3.9") == true
  test "2.7 is invalid (only Python 3 is supported)":
    check isValidPythonTarget("2.7") == false
  test "a non-numeric minor version is invalid":
    check isValidPythonTarget("3.x") == false
  test "a bare major version with no dot is invalid":
    check isValidPythonTarget("3") == false

suite "New-PythonDevEnvironment parseArgs":
  test "--target and --name both parse, extra positionals become packages":
    let p = parseArgs(@["--target", "3.12", "--name", "myapp", "jq"])
    check p.target == "3.12"
    check p.name == "myapp"
    check p.packages == @["jq"]

  test "a trailing --target with no value sets missingFlagValue, not a hang":
    let p = parseArgs(@["--target"])
    check p.missingFlagValue == "--target"

suite "New-PythonDevEnvironment run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_new_python_dev_environment_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: New-PythonDevEnvironment")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_new_python_dev_environment_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: New-PythonDevEnvironment")

  test "an invalid --target is an error":
    let dir = getTempDir() / "test_new_python_invalid_target"
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
    check content.contains("Invalid target: notaversion (expected format: 3.12)")

  test "missing deps is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_new_python_dev_environment"
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

  test "contract: no --target defaults to python3 + uv":
    let dir = getTempDir() / "test_new_python_default"
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = getTempDir() / "test_new_python_default_out.txt"
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
    check flakeContent.contains("            pkgs.python3")
    check flakeContent.contains("            pkgs.uv")

  test "contract: --target 3.12 becomes pkgs.python312 + uv, plus any extra packages":
    let dir = getTempDir() / "test_new_python_target"
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = getTempDir() / "test_new_python_target_out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--name", "app", "--target", "3.12", "jq"], f, f)
    f.close()
    setCurrentDir(savedDir)
    let flakeContent = readFile(dir / "flake.nix")
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check flakeContent.contains("            pkgs.python312")
    check flakeContent.contains("            pkgs.uv")
    check flakeContent.contains("            pkgs.jq")
