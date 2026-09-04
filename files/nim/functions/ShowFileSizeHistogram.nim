import std/[os, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"
import "../lib/fdscan"

type ParsedArgs* = object
  extensions*: seq[string]
  allFlag*: bool
  directory*: string
  unknownOption*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  var i = 0
  while i < args.len:
    let arg = args[i]
    case arg
    of "--all": result.allFlag = true
    of "-e":
      inc i
      if i < args.len: result.extensions.add(args[i])
      else: result.extensions.add("")
    else:
      if arg.len > 0 and arg[0] == '-':
        result.unknownOption = arg
        return result
      else:
        result.directory = arg
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
    outp.writeLine """Usage: Show-FileSizeHistogram [opts] [directory]

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
    Show-FileSizeHistogram
    Show-FileSizeHistogram ~/projects
    Show-FileSizeHistogram -e jpg -e png
    Show-FileSizeHistogram --all"""
    return 0

  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 1

  let dir = if parsed.directory.len > 0: parsed.directory else: "."
  if not requireDir(dir, errp): return 1
  if not checkDeps(["fd"], errp): return 2

  let files = findFiles(runner, dir, parsed.extensions, parsed.allFlag)

  var binCounts = newSeq[int](binLabels.len)
  var totalFiles = 0
  var totalBytes = 0

  for file in files:
    var size: BiggestInt
    try:
      size = getFileSize(file)
    except OSError:
      continue
    inc totalFiles
    totalBytes += size.int
    inc binCounts[binIndex(size.int)]

  if totalFiles == 0:
    warn("No files found in '" & dir & "'", errp)
    return 0

  var maxCount = 0
  for c in binCounts:
    if c > maxCount: maxCount = c

  const barWidth = 30
  var lines: seq[string] = @[]
  for i in 0 ..< binLabels.len:
    let count = binCounts[i]
    let barLen = if maxCount > 0: count * barWidth div maxCount else: 0
    let bar = "█".repeat(barLen) & " ".repeat(barWidth - barLen)
    lines.add(binLabels[i] & "|" & bar & "|" & $count)

  outp.writeLine("")
  info($totalFiles & " files, " & formatSizeLabel(totalBytes), errp)
  outp.writeLine("")
  discard table("Range|Distribution|Files\n" & lines.join("\n"), false, runner,
                outp, errp)
  outp.writeLine("")
  return 0

when isMainModule:
  cliMain(run(commandLineParams()))
