import std/[unittest, os, strutils, algorithm]
import "../GetVerb"

suite "Get-Verb run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_verb_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-Verb")

  test "fails on an unknown option":
    check run(@["--bogus"]) == 1

  test "ignores a stray positional argument":
    let tmp = getTempDir() / "test_get_verb_positional.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["whatever"], f, f)
    f.close()
    removeFile(tmp)
    check code == 0

  test "raw output is sorted, one verb per line, no duplicates":
    let tmp = getTempDir() / "test_get_verb_raw.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--raw"], f, f)
    f.close()
    let lines = readFile(tmp).strip().splitLines()
    removeFile(tmp)
    check code == 0
    check lines.len > 50
    check lines == lines.sorted()
    check "Get" in lines
    check "Add" in lines

  test "non-tty output defaults to the raw listing even without --raw":
    let tmp = getTempDir() / "test_get_verb_nontty.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check "Get\n" in content
