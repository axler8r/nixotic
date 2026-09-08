import std/[json, os, strtabs, strutils, tables, unittest]
import "../context"
import "../driver"
import "../process"
import "../spec"
import "../testing"

template withSavedContext(body: untyped) =
  block:
    var saved: seq[(string, bool, string)]
    for name in [axOutputEnv, axDryRunEnv, axColorEnv, axQuietEnv, axVerboseEnv]:
      saved.add (name, existsEnv(name), getEnv(name))
    try:
      body
    finally:
      for (name, existed, value) in saved:
        if existed: putEnv(name, value)
        else: delEnv(name)

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
    check ex.words == @["vault", "--", "-o", "json", "mount"]
    check ex.resolvable == 1
    check ex.ctx.output == omTable

  test "resolved arguments retain the delimiter through validation":
    let ex = extractCommon(@["vault", "mount", "--", "--help"], Ctx())
    let res = resolveCommand(ex.words, ex.resolvable, basePaths)
    check res.kind == rkFull
    check res.rest == @["--", "--help"]
    check not ex.help
    let s = CommandSpec(args: @[ArgSpec(name: "name", required: true)])
    check validateArgs(s, res.rest)

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

suite "driver self machinery":
  let specs = @[
    CommandSpec(specVersion: 1, path: @["vault", "mount"], kind: ckVerb,
                summary: "mount a LUKS vault", usage: "ax vault mount <name>",
                deps: @["cryptsetup", "mount"], dryRun: false),
    CommandSpec(specVersion: 1, path: @["sys", "swap"], kind: ckReport,
                summary: "per-process swap usage", usage: "ax sys swap",
                dryRun: false)
  ]
  let groups = block:
    var t: OrderedTable[string, string]
    t["vault"] = "LUKS vaults"
    t["sys"] = "system reports"
    t

  test "listZshFunctions returns sorted names, empty for a missing dir":
    let dir = getTempDir() / "test_driver_zsh_functions"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "Update-GitWIPBranchHistory", "")
    writeFile(dir / "Mount-Nfs", "")
    check listZshFunctions(dir) == @["Mount-Nfs", "Update-GitWIPBranchHistory"]
    removeDir(dir)
    check listZshFunctions(dir).len == 0

  test "selfCommands lists both populations through the renderer":
    let tmp = getTempDir() / "test_driver_self_commands.txt"
    let f = open(tmp, fmWrite)
    let rec = newRecordingRunner(exitCode = 0, output = "rendered\n")
    var ctx = Ctx()
    ctx.output = omPlain
    let code = selfCommands(specs, @["Mount-Nfs"], ctx, rec.runner, f, f)
    f.close()
    removeFile(tmp)
    check code == 0
    check rec.calls[0].input.contains("ax vault mount|ax|mount a LUKS vault")
    check rec.calls[0].input.contains("Mount-Nfs|zsh|")

  test "selfDoctor passes when every dependency resolves":
    let dir = getTempDir() / "test_driver_doctor_ok"
    removeDir(dir)
    createDir(dir)
    for exe in ["cryptsetup", "mount"]:
      writeFakeExe(dir, exe, "exit 0")
    let tmp = dir / "out.txt"
    let f = open(tmp, fmWrite)
    var code: int
    withPath(dir):
      code = selfDoctor(specs, outp = f, errp = f)
    f.close()
    removeDir(dir)
    check code == 0

  test "selfDoctor reports the commands with missing dependencies":
    let dir = getTempDir() / "test_driver_doctor_missing"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "mount", "exit 0")
    let tmp = dir / "out.txt"
    let f = open(tmp, fmWrite)
    var code: int
    withPath(dir):
      code = selfDoctor(specs, outp = f, errp = f)
    f.close()
    let content = readFile(tmp)
    removeDir(dir)
    check code == 1
    check content.contains("ax vault mount: missing cryptsetup")
    check not content.contains("ax sys swap:")

  test "newCommand scaffolds module, test, and a groups.json seed":
    let dir = getTempDir() / "test_driver_new_command" / "commands"
    removeDir(getTempDir() / "test_driver_new_command")
    createDir(dir)
    writeFile(dir / "groups.json", "{\n  \"vault\": \"LUKS vaults\"\n}\n")
    let tmp = getTempDir() / "test_driver_new_command_out.txt"
    let f = open(tmp, fmWrite)
    let code = newCommand(@["zfs", "snapshot", "remove"], dir, f, f)
    f.close()
    removeFile(tmp)
    let module = readFile(dir / "zfs" / "snapshot" / "remove.nim")
    let test = readFile(dir / "zfs" / "snapshot" / "tests" / "test_remove.nim")
    let groupsOut = readFile(dir / "groups.json")
    removeDir(getTempDir() / "test_driver_new_command")
    check code == 0
    check module.contains("path: @[\"zfs\", \"snapshot\", \"remove\"]")
    check module.contains("import \"../../../lib/spec\"")
    check module.contains("axMain(cmdSpec)")
    check module.contains("\"\"\"Usage: ax zfs snapshot remove")
    check test.contains("import \"../remove\"")
    check test.contains("import \"../../../../lib/testing\"")
    check groupsOut.contains("\"zfs\": \"TODO")
    check groupsOut.contains("\"zfs snapshot\": \"TODO")
    check groupsOut.contains("\"vault\": \"LUKS vaults\"")

  test "newCommand rejects a leaf outside the lexicon":
    let dir = getTempDir() / "test_driver_new_command_bad" / "commands"
    removeDir(getTempDir() / "test_driver_new_command_bad")
    createDir(dir)
    writeFile(dir / "groups.json", "{}\n")
    let tmp = getTempDir() / "test_driver_new_command_bad_out.txt"
    let f = open(tmp, fmWrite)
    let code = newCommand(@["zfs", "frobnicate"], dir, f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    removeDir(getTempDir() / "test_driver_new_command_bad")
    check code == 64
    check content.contains("not a lexicon verb or report-noun")

  test "completionBash emits depth-cased compgen words":
    let script = completionBash(specs, groups)
    check script.contains("compgen -W \"sys vault help version self\"")
    check script.contains("vault) COMPREPLY=($(compgen -W \"mount\"")
    check script.contains("complete -o default -F _ax_complete ax")

  test "completionNu emits one extern per command":
    let script = completionNu(specs, groups)
    check script.contains("export extern \"ax vault mount\"")
    check script.contains("export extern \"ax sys swap\"")

suite "driver strict registry inputs":
  test "scaffolding rejects command prefix overlaps without writes":
    let dir = getTempDir() / "test_driver_scaffold_overlap"
    removeDir(dir)
    createDir(dir / "vault")
    defer: removeDir(dir)
    writeFile(dir / "groups.json", "{\"vault\":\"vault commands\"}")
    writeFile(dir / "vault" / "mount.nim", "existing")
    let f = open(dir / "output.txt", fmWrite)
    defer: f.close()
    check newCommand(@["vault", "mount", "list"], dir, f, f) == 1
    check not dirExists(dir / "vault" / "mount")
    removeFile(dir / "vault" / "mount.nim")
    createDir(dir / "vault" / "mount")
    writeFile(dir / "vault" / "mount" / "list.nim", "existing")
    check newCommand(@["vault", "mount"], dir, f, f) == 1
    check not fileExists(dir / "vault" / "mount.nim")

  test "registry requires an array of valid nonoverlapping specs":
    let tmp = getTempDir() / "test_driver_registry_shape.json"
    let s = CommandSpec(specVersion: specVersionCurrent,
      path: @["vault", "mount"], summary: "mount a vault", usage: "ax vault mount")
    for text in ["{}", "null", "[null]", "[{}]"]:
      writeFile(tmp, text)
      expect CatchableError:
        discard loadRegistry(tmp)
    writeFile(tmp, $(%*[s.toJson(), s.toJson()]))
    expect ValueError:
      discard loadRegistry(tmp)
    let nested = CommandSpec(specVersion: specVersionCurrent,
      path: @["vault", "mount", "list"], summary: "list mounts",
      usage: "ax vault mount list")
    writeFile(tmp, $(%*[s.toJson(), nested.toJson()]))
    expect ValueError:
      discard loadRegistry(tmp)
    writeFile(tmp, $(%*[s.toJson()]))
    check loadRegistry(tmp) == @[s]
    removeFile(tmp)

  test "groups require an object with valid paths and string summaries":
    let tmp = getTempDir() / "test_driver_groups_shape.json"
    for text in ["[]", "null", "{\"vault\":false}", "{\"vault\":null}",
                 "{\"vault\":\"\"}", "{\"../escape\":\"bad\"}",
                 "{\"a b c\":\"bad\"}", "{\"a  b\":\"bad\"}",
                 "{\"self\":\"reserved\"}"]:
      writeFile(tmp, text)
      expect ValueError:
        discard loadGroups(tmp)
    writeFile(tmp, "{\"vault\":\"LUKS vaults\"}")
    check loadGroups(tmp)["vault"] == "LUKS vaults"
    removeFile(tmp)

  test "buildRegistry rejects malformed kinds before emitting any registry":
    let dir = getTempDir() / "test_driver_bad_spec_kind"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "ax-vault-mount", "")
    let s = CommandSpec(specVersion: specVersionCurrent,
      path: @["vault", "mount"], summary: "mount a vault", usage: "ax vault mount")
    var node = s.toJson()
    node["dryRun"] = %"false"
    let rec = newRecordingRunner(output = $node)
    let outPath = dir / "out.json"
    let errPath = dir / "err.txt"
    let outp = open(outPath, fmWrite)
    let errp = open(errPath, fmWrite)
    check buildRegistry(dir, rec.runner, outp, errp) == 1
    outp.close()
    errp.close()
    check readFile(outPath) == ""
    check readFile(errPath).contains("dryRun must be JBool")
    check rec.calls.len == 1
    removeDir(dir)

suite "driver builtin safety and context":
  test "all self help paths bypass metadata and execution even with dry-run":
    let dir = getTempDir() / "test_driver_builtin_help"
    removeDir(dir)
    createDir(dir)
    let f = open(dir / "out.txt", fmWrite)
    let rec = newRecordingRunner()
    withSavedContext:
      for words in [newSeq[string](), @["commands"], @["doctor"],
                    @["completion", "invalid"], @["build-registry"],
                    @["new-command", "zfs", "snapshot", "remove"]]:
        check selfCmd(words, Ctx(dryRun: true), dir / "missing-libexec",
          dir / "missing-registry", dir / "missing-groups", help = true,
          runner = rec.runner, outp = f, errp = f, commandsDir = dir) == 0
      check rec.calls.len == 0
    f.close()
    check not dirExists(dir / "zfs")
    check readFile(dir / "out.txt").contains("Usage: ax self new-command")
    removeDir(dir)

  test "new-command refuses both flag-derived and inherited dry-run":
    let dir = getTempDir() / "test_driver_builtin_dry_run"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "groups.json", "{}\n")
    let f = open(dir / "out.txt", fmWrite)
    withSavedContext:
      let fromFlag = extractCommon(@["self", "new-command", "zfs", "remove", "-n"], Ctx())
      putEnv(axDryRunEnv, "1")
      for ctx in [fromFlag.ctx, ctxFromEnv()]:
        check selfCmd(@["new-command", "zfs", "remove"], ctx, "", "", "",
          outp = f, errp = f, commandsDir = dir) == 64
    f.close()
    check not dirExists(dir / "zfs")
    check readFile(dir / "groups.json") == "{}\n"
    removeDir(dir)

  test "self doctor uses exported quiet color and output context":
    let dir = getTempDir() / "test_driver_builtin_context"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "registry.json", "[]")
    let f = open(dir / "out.txt", fmWrite)
    withSavedContext:
      exportCtx(Ctx(color: cmAlways))
      let ex = extractCommon(@["self", "doctor", "--quiet", "--color", "never",
                               "-o", "json", "--verbose"], Ctx())
      check selfCmd(@["doctor"], ex.ctx, "", dir / "registry.json", "",
                    outp = f, errp = f) == 0
      check ctxFromEnv() == ex.ctx
    f.close()
    check readFile(dir / "out.txt") == ""
    removeDir(dir)

  test "command help exports resolved context before capture":
    let tmp = getTempDir() / "test_driver_command_help_context.txt"
    let f = open(tmp, fmWrite)
    let rec = newRecordingRunner(output = "Usage: command\n")
    let ctx = Ctx(output: omJson, color: cmNever, dryRun: true,
                  quiet: true, verbose: true)
    withSavedContext:
      check commandHelp("fake-command", ctx, @["topic"], rec.runner, f, f) == 0
      check rec.calls.len == 1
      check rec.calls[0].args == @["topic", "--help"]
      check rec.calls[0].env[axOutputEnv] == "json"
      check rec.calls[0].env[axColorEnv] == "never"
      check rec.calls[0].env[axDryRunEnv] == "1"
      check rec.calls[0].env[axQuietEnv] == "1"
      check rec.calls[0].env[axVerboseEnv] == "1"
    f.close()
    check readFile(tmp) == "Usage: command\n"
    removeFile(tmp)

  test "extra builtin arguments fail before metadata or subprocesses":
    let tmp = getTempDir() / "test_driver_builtin_arity.txt"
    let f = open(tmp, fmWrite)
    let rec = newRecordingRunner()
    withSavedContext:
      for words in [@["commands", "extra"], @["doctor", "--typo"],
                    @["build-registry", "extra"], @["completion"],
                    @["completion", "zsh", "extra"]]:
        check selfCmd(words, Ctx(), "", "", "", runner = rec.runner,
                      outp = f, errp = f) == 64
    f.close()
    check rec.calls.len == 0
    removeFile(tmp)

suite "driver scaffold preflight":
  test "malformed or absent groups leave module and test directories absent":
    let dir = getTempDir() / "test_driver_scaffold_groups"
    removeDir(dir)
    createDir(dir)
    let f = open(dir / "out.txt", fmWrite)
    check newCommand(@["zfs", "snapshot", "remove"], dir, f, f) == 1
    check not dirExists(dir / "zfs")
    for text in ["not json", "[]", "{\"zfs\":1}"]:
      writeFile(dir / "groups.json", text)
      check newCommand(@["zfs", "snapshot", "remove"], dir, f, f) == 1
      check not dirExists(dir / "zfs")
      check readFile(dir / "groups.json") == text
    f.close()
    removeDir(dir)

  test "an existing test file is never overwritten and no module is created":
    let dir = getTempDir() / "test_driver_scaffold_existing_test"
    removeDir(dir)
    createDir(dir / "zfs" / "tests")
    writeFile(dir / "groups.json", "{}\n")
    let testPath = dir / "zfs" / "tests" / "test_remove.nim"
    writeFile(testPath, "keep this test")
    let f = open(dir / "out.txt", fmWrite)
    check newCommand(@["zfs", "remove"], dir, f, f) == 1
    f.close()
    check readFile(testPath) == "keep this test"
    check not fileExists(dir / "zfs" / "remove.nim")
    check readFile(dir / "groups.json") == "{}\n"
    removeDir(dir)

  test "directory destinations and file parents are rejected before writing":
    let dir = getTempDir() / "test_driver_scaffold_blocked"
    removeDir(dir)
    createDir(dir / "zfs" / "remove.nim")
    writeFile(dir / "groups.json", "{}\n")
    let f = open(dir / "out.txt", fmWrite)
    check newCommand(@["zfs", "remove"], dir, f, f) == 1
    check not dirExists(dir / "zfs" / "tests")
    removeDir(dir / "zfs" / "remove.nim")
    writeFile(dir / "zfs" / "tests", "blocker")
    check newCommand(@["zfs", "remove"], dir, f, f) == 1
    check not fileExists(dir / "zfs" / "remove.nim")
    f.close()
    check readFile(dir / "groups.json") == "{}\n"
    removeDir(dir)

  test "dangling destinations and symlinked parents or groups are rejected":
    let dir = getTempDir() / "test_driver_scaffold_links"
    removeDir(dir)
    createDir(dir / "commands" / "zfs")
    createDir(dir / "outside")
    let commands = dir / "commands"
    writeFile(commands / "groups.json", "{}\n")
    let f = open(dir / "out.txt", fmWrite)
    let module = commands / "zfs" / "remove.nim"
    createSymlink(dir / "absent", module)
    check newCommand(@["zfs", "remove"], commands, f, f) == 1
    check symlinkExists(module)
    check not fileExists(dir / "absent")
    removeFile(module)
    removeDir(commands / "zfs")
    createSymlink(dir / "outside", commands / "zfs")
    check newCommand(@["zfs", "remove"], commands, f, f) == 1
    check not fileExists(dir / "outside" / "remove.nim")
    removeFile(commands / "zfs")
    removeFile(commands / "groups.json")
    writeFile(dir / "outside" / "groups.json", "{}\n")
    createSymlink(dir / "outside" / "groups.json", commands / "groups.json")
    check newCommand(@["zfs", "remove"], commands, f, f) == 1
    check not dirExists(commands / "zfs")
    check readFile(dir / "outside" / "groups.json") == "{}\n"
    removeFile(commands / "groups.json")
    f.close()
    removeDir(dir)

  test "report-noun scaffolds use report kind and the shared argument guard":
    let dir = getTempDir() / "test_driver_scaffold_report"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "groups.json", "{}\n")
    let f = open(dir / "out.txt", fmWrite)
    check newCommand(@["sys", "swap"], dir, f, f) == 0
    f.close()
    let source = readFile(dir / "sys" / "swap.nim")
    check source.contains("kind: ckReport")
    check source.contains("if not validateArgs(cmdSpec, args, errp): return 64")
    removeDir(dir)
