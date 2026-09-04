import std/[os, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"
import "../lib/fdscan"

type ParsedArgs* = object
  extensions*: seq[string]
  allFlag*: bool
  raw*: bool
  directory*: string
  unknownOption*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
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
    else:
      if arg.len > 0 and arg[0] == '-':
        result.unknownOption = arg
        return result
      else:
        result.directory = arg
    inc i

proc countTabSpaceLines*(path: string): tuple[tabLines, spaceLines: int] =
  ## Mirrors `grep -cP '^\t'` and `grep -cP '^ '`: a line's first character
  ## is tab, space, or neither, so a single pass suffices.
  result = (0, 0)
  var content: string
  try:
    content = readFile(path)
  except IOError, OSError:
    return
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
    outp.writeLine """Usage: Find-MixedIndentation [opts] [directory]

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
    Find-MixedIndentation
    Find-MixedIndentation ~/projects
    Find-MixedIndentation -e py -e js
    Find-MixedIndentation --all"""
    return 0

  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 1

  let dir = if parsed.directory.len > 0: parsed.directory else: "."
  if not requireDir(dir, errp): return 1
  if not checkDeps(["fd", "file"], errp): return 2

  let files = findFiles(runner, dir, parsed.extensions, parsed.allFlag)
  if files.len == 0:
    info("No files found in '" & dir & "'", errp)
    return 0

  var mixed = 0
  var checked = 0
  var skipped = 0
  var results: seq[tuple[tabLines, spaceLines: int, relPath: string]] = @[]

  for file in files:
    let mime = mimeType(runner, file)
    if not isTextMimeType(mime):
      inc skipped
      continue
    if getFileSize(file) == 0:
      inc skipped
      continue
    inc checked
    let counts = countTabSpaceLines(file)
    if counts.tabLines > 0 and counts.spaceLines > 0:
      inc mixed
      results.add((counts.tabLines, counts.spaceLines, stripDirPrefix(file, dir)))

  if mixed == 0:
    success("No mixed indentation found (" & $checked & " files checked, " &
            $skipped & " skipped)", errp)
    return 0

  var lines: seq[string] = @[]
  for r in results:
    lines.add(r.relPath & "|" & insertSep($r.tabLines, ',') & "|" &
              insertSep($r.spaceLines, ','))

  outp.writeLine("")
  discard table("File|Tabs|Spaces\n" & lines.join("\n"), parsed.raw, runner,
                outp, errp)
  outp.writeLine("")
  warn($mixed & " file(s) with mixed indentation (" & $checked &
       " checked, " & $skipped & " skipped)", errp)

  return 1

when isMainModule:
  cliMain(run(commandLineParams()))
