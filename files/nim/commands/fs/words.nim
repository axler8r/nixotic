import std/[os, algorithm, strutils, tables]
import "../../lib/context"
import "../../lib/fdscan"
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["fs", "words"],
  kind: ckReport,
  summary: "count words across text files, per extension",
  usage: "ax fs words [-e ext] [-n count] [--all] [dir]",
  args: @[
    ArgSpec(name: "dir", required: false,
            description: "target directory (default: current directory)")
  ],
  flags: @[
    FlagSpec(long: "", short: "e", takesValue: true,
             description: "only count files with this extension (repeatable)"),
    FlagSpec(long: "", short: "n", takesValue: true,
             description: "show top N extensions (default: 15)"),
    FlagSpec(long: "all", takesValue: false,
             description: "include hidden files and ignored files")
  ],
  deps: @["fd", "file"],
  dryRun: false
)

type ParsedArgs* = object
  extensions*: seq[string]
  topN*: int
  allFlag*: bool
  raw*: bool
  directory*: string
  unknownOption*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  result.topN = 15
  var i = 0
  while i < args.len:
    let arg = args[i]
    case arg
    of "--all": result.allFlag = true
    of "--raw": result.raw = true
    of "-e":
      inc i
      if i < args.len: result.extensions.add(args[i])
      else: result.extensions.add("")
    of "-n":
      inc i
      if i < args.len:
        try:
          result.topN = parseInt(args[i])
        except ValueError:
          discard
    else:
      if arg.len > 0 and arg[0] == '-':
        result.unknownOption = arg
        return result
      else:
        result.directory = arg
    inc i

proc extractExtension*(path: string): string =
  ## Mirrors the zsh original's `${file:e}`: the text after the last "." in
  ## the basename, "" if there isn't one.
  let ext = splitFile(path).ext
  if ext.len > 0: ext[1 .. ^1] else: ""

proc countWords*(path: string): int =
  ## Mirrors `wc -w < "$file"`: the number of whitespace-separated tokens.
  var content: string
  try:
    content = readFile(path)
  except IOError, OSError:
    return 0
  content.splitWhitespace().len

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax fs words [opts] [directory]

Count words across all text files in a directory tree.
Uses fd to discover files (respects .gitignore) and native word counting.
Results are displayed as a table with per-extension breakdown.

Options:
    -e ext      Only count files with this extension (repeatable)
    -n count    Show top N extensions (default: 15)
    --all       Include hidden files and ignored files
    --raw       Display results as raw output (no formatting)
    -h, --help  Show this help message

Arguments:
    directory   Target directory (default: current directory)

Examples:
    ax fs words
    ax fs words ~/projects/docs
    ax fs words -e md -e txt
    ax fs words -n 5
    ax fs words --all"""
    return 0

  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 64

  let dir = if parsed.directory.len > 0: parsed.directory else: "."
  if not requireDir(dir, errp): return 1
  if not checkDeps(["fd", "file"], errp): return 2

  let files = findFiles(runner, dir, parsed.extensions, parsed.allFlag)
  if files.len == 0:
    warn("No text files found in '" & dir & "'", errp)
    return 0

  var extWords = initTable[string, int]()
  var extFiles = initTable[string, int]()
  var totalWords = 0
  var totalFiles = 0

  for file in files:
    let mime = mimeType(runner, file)
    if not isTextMimeType(mime): continue

    var ext = extractExtension(file)
    if ext.len == 0: ext = "(no ext)"

    let words = countWords(file)
    extWords[ext] = extWords.getOrDefault(ext, 0) + words
    extFiles[ext] = extFiles.getOrDefault(ext, 0) + 1
    totalWords += words
    inc totalFiles

  if totalWords == 0:
    warn("No words found in '" & dir & "'", errp)
    return 0

  var extList: seq[string] = @[]
  for ext in extWords.keys:
    extList.add(ext)
  extList.sort(proc(a, b: string): int =
    let byCount = cmp(extWords[b], extWords[a])
    if byCount != 0: byCount else: cmp(a, b))

  var ctx = ctxFromEnv()
  if parsed.raw:
    ctx.output = omPlain
  var rows: seq[seq[string]] = @[]
  var shown = 0
  for ext in extList:
    if shown >= parsed.topN: break
    let words = extWords[ext]
    let pct = words * 100 div totalWords
    rows.add @["." & ext, insertSep($words, ','), $extFiles[ext], $pct & "%"]
    inc shown

  rows.add @["Total", insertSep($totalWords, ','), $totalFiles, "100%"]

  if ctx.output == omTable:
    outp.writeLine("")
  discard render(@["Extension", "Words", "Files", "Share"], rows, ctx, runner,
                 outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return 0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
