import std/[unittest, os, strutils]
import "../NewDotNetDevEnvironment"
import "../../lib/testing"

suite "New-DotNetDevEnvironment isValidDotNetTarget":
  test "8, 9, and 10 are valid":
    check isValidDotNetTarget("8") == true
    check isValidDotNetTarget("9") == true
    check isValidDotNetTarget("10") == true
  test "anything else is invalid":
    check isValidDotNetTarget("7") == false
    check isValidDotNetTarget("9.0") == false
    check isValidDotNetTarget("") == false

suite "New-DotNetDevEnvironment parseArgs":
  test "a trailing --target with no value sets missingFlagValue, not a hang":
    let p = parseArgs(@["--target"])
    check p.missingFlagValue == "--target"

suite "New-DotNetDevEnvironment run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_new_dotnet_dev_environment_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: New-DotNetDevEnvironment")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_new_dotnet_dev_environment_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: New-DotNetDevEnvironment")

  test "an unsupported --target is an error":
    let dir = getTempDir() / "test_new_dotnet_invalid_target"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--target", "7"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Unknown target: 7 (supported: 8, 9, 10)")

  test "missing deps is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_new_dotnet_dev_environment"
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

  test "contract: no --target defaults to all three SDKs, plus the DOTNET env-attrs block":
    let dir = getTempDir() / "test_new_dotnet_default"
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = getTempDir() / "test_new_dotnet_default_out.txt"
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
    check flakeContent.contains("            pkgs.dotnet-sdk_8")
    check flakeContent.contains("            pkgs.dotnet-sdk_9")
    check flakeContent.contains("            pkgs.dotnet-sdk_10")
    check flakeContent.contains("DOTNET_CLI_TELEMETRY_OPTOUT = \"1\";")
    check flakeContent.contains("DOTNET_NOLOGO = \"1\";")

  test "contract: --target 9 becomes only pkgs.dotnet-sdk_9":
    let dir = getTempDir() / "test_new_dotnet_target"
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = getTempDir() / "test_new_dotnet_target_out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--name", "app", "--target", "9"], f, f)
    f.close()
    setCurrentDir(savedDir)
    let flakeContent = readFile(dir / "flake.nix")
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check flakeContent.contains("            pkgs.dotnet-sdk_9")
    check not flakeContent.contains("dotnet-sdk_8")
    check not flakeContent.contains("dotnet-sdk_10")
