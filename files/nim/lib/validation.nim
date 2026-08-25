import std/[os, strutils]
import output

proc requireArg*(value: string, name: string, errp: File = stderr): bool =
  if value.len == 0:
    error("Missing required argument: " & name, errp)
    return false
  true

proc checkDeps*(cmds: openArray[string], errp: File = stderr): bool =
  var missing: seq[string] = @[]
  for cmd in cmds:
    if findExe(cmd).len == 0:
      missing.add(cmd)
  if missing.len > 0:
    error("Missing commands: " & missing.join(" "), errp)
    return false
  true

proc requirePathTarget*(path: string, errp: File = stderr): bool =
  try:
    discard getFileInfo(path)
  except OSError:
    error("Path does not exist.", errp)
    return false
  if not (fileExists(path) or dirExists(path)):
    error("Path is not a file or directory.", errp)
    return false
  true

const xattrChars = {'a'..'z', 'A'..'Z', '0'..'9', '.', '_', '-'}

proc requireXattrName*(attribute: string, errp: File = stderr): bool =
  if attribute.len == 0 or not attribute.allCharsInSet(xattrChars):
    error("Invalid attribute name.", errp)
    return false
  true
