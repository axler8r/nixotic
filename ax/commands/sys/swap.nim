import std/[os, algorithm, strutils]
import "../../lib/context"
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["sys", "swap"],
  kind: ckReport,
  summary: "per-process swap usage, highest first",
  usage: "ax sys swap [-o table|plain|json]",
  dryRun: false
)

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
    outp.writeLine """Usage: ax sys swap

Display swap memory usage for all processes currently using swap.
Results are sorted by swap usage with highest usage first.
Output format: swap usage (KB) | process ID | process name

Options:
    -h, --help    Show this help message
    --raw         Deprecated alias for -o plain

Examples:
    ax sys swap"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  var ctx = ctxFromEnv()
  for arg in args:
    if arg == "--": break
    if arg == "--raw":
      ctx.output = omPlain
    else:
      error("Unknown option: " & arg, errp)
      return 64

  var swapRows = collectSwapRows(procDir)
  if swapRows.len == 0:
    info("No processes currently using swap.", errp)
    if ctx.output != omJson: return 0

  swapRows.sort(proc(a, b: SwapRow): int = cmp(b.swapKb, a.swapKb))

  var rows: seq[seq[string]] = @[]
  for r in swapRows:
    rows.add @[insertSep($r.swapKb, ',') & " KB", r.pid, r.name]

  if ctx.output == omTable:
    outp.writeLine("")
  let renderCode = render(@["Swap", "PID", "Process"], rows, ctx, runner, outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return renderCode

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
