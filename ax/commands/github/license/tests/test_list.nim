import std/[unittest, os, strutils]
import "../list"
import "../../../../lib/testing"

suite "ax github license list parseArgs":
  test "no args: raw is false":
    check parseArgs(@[]).raw == false

  test "--raw sets the raw flag":
    check parseArgs(@["--raw"]).raw == true

  test "an unrecognized argument is reported":
    check parseArgs(@["--bogus"]).unknownOption == "--bogus"

  test "--raw does not make unexpected arguments valid":
    let rec = newRecordingRunner()
    check run(@["--raw", "--bogus"], runner = rec.runner) == 64
    check run(@["--bogus", "--raw"], runner = rec.runner) == 64
    check rec.calls.len == 0

suite "ax github license list run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_github_licenses_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax github license list")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_get_github_licenses_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax github license list")

  test "missing curl and jq is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_get_github_licenses"
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
    check content.contains("Missing commands: curl jq")

  test "contract: curl fetches the licenses endpoint, jq reformats it, table renders it":
    let dir = getTempDir() / "contract_get_github_licenses"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "curl", "")
    writeFakeExe(dir, "jq", "")
    writeFakeExe(dir, "column", "")
    let rec = newRecordingRunner(exitCode = 0,
      output = "mit|MIT License\napache-2.0|Apache License 2.0\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw"], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 3
    check rec.calls[0].cmd == "curl"
    check rec.calls[0].args == @["-fsS", "https://api.github.com/licenses"]
    check rec.calls[1].cmd == "jq"
    check rec.calls[1].args == @["-r", ".[] | \"\\(.key)|\\(.name)\""]
    check rec.calls[1].input == "mit|MIT License\napache-2.0|Apache License 2.0\n"
    check rec.calls[2].cmd == "column"
    check rec.calls[2].input == "Key|Name\nmit|MIT License\napache-2.0|Apache License 2.0\n"
