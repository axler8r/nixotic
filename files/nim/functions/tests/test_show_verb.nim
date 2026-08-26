import std/[unittest, os, strutils]
import "../ShowVerb"

suite "Show-Verb run":
  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_show_verb_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Show-Verb")

  test "prints usage and returns 0 for --help":
    check run(@["--help"]) == 0

  test "fails when the verb argument is missing":
    check run(@[]) == 1

  test "fails on an unknown verb":
    check run(@["Frobnicate"]) == 1

  test "prints the group and description for a known verb":
    let tmp = getTempDir() / "test_show_verb_get.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["Get"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content == "Get (Common): Specifies an action that retrieves a resource\n"
