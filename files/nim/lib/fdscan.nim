## Shared file-discovery helper for the fd-scan family
## (Find-MixedIndentation, Measure-Words, Show-FileSizeHistogram): each zsh
## original independently reimplements the same "build fd args from -e/--all,
## run fd, word-split its output on newlines" driver, and two of the three
## also independently reimplement the same file --brief --mime-type
## text-file classification.
import std/strutils
import process

proc buildFdArgs*(extensions: seq[string], allFlag: bool): seq[string] =
  result = @["--type", "f", "--print0"]
  if allFlag:
    result.add("--hidden")
    result.add("--no-ignore")
  for ext in extensions:
    result.add("--extension")
    result.add(ext)

proc findFiles*(runner: Runner, dir: string, extensions: seq[string],
                allFlag: bool): seq[string] =
  ## NUL-delimited paths preserve embedded newlines. Failed discovery must
  ## never be mistaken for an empty tree.
  let args = buildFdArgs(extensions, allFlag) & @["--", ".", dir]
  let res = runner.capture("fd", args)
  if res.exitCode != 0:
    raise newException(IOError, "File discovery failed: " & res.error.strip())
  let listing = res.output
  result = @[]
  for line in listing.split('\0'):
    if line.len == 0: continue
    result.add(line)

proc isTextMimeType*(mime: string): bool =
  ## Mirrors the zsh original's (inverted) skip condition: true when mime
  ## starts with "text/" or is exactly "application/json" or
  ## "application/xml".
  mime.startsWith("text/") or mime == "application/json" or
    mime == "application/xml"

proc mimeType*(runner: Runner, path: string): string =
  let res = runner.capture("file", @["--brief", "--mime-type", "--", path])
  if res.exitCode != 0:
    raise newException(IOError, "Cannot classify '" & path & "': " & res.error.strip())
  result = res.output.strip()
  if result.len == 0 or result.startsWith("cannot open") or result.startsWith("ERROR:"):
    raise newException(IOError, "Cannot classify '" & path & "': " & result)
