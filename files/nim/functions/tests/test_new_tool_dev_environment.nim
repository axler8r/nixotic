import std/[unittest, os, strutils]
import "../NewToolDevEnvironment"
import "../../lib/testing"

suite "New-ToolDevEnvironment parseArgs":
  test "default name is the current directory's basename":
    let dir = getTempDir() / "test_new_tool_parseargs_cwd"
    removeDir(dir)
    createDir(dir / "myproj")
    let savedDir = getCurrentDir()
    setCurrentDir(dir / "myproj")
    let p = parseArgs(@[])
    setCurrentDir(savedDir)
    removeDir(dir)
    check p.name == "myproj"
    check p.packages == newSeq[string]()

  test "--name overrides the default":
    let p = parseArgs(@["--name", "custom", "jq"])
    check p.name == "custom"
    check p.packages == @["jq"]

  test "bare positionals accumulate as packages":
    let p = parseArgs(@["jq", "ripgrep", "fd"])
    check p.packages == @["jq", "ripgrep", "fd"]

  test "an unknown option stops parsing immediately":
    let p = parseArgs(@["jq", "--bogus", "fd"])
    check p.unknownOption == "--bogus"
    check p.packages == @["jq"]

  test "a trailing --name with no value sets missingFlagValue, not a hang":
    let p = parseArgs(@["jq", "--name"])
    check p.missingFlagValue == "--name"

suite "New-ToolDevEnvironment run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_new_tool_dev_environment_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: New-ToolDevEnvironment")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_new_tool_dev_environment_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: New-ToolDevEnvironment")

  test "an unknown option is an error, exit 1, before checkDeps is reached":
    let dir = getTempDir() / "test_new_tool_unknown_opt"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir): # empty $PATH: if checkDeps ran, this would be exit 2
      code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Unknown option: --bogus")

  test "a trailing --name with no value is exit 1, not a hang":
    let tmp = getTempDir() / "test_new_tool_missing_name_value.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["jq", "--name"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Missing value for --name")

  test "missing deps is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_new_tool_dev_environment"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["jq"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands:")

  test "no packages given is an error, checkDeps already passed":
    let dir = getTempDir() / "test_new_tool_no_packages"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Usage: New-ToolDevEnvironment")
    check content.contains("Use --help for more information")

  test "contract: full success writes flake.nix with pkgs.-prefixed packages and the given name":
    let dir = getTempDir() / "test_new_tool_success"
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = getTempDir() / "test_new_tool_success_out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--name", "toolbox", "jq", "ripgrep"], f, f)
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    let flakeContent = readFile(dir / "flake.nix")
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check content.contains("Environment activated")
    check flakeContent.contains("description = \"toolbox development environment\";")
    check flakeContent.contains("name = \"toolbox\";")
    check flakeContent.contains("            pkgs.jq")
    check flakeContent.contains("            pkgs.ripgrep")
