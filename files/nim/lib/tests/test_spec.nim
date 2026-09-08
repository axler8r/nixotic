import std/[json, unittest]
import "../spec"

proc sample(): CommandSpec =
  CommandSpec(
    specVersion: specVersionCurrent,
    path: @["docker", "image", "list"],
    kind: ckVerb,
    summary: "list local Docker images",
    usage: "ax docker image list [--dangling]",
    args: @[ArgSpec(name: "term", required: false, variadic: false,
                    description: "filter term")],
    flags: @[FlagSpec(long: "dangling", short: "", takesValue: false,
                      description: "only dangling images")],
    deps: @["docker"],
    dryRun: false)

suite "spec JSON round-trip":
  test "toJson emits the documented shape":
    let n = sample().toJson()
    check n["specVersion"].getInt == 1
    check n["path"].len == 3
    check n["kind"].getStr == "verb"
    check n["flags"][0]["long"].getStr == "dangling"
    check n["args"][0]["name"].getStr == "term"
    check n["deps"][0].getStr == "docker"
    check n["dryRun"].getBool == false

  test "commandSpecFromJson inverts toJson":
    let s = sample()
    check commandSpecFromJson(s.toJson()) == s

  test "report kind serialises as 'report'":
    var s = sample()
    s.kind = ckReport
    check s.toJson()["kind"].getStr == "report"
    check commandSpecFromJson(s.toJson()).kind == ckReport

  test "a malformed node raises a CatchableError":
    expect CatchableError:
      discard commandSpecFromJson(parseJson("""{"specVersion": 1}"""))
