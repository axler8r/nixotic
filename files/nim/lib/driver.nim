## Driver logic for ax: cross-cutting flag extraction, command-path
## resolution against the registry, help text, registry generation, and
## completion generation. Everything here is pure or stream-injected so
## lib/tests can exercise it; ax.nim is the thin main that wires this to
## the real filesystem, environment, and exec.
import std/[algorithm, json, os, sequtils, strutils, tables, terminal]
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

proc loadRegistry*(file: string): seq[CommandSpec] =
  for n in parseJson(readFile(file)):
    result.add commandSpecFromJson(n)

proc registryPaths*(specs: seq[CommandSpec]): seq[seq[string]] =
  specs.mapIt(it.path)

proc loadGroups*(file: string): OrderedTable[string, string] =
  ## groups.json: space-joined group path -> one-line summary. JsonNode
  ## objects preserve insertion order, so the file's order is the display
  ## order.
  for k, v in parseJson(readFile(file)):
    result[k] = v.getStr

# ------------------------------------------------------------------ building

proc buildRegistry*(libexecDir: string, runner: Runner = defaultRunner,
                    outp: File = stdout, errp: File = stderr): int =
  ## `ax self build-registry`: exec every libexec/ax/ax-* with --ax-spec,
  ## validate each answer against the lexicon and its own binary name, and
  ## emit the sorted registry JSON on stdout. Any failure is fatal — this
  ## runs inside the package build, so a bad spec fails the build.
  var names: seq[string]
  for kind, path in walkDir(libexecDir):
    let name = extractFilename(path)
    if name.startsWith("ax-"):
      names.add name
  names.sort()

  var arr = newJArray()
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
    except CatchableError as e:
      error(name & " --ax-spec is not a valid spec: " & e.msg, errp)
      return 1
    if cmdSpec.specVersion != specVersionCurrent:
      error(name & ": unsupported specVersion " & $cmdSpec.specVersion, errp)
      return 1
    if cmdSpec.path.len < 2 or cmdSpec.path.len > 3:
      error(name & ": path depth must be 2 or 3, got " &
            $cmdSpec.path.len, errp)
      return 1
    if "ax-" & cmdSpec.path.join("-") != name:
      error(name & ": spec path '" & cmdSpec.path.join(" ") &
            "' does not match the binary name", errp)
      return 1
    if not isAllowedLeaf(cmdSpec.path[^1]):
      error(name & ": leaf '" & cmdSpec.path[^1] &
            "' is not a lexicon verb or report-noun", errp)
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
