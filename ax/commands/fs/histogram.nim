import std/[os, strutils]
import "../../lib/context"
import "../../lib/fdscan"
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["fs", "histogram"],
  kind: ckReport,
  summary: "histogram of file sizes in a directory tree",
  usage: "ax fs histogram [-e ext] [--all] [dir]",
  args: @[
    ArgSpec(name: "dir", required: false,
            description: "target directory (default: current directory)")
  ],
  flags: @[
    FlagSpec(long: "", short: "e", takesValue: true,
             description: "only count files with this extension (repeatable)"),
    FlagSpec(long: "all", takesValue: false,
             description: "include hidden files and ignored files")
  ],
  deps: @["fd"],
  dryRun: false
)

type ParsedArgs* = object
  extensions*: seq[string]
  allFlag*: bool
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
    of "-e":
      if value.strip().len == 0 or (not attachedValue and value.startsWith("-")):
        result.unknownOption = "-e requires a nonempty extension"
        return
      result.extensions.add(value)
    else:
      result.unknownOption = arg
      return
    inc i

const binLimits = [1024, 10240, 102400, 1048576, 10485760, 104857600, 1073741824]
const binLabels = [
  "   0B -   1KB", "  1KB -  10KB", " 10KB - 100KB", "100KB -   1MB",
  "  1MB -  10MB", " 10MB - 100MB", "100MB -   1GB", "  1GB+       "
]

proc binIndex*(size: int): int =
  ## Returns which of the 8 histogram bins `size` falls into: the first
  ## bin whose upper limit `size` is strictly less than, or the last
  ## (overflow, ">= 1GB") bin if none match.
  for i, limit in binLimits:
    if size < limit: return i
  binLabels.len - 1

proc formatSizeLabel*(totalBytes: int): string =
  ## Mirrors the zsh original's GB/MB/KB/B branching with one decimal place.
  if totalBytes >= 1073741824:
    formatFloat(totalBytes.float / 1073741824.0, ffDecimal, 1) & " GB"
  elif totalBytes >= 1048576:
    formatFloat(totalBytes.float / 1048576.0, ffDecimal, 1) & " MB"
  elif totalBytes >= 1024:
    formatFloat(totalBytes.float / 1024.0, ffDecimal, 1) & " KB"
  else:
    $totalBytes & " B"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax fs histogram [opts] [directory]

Display a histogram of file sizes in a directory tree.
Uses logarithmic bins (powers of 10) by default for a natural
distribution view. Uses fd to discover files (respects .gitignore).

Options:
    -e ext      Only count files with this extension (repeatable)
    --all       Include hidden files and ignored files
    -h, --help  Show this help message

Arguments:
    directory   Target directory (default: current directory)

Examples:
    ax fs histogram
    ax fs histogram ~/projects
    ax fs histogram -e jpg -e png
    ax fs histogram --all"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 64

  let dir = if parsed.directory.len > 0: parsed.directory else: "."
  if not requireDir(dir, errp): return 1
  if not checkDeps(["fd"], errp): return 2

  var files: seq[string]
  try:
    files = findFiles(runner, dir, parsed.extensions, parsed.allFlag)
  except CatchableError as e:
    error(e.msg, errp)
    return 1

  var binCounts = newSeq[int](binLabels.len)
  var totalFiles = 0
  var totalBytes = 0

  for file in files:
    var size: BiggestInt
    try:
      size = getFileSize(file)
    except OSError as e:
      error("Cannot stat '" & file & "': " & e.msg, errp)
      return 1
    inc totalFiles
    totalBytes += size.int
    inc binCounts[binIndex(size.int)]

  if totalFiles == 0:
    warn("No files found in '" & dir & "'", errp)
    if ctxFromEnv().output != omJson: return 0
    return render(@["Range", "Distribution", "Files"], @[], ctxFromEnv(), runner, outp, errp)

  var maxCount = 0
  for c in binCounts:
    if c > maxCount: maxCount = c

  const barWidth = 30
  var rows: seq[seq[string]] = @[]
  for i in 0 ..< binLabels.len:
    let count = binCounts[i]
    let barLen = if maxCount > 0: count * barWidth div maxCount else: 0
    let bar = "█".repeat(barLen) & " ".repeat(barWidth - barLen)
    rows.add @[binLabels[i], bar, $count]

  let ctx = ctxFromEnv()
  if ctx.output == omTable:
    outp.writeLine("")
  info($totalFiles & " files, " & formatSizeLabel(totalBytes), errp)
  if ctx.output == omTable:
    outp.writeLine("")
  let renderCode = render(@["Range", "Distribution", "Files"], rows, ctx,
                          runner, outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return renderCode

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
