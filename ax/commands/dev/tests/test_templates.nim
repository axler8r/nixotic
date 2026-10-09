import std/[json, unittest, os, strutils]
import "../templates"
import "../../../lib/testing"

suite "ax dev templates run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_dev_templates_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax dev templates")

  test "lists every template through the renderer":
    let dir = getTempDir() / "test_dev_templates_list"
    removeDir(dir)
    createDir(dir)
    let rec = newRecordingRunner(exitCode = 0, output = "rendered\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw"], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "column"
    for name in ["tool", "python", "dotnet", "elixir"]:
      check rec.calls[0].input.contains(name)

  test "AX_OUTPUT=json emits a jq-ready array of template objects":
    let tmp = getTempDir() / "test_dev_templates_json.txt"
    let f = open(tmp, fmWrite)
    putEnv("AX_OUTPUT", "json")
    let code = run(@[], f, f)
    delEnv("AX_OUTPUT")
    f.close()
    let parsed = parseJson(readFile(tmp))
    removeFile(tmp)
    check code == 0
    check parsed.len == 4
    check parsed[0]["template"].getStr == "tool"
    check parsed[1]["template"].getStr == "python"