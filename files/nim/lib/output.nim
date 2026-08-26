import std/[os, terminal]

const
  ansiRed = "\e[31m"
  ansiGreen = "\e[32m"
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
