import std/[unittest, os, strutils]
import "../create"
import "../../../lib/testing"

suite "ax dev create validators":
  test "python: 3.12 and 3.9 are valid":
    check isValidPythonTarget("3.12") == true
    check isValidPythonTarget("3.9") == true
  test "python: 2.7, 3.x, and a bare 3 are invalid":
    check isValidPythonTarget("2.7") == false
    check isValidPythonTarget("3.x") == false
    check isValidPythonTarget("3") == false
  test "dotnet: only 8, 9 and 10 are valid":
    check isValidDotNetTarget("8") == true
    check isValidDotNetTarget("9") == true
    check isValidDotNetTarget("10") == true
    check isValidDotNetTarget("7") == false
    check isValidDotNetTarget("9.0") == false
  test "elixir: 1.17 is valid, 1.x and bare 1 are not":
    check isValidElixirTarget("1.17") == true
    check isValidElixirTarget("1.x") == false
    check isValidElixirTarget("1") == false

suite "ax dev create parseArgs":
  test "first positional is the template, later ones are packages":
    let p = parseArgs(@["python", "jq", "ripgrep"])
    check p.templateName == "python"
    check p.packages == @["jq", "ripgrep"]

  test "--target and --name both parse around the template":
    let p = parseArgs(@["--target", "3.12", "python", "--name", "myapp", "jq"])
    check p.templateName == "python"
    check p.target == "3.12"
    check p.name == "myapp"
    check p.packages == @["jq"]

  test "a trailing --target with no value sets missingFlagValue, not a hang":
    let p = parseArgs(@["python", "--target"])
    check p.missingFlagValue == "--target"

  test "an unknown option is recorded":
    let p = parseArgs(@["python", "-x"])
    check p.unknownOption == "-x"

suite "ax dev create run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_dev_create_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax dev create")

  test "missing template is a usage error":
    let tmp = getTempDir() / "test_dev_create_no_template.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Missing template")

  test "an unknown template is a usage error":
    let tmp = getTempDir() / "test_dev_create_bad_template.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["fortran"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Unknown template: fortran")

  test "missing deps is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_dev_create"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["python"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands:")

  test "an invalid python --target is a usage error":
    let dir = getTempDir() / "test_dev_create_invalid_python_target"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["python", "--target", "notaversion"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 64
    check content.contains("Invalid target: notaversion (expected format: 3.12)")

  test "the tool template rejects --target and requires packages":
    let dir = getTempDir() / "test_dev_create_tool_usage"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var codeTarget, codeEmpty: int
    withPath(dir):
      codeTarget = run(@["tool", "--target", "1.0", "jq"], f, f)
      codeEmpty = run(@["tool"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check codeTarget == 64
    check content.contains("--target is not supported for the tool template")
    check codeEmpty == 64
    check content.contains("Usage: ax dev create tool")

  proc scaffoldWith(caseName: string, args: seq[string]): tuple[code: int, flake: string] =
    ## Runs `ax dev create` inside a fresh fixture directory and hands back
    ## the exit code plus the flake.nix it wrote ("" when none appeared).
    let dir = getTempDir() / caseName
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    writeFakeExe(dir, "nix", "exit 0")
    let outPath = getTempDir() / (caseName & "_out.txt")
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(args, f, f)
    f.close()
    setCurrentDir(savedDir)
    let flake =
      if fileExists(dir / "flake.nix"): readFile(dir / "flake.nix") else: ""
    removeFile(outPath)
    removeDir(dir)
    (code, flake)

  test "contract: python with no --target defaults to python3 + uv":
    let r = scaffoldWith("dev_create_python_default", @["python", "--name", "app"])
    check r.code == 0
    check r.flake.contains("            pkgs.python3")
    check r.flake.contains("            pkgs.uv")

  test "contract: python --target 3.12 becomes pkgs.python312 + uv, plus extras":
    let r = scaffoldWith("dev_create_python_target",
                         @["python", "--name", "app", "--target", "3.12", "jq"])
    check r.code == 0
    check r.flake.contains("            pkgs.python312")
    check r.flake.contains("            pkgs.uv")
    check r.flake.contains("            pkgs.jq")

  test "contract: dotnet with no --target ships all three SDKs and the telemetry env attrs":
    let r = scaffoldWith("dev_create_dotnet_default", @["dotnet", "--name", "app"])
    check r.code == 0
    check r.flake.contains("            pkgs.dotnet-sdk_8")
    check r.flake.contains("            pkgs.dotnet-sdk_9")
    check r.flake.contains("            pkgs.dotnet-sdk_10")
    check r.flake.contains("DOTNET_CLI_TELEMETRY_OPTOUT")
    check r.flake.contains("DOTNET_NOLOGO")

  test "contract: dotnet --target 9 ships only that SDK":
    let r = scaffoldWith("dev_create_dotnet_target",
                         @["dotnet", "--name", "app", "--target", "9"])
    check r.code == 0
    check r.flake.contains("            pkgs.dotnet-sdk_9")
    check not r.flake.contains("            pkgs.dotnet-sdk_8")

  test "contract: elixir --target 1.17 uses the beamPackages prefix, extras use pkgs.":
    let r = scaffoldWith("dev_create_elixir_target",
                         @["elixir", "--name", "app", "--target", "1.17", "jq"])
    check r.code == 0
    check r.flake.contains("            pkgs.beamPackages.elixir_1_17")
    check r.flake.contains("            pkgs.jq")

  test "contract: tool scaffolds exactly the given packages":
    let r = scaffoldWith("dev_create_tool", @["tool", "--name", "box", "jq", "fd"])
    check r.code == 0
    check r.flake.contains("            pkgs.jq")
    check r.flake.contains("            pkgs.fd")
    check r.flake.contains("name = \"box\";")
