import std/[os, strutils]
import "../../../lib/context"
import "../../../lib/fdscan"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["fs", "indent", "check"],
  kind: ckVerb,
  summary: "find files mixing tab and space indentation",
  usage: "ax fs indent check [-e ext] [--all] [dir]",
  args: @[
    ArgSpec(name: "dir", required: false,
            description: "target directory (default: current directory)")
  ],
  flags: @[
    FlagSpec(long: "", short: "e", takesValue: true,
             description: "only check files with this extension (repeatable)"),
    FlagSpec(long: "all", takesValue: false,
             description: "include hidden files and ignored files")
  ],
  deps: @["fd", "file"],
  dryRun: false
)

type ParsedArgs* = object
  extensions*: seq[string]
  allFlag*: bool
  raw*: bool
  directory*: string
  unknownOption*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
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
    if arg.startsWith("-e") and arg.len > 2:
      attachedValue = true
      value = arg[2 .. ^1]
      if value[0] in {'=', ':'}: value = value[1 .. ^1]
      arg = "-e"
    elif arg == "-e":
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
    else:
      result.unknownOption = arg
      return
    inc i

proc countTabSpaceLines*(path: string): tuple[tabLines, spaceLines: int] =
  ## Mirrors `grep -cP '^\t'` and `grep -cP '^ '`: a line's first character
  ## is tab, space, or neither, so a single pass suffices.
  result = (0, 0)
  let content = readFile(path)
  for line in content.splitLines():
    if line.len == 0: continue
    if line[0] == '\t': inc result.tabLines
    elif line[0] == ' ': inc result.spaceLines

proc stripDirPrefix*(file, dir: string): string =
  ## Mirrors `${file#${dir%/}/}`: strips `dir` (with any trailing slash
  ## removed) plus one "/" from the start of `file`, if present.
  var d = dir
  if d.len > 1 and d.endsWith("/"): d = d[0 .. ^2]
  let prefix = d & "/"
  if file.startsWith(prefix):
    file[prefix.len .. ^1]
  else:
    file

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax fs indent check [opts] [directory]

Find files that use both tabs and spaces for indentation.
Files using only tabs or only spaces are fine — only mixed
indentation is reported. Uses fd to discover files (respects
.gitignore) and native detection.

Options:
    -e ext      Only check files with this extension (repeatable)
    --all       Include hidden files and ignored files
    --raw       Display results as raw output (no formatting)
    -h, --help  Show this help message

Arguments:
    directory   Target directory (default: current directory)

Examples:
    ax fs indent check
    ax fs indent check ~/projects
    ax fs indent check -e py -e js
    ax fs indent check --all"""
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
    info("No files found in '" & dir & "'", errp)
    if ctx.output != omJson: return 0
    return render(@["File", "Tabs", "Spaces"], @[], ctx, runner, outp, errp)

  var mixed = 0
  var checked = 0
  var skipped = 0
  var results: seq[tuple[tabLines, spaceLines: int, relPath: string]] = @[]

  for file in files:
    var counts: tuple[tabLines, spaceLines: int]
    try:
      let mime = mimeType(runner, file)
      if not isTextMimeType(mime) or getFileSize(file) == 0:
        inc skipped
        continue
      counts = countTabSpaceLines(file)
      inc checked
    except CatchableError as e:
      error("Cannot inspect '" & file & "': " & e.msg, errp)
      return 1
    if counts.tabLines > 0 and counts.spaceLines > 0:
      inc mixed
      results.add((counts.tabLines, counts.spaceLines, stripDirPrefix(file, dir)))

  if mixed == 0:
    success("No mixed indentation found (" & $checked & " files checked, " &
            $skipped & " skipped)", errp)
    if ctx.output != omJson: return 0
    return render(@["File", "Tabs", "Spaces"], @[], ctx, runner, outp, errp)

  var rows: seq[seq[string]] = @[]
  for r in results:
    rows.add @[r.relPath, insertSep($r.tabLines, ','),
               insertSep($r.spaceLines, ',')]

  if ctx.output == omTable:
    outp.writeLine("")
  let renderCode = render(@["File", "Tabs", "Spaces"], rows, ctx, runner, outp, errp)
  if renderCode != 0: return renderCode
  if ctx.output == omTable:
    outp.writeLine("")
  warn($mixed & " file(s) with mixed indentation (" & $checked &
       " checked, " & $skipped & " skipped)", errp)

  return 1

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
