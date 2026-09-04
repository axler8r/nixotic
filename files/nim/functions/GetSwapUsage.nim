import std/[os, algorithm, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"

type SwapRow* = tuple[swapKb: int, pid: string, name: string]

proc readStatusFields*(path: string): tuple[swapKb: int, name: string] =
  ## Mirrors `grep VmSwap $dir/status 2>/dev/null | awk '{print $2}'` and the
  ## matching Name extraction: a missing or unreadable file yields (0, ""),
  ## the same as grep's suppressed-error empty output.
  result = (0, "")
  var content: string
  try:
    content = readFile(path)
  except IOError, OSError:
    return
  for line in content.splitLines():
    if line.startsWith("VmSwap:"):
      let parts = line.splitWhitespace()
      if parts.len >= 2:
        try:
          result.swapKb = parseInt(parts[1])
        except ValueError:
          discard
    elif line.startsWith("Name:"):
      let parts = line.splitWhitespace()
      if parts.len >= 2:
        result.name = parts[1]

proc collectSwapRows*(procDir: string): seq[SwapRow] =
  result = @[]
  for kind, path in walkDir(procDir):
    if kind != pcDir: continue
    let pid = path.extractFilename
    if pid.len == 0 or not pid.allCharsInSet({'0' .. '9'}): continue
    let fields = readStatusFields(path / "status")
    if fields.swapKb > 0:
      result.add((fields.swapKb, pid, fields.name))

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner,
  procDir: string = "/proc"
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Get-SwapUsage [--raw]

Display swap memory usage for all processes currently using swap.
Results are sorted by swap usage with highest usage first.
Output format: swap usage (KB) | process ID | process name

Options:
    -h, --help    Show this help message
    --raw         Display output in raw format

Examples:
    Get-SwapUsage"""
    return 0

  var raw = false
  for arg in args:
    if arg == "--raw":
      raw = true
    else:
      error("Unknown option: " & arg, errp)
      return 1

  var rows = collectSwapRows(procDir)
  if rows.len == 0:
    info("No processes currently using swap.", errp)
    return 0

  rows.sort(proc(a, b: SwapRow): int = cmp(b.swapKb, a.swapKb))

  var lines: seq[string] = @[]
  for r in rows:
    lines.add(insertSep($r.swapKb, ',') & " KB|" & r.pid & "|" & r.name)

  outp.writeLine("")
  discard table("Swap|PID|Process\n" & lines.join("\n"), raw, runner, outp, errp)
  outp.writeLine("")
  return 0

when isMainModule:
  cliMain(run(commandLineParams()))
