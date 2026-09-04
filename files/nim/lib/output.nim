import std/[os, strutils, terminal]
import process

const
  ansiRed = "\e[31m"
  ansiGreen = "\e[32m"
  ansiYellow = "\e[33m"
  ansiReset = "\e[0m"

proc colorEnabled*(f: File): bool =
  isatty(f) and not existsEnv("NO_COLOR")

proc error*(msg: string, errp: File = stderr) =
  if colorEnabled(errp):
    errp.writeLine(ansiRed & "Error:" & ansiReset & " " & msg)
  else:
    errp.writeLine("Error: " & msg)

proc info*(msg: string, errp: File = stderr) =
  if colorEnabled(errp):
    errp.writeLine(ansiGreen & "Info:" & ansiReset & " " & msg)
  else:
    errp.writeLine("Info: " & msg)

proc success*(msg: string, errp: File = stderr) =
  if colorEnabled(errp):
    errp.writeLine(ansiGreen & "Success:" & ansiReset & " " & msg)
  else:
    errp.writeLine("Success: " & msg)

proc warn*(msg: string, errp: File = stderr) =
  if colorEnabled(errp):
    errp.writeLine(ansiYellow & "Warning:" & ansiReset & " " & msg)
  else:
    errp.writeLine("Warning: " & msg)

proc confirm*(message: string, inp: File = stdin, outp: File = stdout): bool =
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

proc table*(data: string, raw: bool = false, runner: Runner = defaultRunner,
           outp: File = stdout, errp: File = stderr): int =
  ## Formats pipe-delimited rows (first row = header) the same way the zsh
  ## __ax_table helper does: `gum table` when outp is an interactive
  ## terminal, NO_COLOR is unset, and gum is on PATH; otherwise plain
  ## `column -t -s|` alignment. `raw` forces the plain path exactly like
  ## the zsh original's --raw flag; a non-tty outp forces it regardless of
  ## raw, matching the zsh original's `[[ ! -t 1 ]]` check.
  let plain = raw or not isatty(outp) or existsEnv("NO_COLOR") or
              findExe("gum").len == 0
  let cr =
    if plain:
      runner.capture("column", @["-t", "-s|"], data)
    else:
      runner.capture("gum", @["table", "--separator", "|", "--border",
                              "rounded", "--print"], data)
  outp.write(cr.output)
  if cr.error.len > 0:
    errp.write(cr.error)
  cr.exitCode
