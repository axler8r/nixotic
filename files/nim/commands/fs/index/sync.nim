import std/[os, tables, sets, algorithm, strutils, tempfiles]
import "../../../lib/context"
import "../../../lib/output"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["fs", "index", "sync"],
  kind: ckVerb,
  summary: "reconcile a tickmark index file with directory contents",
  usage: "ax fs index sync [-f INDEX_FILE] [-n] [dir]",
  args: @[
    ArgSpec(name: "dir", required: false,
            description: "directory to scan (default: the index file's directory)")
  ],
  flags: @[
    FlagSpec(long: "file", short: "f", takesValue: true,
             description: "index file to reconcile (default: _TRACK in dir)")
  ],
  dryRun: true
)

const selfName = "ax-fs-index-sync"

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
    outp.writeLine """Usage: ax fs index sync [-f INDEX_FILE] [-n] [DIRECTORY]

Reconcile a tickmark index file with actual directory contents.
New files are appended with an empty mark; deleted files are removed.
Existing marks are preserved.

Options:
    -f, --file INDEX_FILE  Index file to reconcile (default: _TRACK in DIRECTORY)
    -n, --dry-run          Show what would be added or removed without writing changes
    -h, --help             Show this help message

Arguments:
    DIRECTORY              Directory to scan (default: directory containing INDEX_FILE)

Environment:
    TRACK_EXCLUDE_GLOB     Colon-separated filename globs to exclude (e.g. "*.sh:reconcile-*")

Examples:
    ax fs index sync
    ax fs index sync /path/to/dir
    ax fs index sync -f /path/to/_TRACK
    ax fs index sync -n
    TRACK_EXCLUDE_GLOB="*.sh" ax fs index sync"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64
  var trackFile = ""
  var dir = ""
  var dryRun = ctxFromEnv().dryRun
  var positionalOnly = false
  var hasDir = false
  var hasFile = false
  var i = 0
  while i < args.len:
    let arg = args[i]
    if not positionalOnly and arg == "--":
      positionalOnly = true
      inc i
    elif not positionalOnly and arg in ["--dry-run", "-n"]:
      dryRun = true
      inc i
    elif not positionalOnly and arg in ["-f", "--file"]:
      if i + 1 >= args.len:
        error("Missing value for " & arg, errp)
        return 64
      hasFile = true
      trackFile = args[i + 1]
      i += 2
    elif not positionalOnly and arg.startsWith("--file="):
      hasFile = true
      trackFile = arg[7 .. ^1]
      inc i
    elif not positionalOnly and arg.len > 2 and arg.startsWith("-f"):
      hasFile = true
      trackFile = arg[2 .. ^1]
      if trackFile.len > 0 and trackFile[0] in {'=', ':'}:
        trackFile = trackFile[1 .. ^1]
      inc i
    else:
      if not positionalOnly and arg.startsWith("-"):
        error("Unknown option: " & arg, errp)
        return 64
      if hasDir or arg.len == 0:
        error("Expected at most one non-empty directory argument", errp)
        return 64
      hasDir = true
      dir = arg
      inc i

  if hasFile and trackFile.len == 0:
    error("Index file path must not be empty", errp)
    return 64
  if trackFile.len == 0:
    trackFile = (if dir.len > 0: dir else: ".") / "_TRACK"
  trackFile = normalizedPath(absolutePath(trackFile))
  if dir.len == 0:
    dir = parentDir(trackFile)

  if not requireFile(trackFile, errp): return 1
  if symlinkExists(trackFile):
    error("Refusing symlink index file: " & trackFile, errp)
    return 1
  if not requireDir(dir, errp): return 1

  var excludeGlobs: seq[string] = @[]
  let excludeEnv = getEnv("TRACK_EXCLUDE_GLOB")
  if excludeEnv.len > 0:
    excludeGlobs = excludeEnv.split(':')

  var marks = initTable[string, string]()
  var order: seq[string] = @[]
  let trackBase = extractFilename(trackFile)
  var onDisk = initHashSet[string]()
  try:
    for line in lines(trackFile):
      if line.len > 4 and line[0] == '[' and line[2] == ']' and line[3] == ' ':
        let mark = $line[1]
        let fname = line[4 .. ^1]
        marks[fname] = mark
        order.add(fname)

    # A missing/unreadable scan is an error, never an empty desired state.
    for kind, path in walkDir(dir, checkDir = true):
      if kind != pcFile: continue
      let bname = extractFilename(path)
      if bname == trackBase: continue
      if isExcluded(bname, excludeGlobs): continue
      onDisk.incl(bname)
  except IOError, OSError:
    error("Cannot discover index contents: " & getCurrentExceptionMsg(), errp)
    return 1

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

  var tempPath = ""
  try:
    let (temp, path) = createTempFile(".ax-index-", ".tmp", parentDir(trackFile))
    tempPath = path
    try:
      temp.write(outLines.join("\n") & "\n")
      temp.flushFile()
    finally:
      temp.close()
    setFilePermissions(tempPath, getFilePermissions(trackFile))
    # Same-directory rename replaces the index atomically after a full write.
    moveFile(tempPath, trackFile)
  except IOError, OSError:
    error("Cannot write '" & trackFile & "': " & getCurrentExceptionMsg(), errp)
    return 1
  finally:
    if tempPath.len > 0 and fileExists(tempPath):
      try:
        removeFile(tempPath)
      except OSError:
        warn("Cannot remove temporary index: " & tempPath, errp)
  success("'" & trackBase & "' reconciled.", errp)
  0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
