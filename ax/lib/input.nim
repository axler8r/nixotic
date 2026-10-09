## Piped-list input for commands whose positional argument is a list of
## items (paths, image names). The idiomatic shape `producer | ax ...`
## feeds those items one per line on stdin instead of as positionals.
import std/[strutils, terminal]

proc readPipedItems*(inp: File = stdin): seq[string] =
  ## Items from `inp`, one per line, when nothing was piped the result is
  ## empty: a terminal stdin is never read (it would block), and an empty
  ## non-terminal stdin (`< /dev/null`, cron) yields no items so the caller
  ## falls through to its no-argument default. Blank lines are dropped and
  ## a trailing CR is stripped; interior whitespace is data.
  result = @[]
  if isatty(inp):
    return
  var line: string
  while inp.readLine(line):
    line.removeSuffix('\r')
    if line.len > 0:
      result.add line

proc resolveItems*(positional: seq[string], inp: File = stdin): seq[string] =
  ## Explicit positionals always win; stdin is consulted only when none
  ## were given.
  if positional.len > 0: positional
  else: readPipedItems(inp)
