import std/[os, algorithm, strutils]
import "../../../lib/context"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["docker", "image", "search"],
  kind: ckVerb,
  summary: "search Docker Hub for images",
  usage: "ax docker image search <term>...",
  args: @[
    ArgSpec(name: "term", required: true, variadic: true,
            description: "one or more words to search for")
  ],
  deps: @["docker"],
  dryRun: false
)

type ParsedArgs* = object
  raw*: bool
  searchTerm*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  ## Mirrors the zsh original's `_args` array: every non---raw argument
  ## joins the search term, in the order given, space-separated.
  var terms: seq[string] = @[]
  for arg in args:
    if arg == "--raw":
      result.raw = true
    else:
      terms.add(arg)
  result.searchTerm = terms.join(" ")

proc parseDockerList*(output: string): seq[string] =
  result = @[]
  for line in output.splitLines():
    if line.len == 0: continue
    result.add(line)

proc starCount(row: string): int =
  ## Second pipe-delimited field, parsed as an int; anything unparseable
  ## (should not happen for real `docker search` output) sorts as 0, the
  ## same leniency GNU sort's -n gives a malformed numeric field.
  let parts = row.rsplit("|", maxsplit = 1)
  if parts.len < 2: return 0
  try:
    parseInt(parts[1])
  except ValueError:
    0

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax docker image search <term>...

Search Docker Hub for images by name pattern.

Options:
    -h, --help    Show this help message
    --raw         Deprecated alias for -o plain

Arguments:
    <term>        One or more words to search for

Examples:
    ax docker image search nginx
    ax docker image search postgres official"""
    return 0

  let parsed = parseArgs(args)
  if parsed.searchTerm.len == 0:
    error("Missing search term", errp)
    outp.writeLine("Usage: ax docker image search <term>...")
    return 64

  var ctx = ctxFromEnv()
  if parsed.raw:
    ctx.output = omPlain

  if not checkDeps(["docker"], errp): return 2

  outp.writeLine("Searching for Docker images matching: '" & parsed.searchTerm & "'")

  let listing = runner.capture(
    "docker",
    @["search", parsed.searchTerm, "--format={{.Name}}|{{.StarCount}}"]
  ).output
  var lines = parseDockerList(listing)
  lines.sort(proc(a, b: string): int = cmp(starCount(b), starCount(a)))
  var rows: seq[seq[string]] = @[]
  for line in lines:
    rows.add line.split("|")

  if ctx.output == omTable:
    outp.writeLine("")
  discard render(@["Name", "Stars"], rows, ctx, runner, outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return 0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
