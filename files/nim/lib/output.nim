import std/[os, terminal]

const
  ansiRed = "\e[31m"
  ansiReset = "\e[0m"

proc colorEnabled*(f: File): bool =
  isatty(f) and not existsEnv("NO_COLOR")

proc error*(msg: string, errp: File = stderr) =
  if colorEnabled(errp):
    errp.writeLine(ansiRed & "Error:" & ansiReset & " " & msg)
  else:
    errp.writeLine("Error: " & msg)
