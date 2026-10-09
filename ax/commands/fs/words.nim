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
  usage: "ax fs words [-e ext] [--top count] [--all] [dir]",
  args: @[
    ArgSpec(name: "dir", required: false,
            description: "target directory (default: current directory)")
  ],
  flags: @[
    FlagSpec(long: "", short: "e", takesValue: true,
             description: "only count files with this extension (repeatable)"),
    FlagSpec(long: "top", takesValue: true,
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
  var positionalOnly = false
  var hasDirectory = false
  var i = 0
  while i < args.len:
    var arg = args[i]
    var value = ""
    var attachedValue = false
    if not positionalOnly and arg == "--":
      positionalOnly = true
      inc i
      continue
    if positionalOnly or arg == "-" or not arg.startsWith("-"):
      if hasDirectory:
        result.unknownOption = "extra directory: " & arg
        return
      result.directory = arg
      hasDirectory = true
      inc i
      continue
    if arg.startsWith("--top="):
      value = arg[6 .. ^1]
      arg = "--top"
    elif arg.startsWith("-e") and arg.len > 2:
      attachedValue = true
      value = arg[2 .. ^1]
      if value[0] in {'=', ':'}: value = value[1 .. ^1]
      arg = "-e"
    elif arg in ["-e", "--top"]:
      inc i
      if i < args.len: value = args[i]
    case arg
    of "--all": result.allFlag = true
    of "--raw": result.raw = true
    of "-e":
      if value.strip().len == 0 or (not attachedValue and value.startsWith("-")):
        result.unknownOption = "-e requires a nonempty extension"
        return
      result.extensions.add(value)
    of "--top":
      if value.len == 0 or not value.allCharsInSet({'0'..'9'}):
        result.unknownOption = "--top requires a positive integer"
        return
      try:
        result.topN = parseInt(value)
      except ValueError:
        result.topN = 0
      if result.topN <= 0:
        result.unknownOption = "--top requires a positive integer"
        return
    else:
      result.unknownOption = arg
      return
    inc i

proc extractExtension*(path: string): string =
  ## Mirrors the zsh original's `${file:e}`: the text after the last "." in
  ## the basename, "" if there isn't one.
  let ext = splitFile(path).ext
  if ext.len > 0: ext[1 .. ^1] else: ""

proc countWords*(path: string): int =
  ## Mirrors `wc -w < "$file"`: the number of whitespace-separated tokens.
  ## Iterate lines and tokens rather than allocating a whole-file token list.
  for line in lines(path):
    for word in line.splitWhitespace():
      inc result

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
    --top count Show top N extensions (default: 15)
    --all       Include hidden files and ignored files
    --raw       Display results as raw output (no formatting)
    -h, --help  Show this help message

Arguments:
    directory   Target directory (default: current directory)

Examples:
    ax fs words
    ax fs words ~/projects/docs
    ax fs words -e md -e txt
    ax fs words --top 5
    ax fs words --all"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 64

  let dir = if parsed.directory.len > 0: parsed.directory else: "."
  if not requireDir(dir, errp): return 1
  if not checkDeps(["fd", "file"], errp): return 2

  var ctx = ctxFromEnv()
  if parsed.raw: ctx.output = omPlain
  var files: seq[string]
  try:
    files = findFiles(runner, dir, parsed.extensions, parsed.allFlag)
  except CatchableError as e:
    error(e.msg, errp)
    return 1
  if files.len == 0:
    warn("No text files found in '" & dir & "'", errp)
    if ctx.output != omJson: return 0
    return render(@["Extension", "Words", "Files", "Share"], @[], ctx, runner, outp, errp)

  var extWords = initTable[string, int]()
  var extFiles = initTable[string, int]()
  var totalWords = 0
  var totalFiles = 0

  for file in files:
    var words: int
    try:
      let mime = mimeType(runner, file)
      if not isTextMimeType(mime): continue
      words = countWords(file)
    except CatchableError as e:
      error("Cannot count '" & file & "': " & e.msg, errp)
      return 1

    var ext = extractExtension(file)
    if ext.len == 0: ext = "(no ext)"

    extWords[ext] = extWords.getOrDefault(ext, 0) + words
    extFiles[ext] = extFiles.getOrDefault(ext, 0) + 1
    totalWords += words
    inc totalFiles

  if totalWords == 0:
    warn("No words found in '" & dir & "'", errp)
    if ctx.output != omJson: return 0
    return render(@["Extension", "Words", "Files", "Share"], @[], ctx, runner, outp, errp)

  var extList: seq[string] = @[]
  for ext in extWords.keys:
    extList.add(ext)
  extList.sort(proc(a, b: string): int =
    let byCount = cmp(extWords[b], extWords[a])
    if byCount != 0: byCount else: cmp(a, b))

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
  let renderCode = render(@["Extension", "Words", "Files", "Share"], rows, ctx,
                          runner, outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return renderCode

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
