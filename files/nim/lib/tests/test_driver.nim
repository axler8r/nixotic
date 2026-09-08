import std/[json, os, strutils, tables, unittest]
import "../context"
import "../driver"
import "../spec"
import "../testing"

let basePaths = @[
  @["attr", "get"],
  @["attr", "list"],
  @["vault", "mount"],
  @["vault", "unmount"],
  @["git", "wip", "start"],
  @["git", "wip", "finish"],
  @["docker", "image", "list"]
]

suite "driver extractCommon":
  test "plain words pass through untouched, ctx keeps its base":
    let ex = extractCommon(@["vault", "mount", "data"], Ctx())
    check ex.badFlag == ""
    check ex.words == @["vault", "mount", "data"]
    check ex.resolvable == 3
    check ex.ctx == Ctx()
    check ex.help == false
    check ex.version == false

  test "-o json is consumed wherever it appears":
    let ex = extractCommon(@["docker", "image", "list", "-o", "json"], Ctx())
    check ex.words == @["docker", "image", "list"]
    check ex.ctx.output == omJson
    let ex2 = extractCommon(@["-o", "json", "docker", "image", "list"], Ctx())
    check ex2.words == @["docker", "image", "list"]
    check ex2.ctx.output == omJson

  test "--raw is a deprecated alias for -o plain":
    let ex = extractCommon(@["vault", "mount", "--raw"], Ctx())
    check ex.ctx.output == omPlain
    check ex.words == @["vault", "mount"]

  test "flags override the environment-derived base ctx":
    var base = Ctx()
    base.output = omJson
    let ex = extractCommon(@["vault", "-o", "table"], base)
    check ex.ctx.output == omTable

  test "-n, -q, -v, --color are consumed":
    let ex = extractCommon(
      @["-n", "--color", "never", "-q", "-v", "vault"], Ctx())
    check ex.ctx.dryRun == true
    check ex.ctx.color == cmNever
    check ex.ctx.quiet == true
    check ex.ctx.verbose == true
    check ex.words == @["vault"]

  test "an invalid -o value sets badFlag":
    let ex = extractCommon(@["-o", "yaml", "vault"], Ctx())
    check ex.badFlag.contains("invalid value 'yaml'")

  test "a trailing -o with no value sets badFlag":
    let ex = extractCommon(@["vault", "-o"], Ctx())
    check ex.badFlag.contains("requires a value")

  test "-h and -V are recorded, not passed through":
    let ex = extractCommon(@["vault", "mount", "--help"], Ctx())
    check ex.help == true
    check ex.words == @["vault", "mount"]
    let ex2 = extractCommon(@["-V"], Ctx())
    check ex2.version == true

  test "everything after -- passes through verbatim and is not resolvable":
    let ex = extractCommon(@["vault", "--", "-o", "json", "mount"], Ctx())
    check ex.words == @["vault", "-o", "json", "mount"]
    check ex.resolvable == 1
    check ex.ctx.output == omTable

suite "driver resolveCommand":
  test "depth-2 full match splits path from rest":
    let r = resolveCommand(@["vault", "mount", "data"], 3, basePaths)
    check r.kind == rkFull
    check r.path == @["vault", "mount"]
    check r.rest == @["data"]

  test "depth-3 full match":
    let r = resolveCommand(@["git", "wip", "start", "topic"], 4, basePaths)
    check r.kind == rkFull
    check r.path == @["git", "wip", "start"]
    check r.rest == @["topic"]

  test "a leaf alias resolves to the canonical path":
    let r = resolveCommand(@["docker", "image", "ls"], 3, basePaths)
    check r.kind == rkFull
    check r.path == @["docker", "image", "list"]
    let r2 = resolveCommand(@["vault", "umount", "data"], 3, basePaths)
    check r2.path == @["vault", "unmount"]

  test "a flag stops path words":
    let r = resolveCommand(@["vault", "mount", "--force"], 3, basePaths)
    check r.kind == rkFull
    check r.path == @["vault", "mount"]
    check r.rest == @["--force"]

  test "a bare group is a valid prefix with sorted children":
    let r = resolveCommand(@["git", "wip"], 2, basePaths)
    check r.kind == rkPrefix
    check r.deepest == @["git", "wip"]
    check r.children == @["finish", "start"]

  test "an unknown word reports the deepest valid prefix":
    let r = resolveCommand(@["vault", "nosuch"], 2, basePaths)
    check r.kind == rkNone
    check r.deepest == @["vault"]
    check r.children == @["mount", "unmount"]

  test "an unknown group reports the top-level children":
    let r = resolveCommand(@["nosuch"], 1, basePaths)
    check r.kind == rkNone
    check r.deepest.len == 0
    check "vault" in r.children

  test "words after -- are never path segments":
    let r = resolveCommand(@["vault", "mount"], 1, basePaths)
    check r.kind == rkNone
    check r.deepest == @["vault"]

suite "driver buildRegistry":
  proc fakeSpec(path: seq[string]): string =
    let s = CommandSpec(
      specVersion: specVersionCurrent, path: path, kind: ckVerb,
      summary: "fake", usage: "ax " & path.join(" "), deps: @[],
      dryRun: false)
    "echo " & quoteShell($s.toJson())

  test "concatenates and sorts the specs of every ax-* binary":
    let dir = getTempDir() / "test_build_registry_ok"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "ax-vault-mount", fakeSpec(@["vault", "mount"]))
    writeFakeExe(dir, "ax-attr-get", fakeSpec(@["attr", "get"]))
    let outPath = dir / "out.json"
    let f = open(outPath, fmWrite)
    let code = buildRegistry(dir, outp = f, errp = f)
    f.close()
    let parsed = parseJson(readFile(outPath))
    removeDir(dir)
    check code == 0
    check parsed.len == 2
    check parsed[0]["path"][0].getStr == "attr"
    check parsed[1]["path"][0].getStr == "vault"

  test "a spec whose path disagrees with its binary name is fatal":
    let dir = getTempDir() / "test_build_registry_mismatch"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "ax-vault-mount", fakeSpec(@["vault", "unmount"]))
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    let code = buildRegistry(dir, outp = f, errp = f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("does not match the binary name")

  test "a leaf outside the lexicon is fatal":
    let dir = getTempDir() / "test_build_registry_bad_leaf"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "ax-vault-frobnicate", fakeSpec(@["vault", "frobnicate"]))
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    let code = buildRegistry(dir, outp = f, errp = f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("not a lexicon verb or report-noun")

  test "unparseable --ax-spec output is fatal":
    let dir = getTempDir() / "test_build_registry_garbage"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "ax-vault-mount", "echo not-json")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    let code = buildRegistry(dir, outp = f, errp = f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("not a valid spec")

suite "driver help and completion":
  let specs = @[
    CommandSpec(specVersion: 1, path: @["vault", "mount"], kind: ckVerb,
                summary: "mount a LUKS vault",
                usage: "ax vault mount <name>", dryRun: false),
    CommandSpec(specVersion: 1, path: @["git", "wip", "start"], kind: ckVerb,
                summary: "begin a WIP branch",
                usage: "ax git wip start <name>",
                flags: @[FlagSpec(long: "force", takesValue: false,
                                  description: "no confirmation")],
                dryRun: false)
  ]
  let groups = block:
    var t: OrderedTable[string, string]
    t["vault"] = "LUKS vaults"
    t["git"] = "git workflow"
    t["git wip"] = "WIP branch lifecycle"
    t

  test "overviewText lists top-level groups only, plus builtins":
    let text = overviewText(specs, groups, "0.1.0")
    check text.contains("ax 0.1.0")
    check text.contains("vault")
    check text.contains("LUKS vaults")
    check text.contains("help [<path>]")
    check not text.contains("WIP branch lifecycle")

  test "subtreeText lists the commands under a prefix with summaries":
    let text = subtreeText(specs, groups, @["git", "wip"])
    check text.contains("WIP branch lifecycle")
    check text.contains("ax git wip start")
    check text.contains("begin a WIP branch")
    check not text.contains("vault mount")

  test "completionZsh emits a parseable-looking tree with flags":
    let script = completionZsh(specs, groups)
    check script.startsWith("#compdef ax")
    check script.contains("'vault:LUKS vaults'")
    check script.contains("'git wip')")
    check script.contains("--force[no confirmation]")
    check script.contains("_describe")

  test "renderHelp writes plain text when outp is not a tty":
    let tmp = getTempDir() / "test_driver_render_help.txt"
    let f = open(tmp, fmWrite)
    let code = renderHelp("Usage: ax vault mount\n", outp = f, errp = f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content == "Usage: ax vault mount\n"
