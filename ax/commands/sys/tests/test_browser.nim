import std/[unittest, os, strutils, json, tempfiles]
import "../browser"
import "../../../lib/testing"

suite "ax sys browser run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_default_browser_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax sys browser")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_get_default_browser_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax sys browser")

  test "unknown option is an error":
    let tmp = getTempDir() / "test_get_default_browser_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Unknown option: --bogus")

  test "a stray positional argument is rejected before querying handlers":
    let tmp = getTempDir() / "test_get_default_browser_stray.txt"
    let f = open(tmp, fmWrite)
    let rec = newRecordingRunner()
    let code = run(@["foo"], f, f, rec.runner)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check rec.calls.len == 0
    check content.len > 0

  test "JSON output is structured even when stdout is not a TTY":
    let dir = createTempDir("ax-browser-json-", "")
    defer: removeDir(dir)
    writeFakeExe(dir, "xdg-mime", "")
    let hadOutput = existsEnv("AX_OUTPUT")
    let savedOutput = getEnv("AX_OUTPUT")
    putEnv("AX_OUTPUT", "json")
    defer:
      if hadOutput: putEnv("AX_OUTPUT", savedOutput)
      else: delEnv("AX_OUTPUT")
    let rec = newRecordingRunner(output = "browser.desktop\n")
    let path = dir / "out"
    let f = open(path, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, stderr, rec.runner)
    f.close()
    check code == 0
    let data = parseJson(readFile(path))
    check data == %*[{"scheme": "http", "handler": "browser.desktop"},
                    {"scheme": "https", "handler": "browser.desktop"}]
    check rec.calls.len == 2

  test "failed handler query is not reported as an empty default":
    let dir = createTempDir("ax-browser-failure-", "")
    defer: removeDir(dir)
    writeFakeExe(dir, "xdg-mime", "")
    let rec = newRecordingRunner(exitCode = 1, error = "query failed")
    let f = open("/dev/null", fmWrite)
    defer: f.close()
    withPath(dir):
      check run(@[], f, f, rec.runner) == 1
    check rec.calls.len == 1

  test "characterization: queries http then https scheme handlers":
    let dir = getTempDir() / "char_get_default_browser"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "xdg-mime", fakeRecorder(log))
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw"], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check calls == @[
      "query default x-scheme-handler/http",
      "query default x-scheme-handler/https"
    ]

  test "contract: queries the http then https scheme handlers in order":
    let rec = newRecordingRunner(exitCode = 0)
    let tmp = getTempDir() / "contract_get_default_browser.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--raw"], f, f, rec.runner)
    f.close()
    removeFile(tmp)
    check code == 0
    check rec.calls.len == 2
    check rec.calls[0].cmd == "xdg-mime"
    check rec.calls[0].args == @["query", "default", "x-scheme-handler/http"]
    check rec.calls[1].cmd == "xdg-mime"
    check rec.calls[1].args == @["query", "default", "x-scheme-handler/https"]
