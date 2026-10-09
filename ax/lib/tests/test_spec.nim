import std/[json, os, strutils, unittest]
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
    s.path = @["sys", "swap"]
    s.usage = "ax sys swap"
    s.kind = ckReport
    check s.toJson()["kind"].getStr == "report"
    check commandSpecFromJson(s.toJson()).kind == ckReport

  test "a malformed node raises a CatchableError":
    expect CatchableError:
      discard commandSpecFromJson(parseJson("""{"specVersion": 1}"""))

suite "spec schema and semantics":
  test "wrong top-level field kinds never silently default":
    for name in ["specVersion", "path", "kind", "summary", "usage", "args",
                 "flags", "deps", "dryRun"]:
      var n = sample().toJson()
      n[name] = newJNull()
      expect ValueError:
        discard commandSpecFromJson(n)
    for n in [newJArray(), newJNull(), %"spec"]:
      expect ValueError:
        discard commandSpecFromJson(n)

  test "nested field kinds are checked including booleans":
    for name in ["name", "required", "variadic", "description"]:
      var n = sample().toJson()
      n["args"][0][name] = newJNull()
      expect ValueError:
        discard commandSpecFromJson(n)
    for name in ["long", "short", "takesValue", "description"]:
      var n = sample().toJson()
      n["flags"][0][name] = newJNull()
      expect ValueError:
        discard commandSpecFromJson(n)
    for name in ["path", "deps", "args", "flags"]:
      var n = sample().toJson()
      n[name].elems[0] = %1
      expect ValueError:
        discard commandSpecFromJson(n)

  test "unknown fields and unsupported versions are rejected":
    var n = sample().toJson()
    n["dryrun"] = %true
    expect ValueError:
      discard commandSpecFromJson(n)
    n = sample().toJson()
    n["specVersion"] = %2
    expect ValueError:
      discard commandSpecFromJson(n)
    n = sample().toJson()
    n["flags"][0]["takeValue"] = %false
    expect ValueError:
      discard commandSpecFromJson(n)

  test "paths must be reversible canonical non-builtin command paths":
    for path in [@["list"], @["a", "b", "c", "list"],
                 @["../escape", "list"], @["bad-group", "list"],
                 @["Group", "list"], @["", "list"],
                 @["self", "list"], @["help", "list"],
                 @["version", "list"], @["docker", "ls"],
                 @["docker", "frobnicate"]]:
      var s = sample()
      s.path = path
      s.usage = "ax " & path.join(" ")
      expect ValueError:
        discard commandSpecFromJson(s.toJson())

  test "kind must agree with the lexicon":
    var s = sample()
    s.kind = ckReport
    expect ValueError:
      discard commandSpecFromJson(s.toJson())
    s.kind = ckVerb
    s.path = @["sys", "swap"]
    s.usage = "ax sys swap"
    expect ValueError:
      discard commandSpecFromJson(s.toJson())

  test "reserved global and hidden flags cannot be declared by commands":
    for name in ["output", "raw", "dry-run", "color", "quiet", "verbose",
                 "help", "version", "ax-spec"]:
      var s = sample()
      s.flags = @[FlagSpec(long: name)]
      expect ValueError:
        discard commandSpecFromJson(s.toJson())
    for name in ["o", "n", "q", "v", "h", "V"]:
      var s = sample()
      s.flags = @[FlagSpec(short: name)]
      expect ValueError:
        discard commandSpecFromJson(s.toJson())

  test "invalid duplicate and nameless flags are rejected":
    for flags in [@[FlagSpec()], @[FlagSpec(long: "--force")],
                  @[FlagSpec(short: "ff")], @[FlagSpec(short: "-")],
                  @[FlagSpec(long: "force"), FlagSpec(long: "force")],
                  @[FlagSpec(short: "f"), FlagSpec(short: "f")]]:
      var s = sample()
      s.flags = flags
      expect ValueError:
        discard commandSpecFromJson(s.toJson())

  test "positional declarations must be unambiguous":
    for args in [@[ArgSpec(name: "")],
                 @[ArgSpec(name: "x"), ArgSpec(name: "x")],
                 @[ArgSpec(name: "x"), ArgSpec(name: "y", required: true)],
                 @[ArgSpec(name: "x", variadic: true), ArgSpec(name: "y")]]:
      var s = sample()
      s.args = args
      expect ValueError:
        discard commandSpecFromJson(s.toJson())

  test "summary usage and dependencies have meaningful content":
    var s = sample()
    s.summary = "\n"
    expect ValueError:
      discard commandSpecFromJson(s.toJson())
    s = sample()
    s.usage = "ax docker image listother"
    expect ValueError:
      discard commandSpecFromJson(s.toJson())
    for deps in [@[""], @["git", "git"], @["git --version"]]:
      s = sample()
      s.deps = deps
      expect ValueError:
        discard commandSpecFromJson(s.toJson())

proc checkedArgs(s: CommandSpec, args: openArray[string]):
    tuple[ok: bool, diagnostic: string] =
  let tmp = getTempDir() / "test_spec_validate_args.txt"
  let f = open(tmp, fmWrite)
  try:
    result.ok = validateArgs(s, args, f)
  finally:
    f.close()
  result.diagnostic = readFile(tmp)
  removeFile(tmp)

suite "spec argument validation":
  let s = CommandSpec(
    args: @[ArgSpec(name: "name", required: true), ArgSpec(name: "dir")],
    flags: @[FlagSpec(long: "file", short: "f", takesValue: true),
             FlagSpec(short: "e", takesValue: true), FlagSpec(long: "force")])

  test "known flags and optional positionals validate":
    check checkedArgs(s, ["name"]).ok
    check checkedArgs(s, ["--force", "name", "--file", "index", "dir"]).ok
    check checkedArgs(s, ["name", "--file=index"]).ok

  test "existing short attached value forms validate":
    for flag in ["-e.nim", "-e=.nim", "-e:.nim", "-findex"]:
      check checkedArgs(s, ["name", flag]).ok

  test "unknown flags and values on boolean flags are rejected":
    for flag in ["--typo", "-x", "--force=yes", "--dry-run", "-n"]:
      check not checkedArgs(s, ["name", flag]).ok
    check checkedArgs(s, ["name", "--typo"]).diagnostic.contains("Unknown option")

  test "missing option values cannot consume the next option or terminator":
    for args in [@["name", "--file"], @["name", "--file="],
                 @["name", "-e="], @["name", "-e:"],
                 @["name", "--file", ""], @["name", "--file", "--force"],
                 @["name", "--file", "--"]]:
      let result = checkedArgs(s, args)
      check not result.ok
      check result.diagnostic.contains("Missing value")

  test "missing required positionals and excess arguments are rejected":
    check not checkedArgs(s, []).ok
    check not checkedArgs(s, [""]).ok
    check not checkedArgs(s, ["one", "two", "three"]).ok
    check not checkedArgs(CommandSpec(), ["stray"]).ok

  test "terminator preserves dash-prefixed positionals including help":
    check checkedArgs(s, ["--", "--help"]).ok
    check checkedArgs(s, ["name", "--", "-n"]).ok
    check not checkedArgs(s, ["--"]).ok

  test "required variadic arguments need at least one value":
    let variadic = CommandSpec(args: @[
      ArgSpec(name: "name", required: true),
      ArgSpec(name: "files", required: true, variadic: true)])
    check not checkedArgs(variadic, []).ok
    check not checkedArgs(variadic, ["name"]).ok
    check checkedArgs(variadic, ["name", "a"]).ok
    check checkedArgs(variadic, ["name", "a", "b"]).ok
    let optional = CommandSpec(args: @[ArgSpec(name: "files", variadic: true)])
    check checkedArgs(optional, []).ok
    check checkedArgs(optional, ["a", "b"]).ok

  test "dry-run switches are accepted only for supporting commands":
    let supported = CommandSpec(dryRun: true)
    check checkedArgs(supported, ["-n"]).ok
    check checkedArgs(supported, ["--dry-run"]).ok
    check not checkedArgs(supported, ["--dry-run=true"]).ok
    check not checkedArgs(CommandSpec(), ["--dry-run"]).ok

  test "help bypasses unsupported dry-run and required arguments":
    let tmp = getTempDir() / "test_spec_invocation.txt"
    let f = open(tmp, fmWrite)
    check validateInvocation(s, ["--help"], true, f)
    check validateInvocation(s, ["-h"], true, f)
    check not validateInvocation(s, ["name"], true, f)
    check not validateInvocation(s, [], false, f)
    check not validateInvocation(s, ["name", "--unknown"], false, f)
    check not validateInvocation(s, ["--", "--help"], true, f)
    check validateInvocation(s, ["name"], false, f)
    f.close()
    removeFile(tmp)
