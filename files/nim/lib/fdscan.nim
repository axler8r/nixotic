## Shared file-discovery helper for the fd-scan family
## (Find-MixedIndentation, Measure-Words, Show-FileSizeHistogram): each zsh
## original independently reimplements the same "build fd args from -e/--all,
## run fd, word-split its output on newlines" driver, and two of the three
## also independently reimplement the same file --brief --mime-type
## text-file classification.
import std/strutils
import process

proc buildFdArgs*(extensions: seq[string], allFlag: bool): seq[string] =
  result = @["--type", "f"]
  if allFlag:
    result.add("--hidden")
    result.add("--no-ignore")
  for ext in extensions:
    result.add("--extension")
    result.add(ext)

proc findFiles*(runner: Runner, dir: string, extensions: seq[string],
                allFlag: bool): seq[string] =
  ## Runs fd against `dir`, returning the discovered file paths — mirrors
  ## `files=("${(@f)$(fd ... . "$dir" 2>/dev/null)}")`: word-split fd's
  ## output on newlines, dropping the blank line a trailing "\n" produces.
  let args = buildFdArgs(extensions, allFlag) & @[".", dir]
  let listing = runner.capture("fd", args).output
  result = @[]
  for line in listing.splitLines():
    if line.len == 0: continue
    result.add(line)

proc isTextMimeType*(mime: string): bool =
  ## Mirrors the zsh original's (inverted) skip condition: true when mime
  ## starts with "text/" or is exactly "application/json" or
  ## "application/xml".
  mime.startsWith("text/") or mime == "application/json" or
    mime == "application/xml"

proc mimeType*(runner: Runner, path: string): string =
  runner.capture("file", @["--brief", "--mime-type", path]).output.strip()
