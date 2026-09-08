import std/[json, os, strutils, terminal]
import context
import process

const
  ansiRed = "\e[31m"
  ansiGreen = "\e[32m"
  ansiYellow = "\e[33m"
  ansiReset = "\e[0m"

proc colorEnabled*(f: File): bool =
  ## AX_COLOR=always/never (set by the driver from --color) overrides the
  ## auto detection; auto or unset keeps the original behaviour, so
  ## NO_COLOR stays honoured by default and an explicit `always` wins over
  ## it (no-color.org convention).
  case getEnv(axColorEnv)
  of "always": true
  of "never": false
  else: isatty(f) and not existsEnv("NO_COLOR")

proc quietEnabled(): bool =
  getEnv(axQuietEnv) == "1"

proc error*(msg: string, errp: File = stderr) =
  if colorEnabled(errp):
    errp.writeLine(ansiRed & "Error:" & ansiReset & " " & msg)
  else:
    errp.writeLine("Error: " & msg)

proc info*(msg: string, errp: File = stderr) =
  ## Suppressed under -q/AX_QUIET; error and warn never are.
  if quietEnabled():
    return
  if colorEnabled(errp):
    errp.writeLine(ansiGreen & "Info:" & ansiReset & " " & msg)
  else:
    errp.writeLine("Info: " & msg)

proc success*(msg: string, errp: File = stderr) =
  ## Suppressed under -q/AX_QUIET; error and warn never are.
  if quietEnabled():
    return
  if colorEnabled(errp):
    errp.writeLine(ansiGreen & "Success:" & ansiReset & " " & msg)
  else:
    errp.writeLine("Success: " & msg)

proc warn*(msg: string, errp: File = stderr) =
  if colorEnabled(errp):
    errp.writeLine(ansiYellow & "Warning:" & ansiReset & " " & msg)
  else:
    errp.writeLine("Warning: " & msg)

proc confirm*(message: string, inp: File = stdin, outp: File = stderr): bool =
  ## Interactive y/N prompt. Writes `message` (plus " (y/N): ") to `outp`
  ## with no trailing newline, then reads one line from `inp`. Mirrors the
  ## zsh original's `__ax_confirm`: only "y"/"yes" (any case) count as
  ## acceptance; a blank line, "n", anything else, or EOF is a decline.
  outp.write(message & " (y/N): ")
  outp.flushFile()
  var response: string
  if not inp.readLine(response):
    return false
  let normalized = response.strip().toLowerAscii()
  normalized == "y" or normalized == "yes"

func tableUsesColor*(color: ColorMode, tty, noColor, gumAvailable: bool): bool =
  gumAvailable and (color == cmAlways or (color == cmAuto and tty and not noColor))

proc table*(data: string, raw: bool = false, runner: Runner = defaultRunner,
           outp: File = stdout, errp: File = stderr,
           color: ColorMode = ctxFromEnv().color): int =
  ## Plain output always uses column. Table output follows the resolved
  ## colour policy, including an explicit override of NO_COLOR.
  let plain = raw or not tableUsesColor(color, isatty(outp), existsEnv("NO_COLOR"),
                                       findExe("gum").len > 0)
  var cr: CommandResult
  if plain:
    cr = runner.capture("column", @["-t", "-s|"], data)
  else:
    # gum uses termenv's environment rather than AX_COLOR. Restore exact
    # set/unset state after the synchronous child finishes.
    let hadNoColor = existsEnv("NO_COLOR")
    let noColor = getEnv("NO_COLOR")
    let hadForce = existsEnv("CLICOLOR_FORCE")
    let force = getEnv("CLICOLOR_FORCE")
    try:
      if color == cmAlways:
        delEnv("NO_COLOR")
        putEnv("CLICOLOR_FORCE", "1")
      cr = runner.capture("gum", @["table", "--separator", "|", "--border",
                                  "rounded", "--print"], data)
    finally:
      if hadNoColor: putEnv("NO_COLOR", noColor)
      else: delEnv("NO_COLOR")
      if hadForce: putEnv("CLICOLOR_FORCE", force)
      else: delEnv("CLICOLOR_FORCE")
  outp.write(cr.output)
  if cr.error.len > 0:
    errp.write(cr.error)
  cr.exitCode

proc jsonKey(header: string): string =
  header.strip().toLowerAscii().replace(" ", "_")

func displayCell*(value: string): string =
  ## Display encoding, not a transport format; JSON preserves exact data.
  for c in value:
    case c
    of '\\': result.add "\\\\"
    of '|': result.add "\\x7c"
    of '\n': result.add "\\n"
    of '\r': result.add "\\r"
    of '\t': result.add "\\t"
    of '\0' .. '\b', '\v', '\f', '\x0e' .. '\x1f', '\x7f':
      result.add "\\x" & toHex(ord(c), 2).toLowerAscii()
    else: result.add c

proc render*(header: seq[string], rows: seq[seq[string]], ctx: Ctx,
             runner: Runner = defaultRunner,
             outp: File = stdout, errp: File = stderr): int =
  ## Ctx-aware renderer for tabular data — every list and report command
  ## goes through it. `table` and `plain` reproduce the pre-ax behaviour
  ## (gum/column and --raw respectively); `json` emits an array of objects
  ## keyed by the lowercased, underscore-joined header cells, making every
  ## such command a first-class jq source.
  var keys: seq[string]
  for h in header:
    let key = jsonKey(h)
    if key.len == 0 or key in keys:
      error("Report headers must have nonempty, unique JSON keys", errp)
      return 1
    keys.add key
  for row in rows:
    if row.len > header.len:
      error("Report row has more cells than its header", errp)
      return 1
  case ctx.output
  of omJson:
    var arr = newJArray()
    for row in rows:
      var obj = newJObject()
      for i, h in header:
        obj[jsonKey(h)] = %(if i < row.len: row[i] else: "")
      arr.add obj
    outp.writeLine(arr.pretty())
    0
  of omTable, omPlain:
    var columns: seq[string]
    for h in header: columns.add displayCell(h)
    var data = columns.join("|") & "\n"
    for row in rows:
      columns.setLen(0)
      for cell in row: columns.add displayCell(cell)
      data.add columns.join("|") & "\n"
    table(data, raw = ctx.output == omPlain, runner = runner,
          outp = outp, errp = errp, color = ctx.color)
