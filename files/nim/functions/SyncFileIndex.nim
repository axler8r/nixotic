import std/[os, tables, sets, algorithm, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/validation"

const selfName = "Sync-FileIndex"

proc matchesGlob(name, pattern: string): bool =
  if pattern.len == 0: return false
  let parts = pattern.split('*')
  if parts.len == 1:
    return name == pattern
  var pos = 0
  if parts[0].len > 0:
    if not name.startsWith(parts[0]): return false
    pos = parts[0].len
  for i in 1 ..< parts.len - 1:
    if parts[i].len == 0: continue
    let idx = name.find(parts[i], pos)
    if idx < 0: return false
    pos = idx + parts[i].len
  let last = parts[^1]
  if last.len > 0:
    if not name.endsWith(last): return false
    if pos > name.len - last.len: return false
  true

proc isExcluded(name: string, excludeGlobs: seq[string]): bool =
  if name == selfName: return true
  for pat in excludeGlobs:
    if matchesGlob(name, pat): return true
  false

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Sync-FileIndex [-f INDEX_FILE] [--dry-run] [DIRECTORY]

Reconcile a tickmark index file with actual directory contents.
New files are appended with an empty mark; deleted files are removed.
Existing marks are preserved.

Options:
    -f, --file INDEX_FILE  Index file to reconcile (default: _TRACK in DIRECTORY)
    --dry-run              Show what would be added or removed without writing changes
    -h, --help             Show this help message

Arguments:
    DIRECTORY              Directory to scan (default: directory containing INDEX_FILE)

Environment:
    TRACK_EXCLUDE_GLOB     Colon-separated filename globs to exclude (e.g. "*.sh:reconcile-*")

Examples:
    Sync-FileIndex
    Sync-FileIndex /path/to/dir
    Sync-FileIndex -f /path/to/_TRACK
    Sync-FileIndex --dry-run
    TRACK_EXCLUDE_GLOB="*.sh" Sync-FileIndex"""
    return 0

  var trackFile = ""
  var dir = ""
  var dryRun = false
  var i = 0
  while i < args.len:
    let arg = args[i]
    if arg == "--dry-run":
      dryRun = true
      inc i
    elif arg == "-f" or arg == "--file":
      if i + 1 >= args.len:
        error("Missing value for " & arg, errp)
        return 1
      trackFile = args[i + 1]
      i += 2
    elif arg.len > 2 and arg[0] == '-' and arg[1] == 'f':
      trackFile = arg[2 .. ^1]
      inc i
    else:
      dir = arg
      inc i

  if trackFile.len == 0:
    trackFile = (if dir.len > 0: dir else: ".") / "_TRACK"
  trackFile = normalizedPath(absolutePath(trackFile))
  if dir.len == 0:
    dir = parentDir(trackFile)

  if not requireFile(trackFile, errp): return 1

  var excludeGlobs: seq[string] = @[]
  let excludeEnv = getEnv("TRACK_EXCLUDE_GLOB")
  if excludeEnv.len > 0:
    excludeGlobs = excludeEnv.split(':')

  var marks = initTable[string, string]()
  var order: seq[string] = @[]
  for line in lines(trackFile):
    if line.len > 4 and line[0] == '[' and line[2] == ']' and line[3] == ' ':
      let mark = $line[1]
      let fname = line[4 .. ^1]
      marks[fname] = mark
      order.add(fname)

  let trackBase = extractFilename(trackFile)
  var onDisk = initHashSet[string]()
  for kind, path in walkDir(dir):
    if kind != pcFile: continue
    let bname = extractFilename(path)
    if bname == trackBase: continue
    if isExcluded(bname, excludeGlobs): continue
    onDisk.incl(bname)

  var added: seq[string] = @[]
  for fname in onDisk:
    if not marks.hasKey(fname):
      added.add(fname)
  added.sort()

  var removed: seq[string] = @[]
  for fname in order:
    if not onDisk.contains(fname):
      removed.add(fname)
  removed.sort()

  if added.len == 0 and removed.len == 0:
    success("'" & trackBase & "' is already in sync.", errp)
    return 0

  if added.len > 0:
    info("adding   (" & $added.len & "): " & added.join(", "), errp)
  if removed.len > 0:
    info("removing (" & $removed.len & "): " & removed.join(", "), errp)

  if dryRun: return 0

  var outLines: seq[string] = @[]
  for fname in order:
    if onDisk.contains(fname):
      outLines.add("[" & marks[fname] & "] " & fname)
  for fname in added:
    outLines.add("[ ] " & fname)
  outLines.sort()

  try:
    writeFile(trackFile, outLines.join("\n") & "\n")
  except IOError, OSError:
    error("Cannot write '" & trackFile & "': " & getCurrentExceptionMsg(), errp)
    return 1
  success("'" & trackBase & "' reconciled.", errp)
  0

when isMainModule:
  cliMain(run(commandLineParams()))
