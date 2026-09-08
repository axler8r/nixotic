import std/[os, algorithm, strutils]
import "../../../lib/context"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["git", "repo", "root"],
  kind: ckReport,
  summary: "map repository directories to their remote fetch URLs",
  usage: "ax git repo root [-o table|plain|json]",
  deps: @["git"],
  dryRun: false
)

proc isGitRepo*(dir: string, runner: Runner): bool =
  runner.runQuiet("git", @["-C", dir, "rev-parse", "--git-dir"]) == 0

proc gitRemoteFetchUrl*(dir: string, runner: Runner): string =
  ## Returns "origin"'s fetch URL if present, else the first remote `git
  ## remote -v` lists; "" if the directory has no remotes at all.
  let res = runner.capture("git", @["-C", dir, "remote", "-v"])
  if res.exitCode != 0:
    raise newException(IOError, "Cannot list remotes for '" & dir & "': " & res.error.strip())
  let listing = res.output
  var firstUrl = ""
  for line in listing.splitLines():
    if line.len == 0: continue
    if not line.contains("(fetch)"): continue
    let parts = line.splitWhitespace()
    if parts.len < 2: continue
    if firstUrl.len == 0: firstUrl = parts[1]
    if parts[0] == "origin": return parts[1]
  firstUrl

proc collectRepoRows*(baseDir: string, runner: Runner): seq[tuple[url, path: string]] =
  result = @[]
  var dirs: seq[string] = @[]
  for kind, path in walkDir(baseDir, checkDir = true):
    if kind != pcDir: continue
    if path.extractFilename.startsWith("."): continue
    dirs.add(path)
  dirs.sort()
  for dir in dirs:
    if not isGitRepo(dir, runner): continue
    result.add((gitRemoteFetchUrl(dir, runner), dir.absolutePath))

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner,
  baseDir: string = "."
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax git repo root [-o table|plain|json]

Maps git repository directories to their remote fetch URLs.

Options:
    -h, --help    Show this help message
    --raw         Deprecated alias for -o plain

Examples:
    ax git repo root"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  var ctx = ctxFromEnv()
  for arg in args:
    if arg == "--raw":
      ctx.output = omPlain

  if not checkDeps(["git"], errp): return 2

  var repoRows: seq[tuple[url, path: string]]
  try:
    repoRows = collectRepoRows(baseDir, runner)
  except CatchableError as e:
    error(e.msg, errp)
    return 1
  var rows: seq[seq[string]] = @[]
  for r in repoRows:
    rows.add @[r.url, r.path]

  # The blank-line padding around the table is cosmetic gum spacing; plain
  # and json output stay unpadded so they remain script- and jq-clean.
  if ctx.output == omTable:
    outp.writeLine("")
  let renderCode = render(@["Remote", "Path"], rows, ctx, runner, outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return renderCode

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
