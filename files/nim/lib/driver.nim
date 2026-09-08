## Driver logic for ax: cross-cutting flag extraction, command-path
## resolution against the registry, help text, registry generation, and
## completion generation. Everything here is pure or stream-injected so
## lib/tests can exercise it; ax.nim is the thin main that wires this to
## the real filesystem, environment, and exec.
import std/[algorithm, json, os, posix, sequtils, strutils, tables, terminal]
import context
import lexicon
import output
import process
import spec

# ---------------------------------------------------------------- extraction

type Extracted* = object
  ctx*: Ctx
  words*: seq[string]   ## everything not consumed, in original order
  resolvable*: int      ## words[0 ..< resolvable] may be path segments; a
                        ## `--` freezes everything after it as plain args
  help*: bool
  version*: bool
  badFlag*: string      ## diagnostic for an invalid/missing flag value; ""
                        ## when extraction succeeded

proc extractCommon*(args: seq[string], base: Ctx): Extracted =
  ## Pulls the cross-cutting flags (§ docs/ax-cli-design.md) out of argv
  ## wherever they appear, starting from `base` (the environment-derived
  ## Ctx) so `AX_OUTPUT=json ax ...` and `ax -o json ...` agree. A literal
  ## `--` stops extraction; later tokens pass through verbatim and are
  ## never treated as path segments.
  result.ctx = base
  result.resolvable = -1
  var i = 0
  var passthrough = false

  template needValue(flag: string, valid: openArray[string]): string =
    if i + 1 >= args.len:
      result.badFlag = flag & " requires a value"
      return result
    let v = args[i + 1]
    if v notin valid:
      result.badFlag = flag & ": invalid value '" & v & "'"
      return result
    i += 2
    v

  while i < args.len:
    let a = args[i]
    if passthrough:
      result.words.add a
      inc i
      continue
    case a
    of "--":
      passthrough = true
      result.resolvable = result.words.len
      result.words.add a
      inc i
    of "-o", "--output":
      let v = needValue(a, ["table", "plain", "json"])
      result.ctx.output = parseEnum[OutputMode](v)
    of "--raw":
      result.ctx.output = omPlain
      inc i
    of "-n", "--dry-run":
      result.ctx.dryRun = true
      inc i
    of "--color":
      let v = needValue(a, ["auto", "always", "never"])
      result.ctx.color = parseEnum[ColorMode](v)
    of "-q", "--quiet":
      result.ctx.quiet = true
      inc i
    of "-v", "--verbose":
      result.ctx.verbose = true
      inc i
    of "-h", "--help":
      result.help = true
      inc i
    of "-V", "--version":
      result.version = true
      inc i
    else:
      result.words.add a
      inc i
  if result.resolvable < 0:
    result.resolvable = result.words.len

# ---------------------------------------------------------------- resolution

type
  ResolveKind* = enum
    rkFull     ## words resolved to exactly one registry command
    rkPrefix   ## words are a valid group/subgroup with nothing after it
    rkNone     ## first unmatched word; deepest/children describe the tree

  Resolution* = object
    kind*: ResolveKind
    path*: seq[string]       ## rkFull: the canonical command path
    rest*: seq[string]       ## rkFull: the words after the path, in order
    deepest*: seq[string]    ## rkPrefix/rkNone: deepest valid prefix
    children*: seq[string]   ## rkPrefix/rkNone: next segments under deepest

proc childrenOf(paths: seq[seq[string]], prefix: seq[string]): seq[string] =
  for p in paths:
    if p.len > prefix.len and p[0 ..< prefix.len] == prefix and
       p[prefix.len] notin result:
      result.add p[prefix.len]
  result.sort()

proc resolveCommand*(words: seq[string], resolvable: int,
                     paths: seq[seq[string]]): Resolution =
  ## Longest-prefix match of the leading words against registry paths,
  ## alias-normalising only the candidate leaf (grammar: aliases are leaf
  ## words). Only words before the first `-`-prefixed token and before a
  ## `--` are eligible as path segments.
  var lead: seq[string]
  for i, w in words:
    if i >= resolvable or w.startsWith("-") or lead.len == 3:
      break
    lead.add w

  for depth in countdown(min(3, lead.len), 1):
    var cand = lead[0 ..< depth]
    cand[depth - 1] = canonicalLeaf(cand[depth - 1])
    if cand in paths:
      return Resolution(kind: rkFull, path: cand,
                        rest: words[depth .. ^1])

  var deepest: seq[string]
  for w in lead:
    let next = deepest & w
    if paths.anyIt(it.len > next.len and it[0 ..< next.len] == next):
      deepest = next
    else:
      break

  result.children = childrenOf(paths, deepest)
  result.deepest = deepest
  result.kind =
    if deepest.len == words.len and words.len > 0: rkPrefix
    else: rkNone

# ------------------------------------------------------------ registry files

proc addRegistrySpec(specs: var seq[CommandSpec], s: CommandSpec) =
  for existing in specs:
    let depth = min(existing.path.len, s.path.len)
    if existing.path[0 ..< depth] == s.path[0 ..< depth]:
      raise newException(ValueError, "duplicate or overlapping command path: " &
                          s.path.join(" "))
  specs.add s

proc loadRegistry*(file: string): seq[CommandSpec] =
  let node = parseJson(readFile(file))
  if node.kind != JArray:
    raise newException(ValueError, "registry must be a JSON array")
  for n in node:
    result.addRegistrySpec(commandSpecFromJson(n))

proc registryPaths*(specs: seq[CommandSpec]): seq[seq[string]] =
  specs.mapIt(it.path)

proc loadGroups*(file: string): OrderedTable[string, string] =
  ## groups.json: space-joined group path -> one-line summary. JsonNode
  ## objects preserve insertion order, so the file's order is the display
  ## order.
  let node = parseJson(readFile(file))
  if node.kind != JObject:
    raise newException(ValueError, "groups must be a JSON object")
  for k, v in node:
    let words = k.split(' ')
    if words.len notin 1 .. 2 or words.anyIt(not validPathSegment(it)) or
       words[0] in ["help", "version", "self"]:
      raise newException(ValueError, "invalid group path: " & k)
    if v.kind != JString or v.getStr.strip().len == 0 or
       v.getStr.contains({'\n', '\r', '\0'}):
      raise newException(ValueError, "group summary must be a nonempty single line: " & k)
    result[k] = v.getStr

# ------------------------------------------------------------------ building

proc buildRegistry*(libexecDir: string, runner: Runner = defaultRunner,
                    outp: File = stdout, errp: File = stderr): int =
  ## `ax self build-registry`: exec every libexec/ax/ax-* with --ax-spec,
  ## validate each answer against the lexicon and its own binary name, and
  ## emit the sorted registry JSON on stdout. Any failure is fatal — this
  ## runs inside the package build, so a bad spec fails the build.
  var names: seq[string]
  try:
    for kind, path in walkDir(libexecDir, checkDir = true):
      let name = extractFilename(path)
      if name.startsWith("ax-"):
        if kind notin {pcFile, pcLinkToFile}:
          error("not a command binary: " & path, errp)
          return 1
        names.add name
  except OSError as e:
    error(e.msg, errp)
    return 1
  names.sort()

  var arr = newJArray()
  var specs: seq[CommandSpec]
  for name in names:
    let cr = runner.capture(libexecDir / name, @["--ax-spec"])
    if cr.exitCode != 0:
      error(name & " --ax-spec exited " & $cr.exitCode & ": " & cr.error, errp)
      return 1
    var node: JsonNode
    var cmdSpec: CommandSpec
    try:
      node = parseJson(cr.output)
      cmdSpec = commandSpecFromJson(node)
      specs.addRegistrySpec(cmdSpec)
    except CatchableError as e:
      error(name & " --ax-spec is not a valid spec: " & e.msg, errp)
      return 1
    if "ax-" & cmdSpec.path.join("-") != name:
      error(name & ": spec path '" & cmdSpec.path.join(" ") &
            "' does not match the binary name", errp)
      return 1
    arr.add node
  outp.writeLine(arr.pretty())
  0

# ---------------------------------------------------------------------- help

const globalFlagsHelp* = """
Global flags:
    -o, --output <table|plain|json>    output mode (--raw: deprecated alias for -o plain)
    -n, --dry-run                      print intended actions without executing
        --color <auto|always|never>    colour output (NO_COLOR honoured on auto)
    -q, --quiet                        suppress Info/Success status lines
    -v, --verbose                      extra diagnostics on stderr
    -h, --help                         show help
    -V, --version                      show version"""

proc aligned(rows: seq[(string, string)], indent: string): string =
  var width = 0
  for (left, _) in rows:
    width = max(width, left.len)
  for (left, right) in rows:
    result.add indent & left.alignLeft(width + 4) & right & "\n"

proc overviewText*(specs: seq[CommandSpec],
                   groups: OrderedTable[string, string],
                   version: string): string =
  result = "ax " & version & " — the nixotic toolbelt\n\n" &
           "Usage: ax [global flags] <group> [<subgroup>] <command> [args]\n\n" &
           globalFlagsHelp & "\n\nGroups:\n"
  var rows: seq[(string, string)]
  for key, summary in groups:
    if ' ' notin key:
      rows.add (key, summary)
  result.add aligned(rows, "    ")
  result.add "\nBuiltins:\n"
  result.add aligned(@[
    ("help [<path>]", "this overview, a group's commands, or one command's help"),
    ("version", "print the ax version"),
    ("self <command>", "toolbelt maintenance: commands, completion, doctor, new-command, build-registry")
  ], "    ")
  result.add "\nRun `ax help <group>` to list a group's commands.\n"

proc subtreeText*(specs: seq[CommandSpec],
                  groups: OrderedTable[string, string],
                  prefix: seq[string]): string =
  let key = prefix.join(" ")
  result = "ax " & key
  if key in groups:
    result.add " — " & groups[key]
  result.add "\n\n"
  var rows: seq[(string, string)]
  for s in specs:
    if s.path.len > prefix.len and s.path[0 ..< prefix.len] == prefix:
      rows.add ("ax " & s.path.join(" "), s.summary)
  result.add aligned(rows, "    ")
  result.add "\nRun `ax help <group> <command>` for one command's help.\n"

proc renderHelp*(text: string, runner: Runner = defaultRunner,
                 outp: File = stdout, errp: File = stderr): int =
  ## Help pipeline inherited from Get-Help: bat syntax highlighting when
  ## stdout is a tty and bat is available, plain text otherwise. Colour
  ## defers to output.colorEnabled so NO_COLOR/--color stay honoured.
  if not isatty(outp) or findExe("bat").len == 0:
    outp.write(text)
    return 0
  let colored = colorEnabled(outp)
  let cr = runner.capture("bat",
    @[(if colored: "--color=always" else: "--color=never"),
      "--plain", "--language=help"], text)
  outp.write(cr.output)
  if cr.error.len > 0:
    errp.write(cr.error)
  cr.exitCode

proc commandHelp*(binPath: string, ctx: Ctx, extraArgs: seq[string] = @[],
                  runner: Runner = defaultRunner, outp: File = stdout,
                  errp: File = stderr): int =
  ## Help children and the renderer use the same resolved context as exec.
  exportCtx(ctx)
  let cr = runner.capture(binPath, extraArgs & @["--help"])
  if cr.error.len > 0:
    errp.write(cr.error)
  if cr.exitCode != 0:
    outp.write(cr.output)
    return cr.exitCode
  renderHelp(cr.output, runner, outp, errp)

# ---------------------------------------------------------------------- self

proc selfHelpText*(words: seq[string]): string =
  ## Empty means an unknown builtin. No registry or filesystem access.
  if words.len == 0:
    return "Usage: ax self <commands|completion|doctor|new-command|build-registry>\n"
  case words[0]
  of "commands": "Usage: ax self commands\nList ax commands and zsh functions.\n"
  of "completion": "Usage: ax self completion <zsh|bash|nu>\n"
  of "doctor": "Usage: ax self doctor\nAudit declared dependencies.\n"
  of "new-command": "Usage: ax self new-command <group> [<subgroup>] <leaf>\n"
  of "build-registry": "Usage: ax self build-registry\nEmit validated registry JSON.\n"
  else: ""

proc listZshFunctions*(dir: string): seq[string] =
  ## The surviving PascalCase zsh functions, for `ax self commands` — the
  ## cross-population discovery Get-UserFunctions used to scrape.
  if not dirExists(dir):
    return @[]
  for kind, path in walkDir(dir):
    if kind in {pcFile, pcLinkToFile}:
      result.add extractFilename(path)
  result.sort()

proc selfCommands*(specs: seq[CommandSpec], zshFunctions: seq[string],
                   ctx: Ctx, runner: Runner = defaultRunner,
                   outp: File = stdout, errp: File = stderr): int =
  ## `ax self commands`: every registry command plus the surviving zsh
  ## functions, one table, -o aware.
  var rows: seq[seq[string]] = @[]
  for s in specs:
    rows.add @["ax " & s.path.join(" "), "ax", s.summary]
  for name in zshFunctions:
    rows.add @[name, "zsh", ""]
  render(@["Command", "Source", "Summary"], rows, ctx, runner, outp, errp)

proc selfDoctor*(specs: seq[CommandSpec], runner: Runner = defaultRunner,
                 outp: File = stdout, errp: File = stderr): int =
  ## `ax self doctor`: audits every command's declared dependencies
  ## against $PATH. Exit 0 when everything resolves, 1 otherwise.
  var problems: seq[(string, string)]
  for s in specs:
    var missing: seq[string]
    for dep in s.deps:
      if findExe(dep).len == 0:
        missing.add dep
    if missing.len > 0:
      problems.add ("ax " & s.path.join(" "), missing.join(" "))
  if problems.len == 0:
    success("Every declared dependency is on $PATH.", errp)
    return 0
  for (cmd, missing) in problems:
    outp.writeLine(cmd & ": missing " & missing)
  error($problems.len & " command(s) have missing dependencies.", errp)
  1

const commandTemplate = """import std/os
import "$LIB/output"
import "$LIB/process"
import "$LIB/spec"
import "$LIB/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @[$PATHSEQ],
  kind: $KIND,
  summary: "TODO one line, lowercase first word",
  usage: "ax $PATHWORDS",
  deps: @[],
  dryRun: false
)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine ""\"Usage: ax $PATHWORDS

TODO description.

Options:
    -h, --help    Show this help message""\"
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64
  # TODO: requireArg/checkDeps guards, then the work.
  0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
"""

const testTemplate = """import std/[unittest, os, strutils]
import "../$LEAF"
import "$LIB/testing"

suite "ax $PATHWORDS run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_$UNDERSCORED_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax $PATHWORDS")
"""

proc newCommand*(words: seq[string], commandsDir: string,
                 outp: File = stdout, errp: File = stderr,
                 dryRun: bool = false): int =
  ## `ax self new-command <group> [<subgroup>] <leaf>`: scaffolds the
  ## module and its test under commands/, and seeds a groups.json entry
  ## when the group is new. There is no name mapping to update — the
  ## path IS the mapping.
  if dryRun:
    error("ax self new-command does not support --dry-run", errp)
    return 64
  if words.len < 2 or words.len > 3:
    error("usage: ax self new-command <group> [<subgroup>] <leaf>", errp)
    return 64
  for w in words:
    if not validPathSegment(w):
      error("segment '" & w & "' must match [a-z][a-z0-9]*", errp)
      return 64
  if words[0] in ["help", "version", "self"]:
    error("reserved builtin group: " & words[0], errp)
    return 64
  let leaf = words[^1]
  if not isAllowedLeaf(leaf):
    error("leaf '" & leaf & "' is not a lexicon verb or report-noun " &
          "(see files/nim/lexicon.json)", errp)
    return 64
  if not dirExists(commandsDir):
    error("no commands/ tree at " & commandsDir &
          " — run from the nixotic repo root", errp)
    return 1

  let subdir = commandsDir / words[0 ..< ^1].join("/")
  let module = subdir / (leaf & ".nim")
  let test = subdir / "tests" / ("test_" & leaf & ".nim")
  let groupsFile = commandsDir / "groups.json"

  # Preflight EVERY output and its ancestors before creating anything.
  # Refuse symlinks (including dangling ones) rather than writing outside
  # the source tree. Check groups before modules, not after writing them.
  proc entryExists(path: string): bool =
    try:
      discard getFileInfo(path, followSymlink = false)
      true
    except OSError as e:
      if e.errorCode == ENOENT: return false
      raise

  proc checkParent(path: string) =
    var parent = absolutePath(path).parentDir
    var nearest = true
    while parent.len > 0:
      if entryExists(parent):
        if symlinkExists(parent) or not dirExists(parent):
          raise newException(ValueError, "unsafe scaffold directory: " & parent)
        let mode = if nearest: W_OK or X_OK else: X_OK
        if access(parent.cstring, mode) != 0:
          raise newException(ValueError, "scaffold directory is not accessible: " & parent)
        nearest = false
      let next = parent.parentDir
      if next == parent: break
      parent = next

  var groups: OrderedTable[string, string]
  var seeded = false
  var groupsText = ""
  try:
    for source in walkDirRec(commandsDir, checkDir = true):
      let relative = relativePath(source, commandsDir)
      if not relative.endsWith(".nim") or "/tests/" in relative:
        continue
      let existing = relative[0 ..< relative.len - 4].split('/')
      let depth = min(existing.len, words.len)
      if existing[0 ..< depth] == words[0 ..< depth]:
        raise newException(ValueError,
          "command path overlaps existing source: " & relative)
    for path in [module, test]:
      checkParent(path)
      if entryExists(path):
        raise newException(ValueError, "already exists: " & path)
    checkParent(groupsFile)
    if symlinkExists(groupsFile) or not fileExists(groupsFile):
      raise newException(ValueError, "groups.json must be an existing regular file")
    groups = loadGroups(groupsFile)
    for depth in 1 ..< words.len:
      let key = words[0 ..< depth].join(" ")
      if key notin groups:
        groups[key] = "TODO one-line summary"
        seeded = true
    if seeded:
      if access(groupsFile.cstring, W_OK) != 0:
        raise newException(ValueError, "groups.json is not writable")
      var node = newJObject()
      for k, v in groups:
        node[k] = %v
      groupsText = node.pretty() & "\n"
  except CatchableError as e:
    error(e.msg, errp)
    return 1

  # lib/ relative to the module's directory: commands/<g>/ is two up,
  # commands/<g>/<s>/ is three, and the test sits one deeper.
  let libFromModule = (if words.len == 2: "../../lib" else: "../../../lib")
  let libFromTest = "../" & libFromModule

  proc fill(tmpl, lib: string): string =
    tmpl.replace("$LIB", lib)
      .replace("$KIND", if leaf in reportNouns: "ckReport" else: "ckVerb")
        .replace("$PATHSEQ", "\"" & words.join("\", \"") & "\"")
        .replace("$PATHWORDS", words.join(" "))
        .replace("$UNDERSCORED", words.join("_"))
        .replace("$LEAF", leaf)
        .replace("\"\"\\\"", "\"\"\"")

  createDir(subdir / "tests")
  writeFile(module, fill(commandTemplate, libFromModule))
  writeFile(test, fill(testTemplate, libFromTest))
  outp.writeLine("Created " & module)
  outp.writeLine("Created " & test)

  if seeded:
    writeFile(groupsFile, groupsText)
    outp.writeLine("Seeded groups.json — replace the TODO summary")
  0

proc completionZsh*(specs: seq[CommandSpec],
                    groups: OrderedTable[string, string]): string
proc completionBash*(specs: seq[CommandSpec],
                     groups: OrderedTable[string, string]): string
proc completionNu*(specs: seq[CommandSpec],
                   groups: OrderedTable[string, string]): string

proc selfCmd*(words: seq[string], ctx: Ctx, libexecDir, registryFile,
              groupsFile: string, help: bool = false,
              runner: Runner = defaultRunner, outp: File = stdout,
              errp: File = stderr, commandsDir: string = ""): int =
  ## Help is handled before loading metadata, checking arity or executing
  ## maintenance. The explicit context also governs status and rendering.
  exportCtx(ctx)
  let usage = selfHelpText(words)
  if help:
    if usage.len == 0:
      error("unknown self command: " & words[0], errp)
      return 64
    return renderHelp(usage, runner, outp, errp)
  if words.len == 0:
    error(usage.strip(), errp)
    return 64
  if usage.len == 0:
    error("unknown self command: " & words[0], errp)
    return 64
  if words[0] != "new-command" and
     words.len != (if words[0] == "completion": 2 else: 1):
    error(usage.strip(), errp)
    return 64
  case words[0]
  of "build-registry":
    buildRegistry(libexecDir, runner, outp, errp)
  of "completion":
    if words[1] notin ["zsh", "bash", "nu"]:
      error(usage.strip(), errp)
      return 64
    let specs = loadRegistry(registryFile)
    let groups = loadGroups(groupsFile)
    case words[1]
    of "zsh": outp.write(completionZsh(specs, groups))
    of "bash": outp.write(completionBash(specs, groups))
    else: outp.write(completionNu(specs, groups))
    0
  of "commands":
    selfCommands(loadRegistry(registryFile),
                 listZshFunctions(getHomeDir() / ".zsh" / "functions"),
                 ctx, runner, outp, errp)
  of "doctor":
    selfDoctor(loadRegistry(registryFile), runner, outp, errp)
  of "new-command":
    let dir = if commandsDir.len > 0: commandsDir
              else: getCurrentDir() / "files" / "nim" / "commands"
    newCommand(words[1 .. ^1], dir, outp, errp, dryRun = ctx.dryRun)
  else:
    64

# ---------------------------------------------------------------- completion

proc zqEscape(s: string): string =
  ## Escapes a summary for use inside a zsh completion 'name:desc' pair.
  s.replace("\\", "\\\\").replace("'", "''").replace(":", "\\:")

proc describeBlock(tag: string, pairs: seq[(string, string)],
                   indent: string): string =
  result = indent & "reply=(\n"
  for (name, desc) in pairs:
    result.add indent & "  '" & name & ":" & zqEscape(desc) & "'\n"
  result.add indent & ")\n"
  result.add indent & "_describe -t commands '" & tag & "' reply\n"

proc flagSpecsFor(s: CommandSpec): string =
  for f in s.flags:
    let name =
      if f.long.len > 0: "--" & f.long
      elif f.short.len > 0: "-" & f.short
      else: continue
    var entry = "'" & name & "[" & zqEscape(f.description) & "]"
    if f.takesValue:
      entry.add ":value:"
    entry.add "'"
    result.add " " & entry

proc completionZsh*(specs: seq[CommandSpec],
                    groups: OrderedTable[string, string]): string =
  ## Generates the _ax completion function from the registry: group and
  ## subgroup words at positions 2-3, leaves and per-command long flags
  ## after that, files as the positional fallback.
  let paths = registryPaths(specs)

  proc summaryFor(path: seq[string]): string =
    for s in specs:
      if s.path == path:
        return s.summary
    groups.getOrDefault(path.join(" "), "")

  proc childPairs(prefix: seq[string]): seq[(string, string)] =
    for c in childrenOf(paths, prefix):
      result.add (c, summaryFor(prefix & c))

  result = "#compdef ax\n" &
           "# Generated by `ax self completion zsh` — do not edit.\n\n" &
           "_ax() {\n" &
           "  local -a reply\n" &
           "  local g=\"${words[2]}\" s=\"${words[3]}\"\n" &
           "  case $CURRENT in\n" &
           "    2)\n"
  var top: seq[(string, string)]
  for (c, d) in childPairs(@[]):
    top.add (c, d)
  top.add ("help", "show help")
  top.add ("version", "print the ax version")
  top.add ("self", "toolbelt maintenance")
  result.add describeBlock("ax command", top, "      ")
  result.add "      ;;\n    3)\n      case $g in\n"
  for group in childrenOf(paths, @[]):
    result.add "        " & group & ")\n"
    result.add describeBlock("ax " & group & " command",
                             childPairs(@[group]), "          ")
    result.add "          ;;\n"
  result.add "        help)\n"
  result.add describeBlock("ax help topic", childPairs(@[]), "          ")
  result.add "          ;;\n"
  result.add "        self)\n"
  result.add describeBlock("ax self command", @[
    ("commands", "list every ax command and surviving zsh function"),
    ("completion", "emit a completion script (zsh, bash, nu)"),
    ("doctor", "audit declared dependencies against $PATH"),
    ("new-command", "scaffold a new command module and test"),
    ("build-registry", "regenerate the registry from built binaries")
  ], "          ")
  result.add "          ;;\n        *) _files ;;\n      esac\n      ;;\n"
  result.add "    *)\n      case \"$g $s\" in\n"
  for s in specs:
    if s.path.len == 2:
      result.add "        '" & s.path.join(" ") & "')\n" &
                 "          _arguments" & flagSpecsFor(s) &
                 " '*:file:_files'\n          ;;\n"
  var subgroups: seq[seq[string]]
  for p in paths:
    if p.len == 3 and p[0 .. 1] notin subgroups:
      subgroups.add p[0 .. 1]
  for sub in subgroups:
    result.add "        '" & sub.join(" ") & "')\n" &
               "          if (( CURRENT == 4 )); then\n"
    result.add describeBlock("ax " & sub.join(" ") & " command",
                             childPairs(sub), "            ")
    result.add "          else\n            case \"${words[4]}\" in\n"
    for s in specs:
      if s.path.len == 3 and s.path[0 .. 1] == sub:
        result.add "              " & s.path[2] & ")\n" &
                   "                _arguments" & flagSpecsFor(s) &
                   " '*:file:_files'\n                ;;\n"
    result.add "              *) _files ;;\n            esac\n" &
               "          fi\n          ;;\n"
  result.add "        *) _files ;;\n      esac\n      ;;\n" &
             "  esac\n}\n\n_ax \"$@\"\n"

proc completionBash*(specs: seq[CommandSpec],
                     groups: OrderedTable[string, string]): string =
  ## Word completion by depth: groups at position 1, children at 2-3,
  ## long flags after a resolved command. No descriptions — bash's
  ## compgen -W has nowhere to put them.
  let paths = registryPaths(specs)

  proc children(prefix: seq[string]): string =
    childrenOf(paths, prefix).join(" ")

  proc flagsFor(path: seq[string]): string =
    for s in specs:
      if s.path == path:
        var names: seq[string]
        for f in s.flags:
          if f.long.len > 0: names.add "--" & f.long
          elif f.short.len > 0: names.add "-" & f.short
        return names.join(" ")
    ""

  result = "# Generated by `ax self completion bash` — do not edit.\n\n" &
           "_ax_complete() {\n" &
           "  local cur=\"${COMP_WORDS[COMP_CWORD]}\"\n" &
           "  local w1=\"${COMP_WORDS[1]}\" w2=\"${COMP_WORDS[2]}\" w3=\"${COMP_WORDS[3]}\"\n" &
           "  COMPREPLY=()\n" &
           "  case $COMP_CWORD in\n" &
           "    1)\n" &
           "      COMPREPLY=($(compgen -W \"" & children(@[]) &
           " help version self\" -- \"$cur\")) ;;\n" &
           "    2)\n      case \"$w1\" in\n"
  for group in childrenOf(paths, @[]):
    result.add "        " & group & ") COMPREPLY=($(compgen -W \"" &
               children(@[group]) & "\" -- \"$cur\")) ;;\n"
  result.add "        help) COMPREPLY=($(compgen -W \"" & children(@[]) &
             "\" -- \"$cur\")) ;;\n"
  result.add "        self) COMPREPLY=($(compgen -W \"commands completion " &
             "doctor new-command build-registry\" -- \"$cur\")) ;;\n"
  result.add "      esac ;;\n    *)\n      case \"$w1 $w2\" in\n"
  var twoWord: seq[seq[string]]
  var subgroups: seq[seq[string]]
  for p in paths:
    if p.len == 2 and p notin twoWord: twoWord.add p
    if p.len == 3 and p[0 .. 1] notin subgroups: subgroups.add p[0 .. 1]
  for p in twoWord:
    result.add "        '" & p.join(" ") & "') COMPREPLY=($(compgen -W \"" &
               flagsFor(p) & "\" -- \"$cur\")) ;;\n"
  for sub in subgroups:
    result.add "        '" & sub.join(" ") & "')\n" &
               "          if (( COMP_CWORD == 3 )); then\n" &
               "            COMPREPLY=($(compgen -W \"" & children(sub) &
               "\" -- \"$cur\"))\n          else\n            case \"$w3\" in\n"
    for s in specs:
      if s.path.len == 3 and s.path[0 .. 1] == sub:
        result.add "              " & s.path[2] &
                   ") COMPREPLY=($(compgen -W \"" & flagsFor(s.path) &
                   "\" -- \"$cur\")) ;;\n"
    result.add "            esac\n          fi ;;\n"
  result.add "      esac ;;\n  esac\n}\n\ncomplete -o default -F _ax_complete ax\n"

proc nuFlagLines(s: CommandSpec): string =
  for f in s.flags:
    if f.long.len == 0: continue
    result.add "  --" & f.long
    if f.takesValue:
      result.add ": string"
    if f.description.len > 0:
      result.add "  # " & f.description
    result.add "\n"

proc completionNu*(specs: seq[CommandSpec],
                   groups: OrderedTable[string, string]): string =
  ## `export extern` declarations: nushell derives subcommand and flag
  ## completion from the extern signatures themselves.
  result = "# Generated by `ax self completion nu` — do not edit.\n\n" &
           "export extern \"ax\" [command?: string]\n"
  for s in specs:
    result.add "\n# " & s.summary & "\nexport extern \"ax " &
               s.path.join(" ") & "\" [\n  ...args\n" & nuFlagLines(s) & "]\n"
