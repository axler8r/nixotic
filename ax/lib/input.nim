## Piped-list input for commands whose positional argument is a list of
## items (paths, image names). The idiomatic shape `producer | ax ...`
## feeds those items one per line on stdin instead of as positionals.
import std/[strutils, terminal]

func stripAnsi*(s: string): string =
  ## Removes CSI escape sequences (`ESC [ params final`), the colour codes a
  ## `--color=always` ls/eza alias emits even into a pipe.
  result = newStringOfCap(s.len)
  var i = 0
  while i < s.len:
    if s[i] == '\e' and i + 1 < s.len and s[i + 1] == '[':
      i += 2
      while i < s.len and s[i] in {'\x30'..'\x3F'}: inc i
      while i < s.len and s[i] in {'\x20'..'\x2F'}: inc i
      if i < s.len and s[i] in {'\x40'..'\x7E'}: inc i
    else:
      result.add s[i]
      inc i

proc readPipedItems*(inp: File = stdin): seq[string] =
  ## Items from `inp`, one per line, when nothing was piped the result is
  ## empty: a terminal stdin is never read (it would block), and an empty
  ## non-terminal stdin (`< /dev/null`, cron) yields no items so the caller
  ## falls through to its no-argument default. Blank lines are dropped and
  ## a trailing CR is stripped; interior whitespace is data.
  ##
  ## `ls`-shaped input is understood: colour codes are stripped, and a
  ## multi-directory listing (`name:` header, its entries, a blank line)
  ## collapses to `name` — the entries are not items. So `ls */ | ax ...`
  ## and `ls -d */ | ax ...` both yield the directories.
  result = @[]
  if isatty(inp):
    return
  var line: string
  var inListing = false
  while inp.readLine(line):
    line.removeSuffix('\r')
    line = stripAnsi(line)
    if line.len == 0:
      inListing = false
    elif inListing:
      discard
    elif line.len > 1 and line[^1] == ':':
      result.add line[0 ..^ 2]
      inListing = true
    else:
      result.add line

proc resolveItems*(positional: seq[string], inp: File = stdin): seq[string] =
  ## Explicit positionals always win; stdin is consulted only when none
  ## were given.
  if positional.len > 0: positional
  else: readPipedItems(inp)
