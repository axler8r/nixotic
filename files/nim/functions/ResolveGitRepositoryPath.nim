import std/[os, algorithm, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"

proc isGitRepo*(dir: string, runner: Runner): bool =
  runner.runQuiet("git", @["-C", dir, "rev-parse", "--git-dir"]) == 0

proc gitRemoteFetchUrl*(dir: string, runner: Runner): string =
  ## Returns "origin"'s fetch URL if present, else the first remote `git
  ## remote -v` lists; "" if the directory has no remotes at all.
  let listing = runner.capture("git", @["-C", dir, "remote", "-v"]).output
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
  for kind, path in walkDir(baseDir):
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
    outp.writeLine """Usage: Resolve-GitRepositoryPath [--raw]

Maps git repository directories to their remote fetch URLs.

Options:
    -h, --help    Show this help message
    --raw         Display output in raw format

Examples:
    Resolve-GitRepositoryPath"""
    return 0

  var raw = false
  for arg in args:
    if arg == "--raw":
      raw = true

  if not checkDeps(["git"], errp): return 2

  let rows = collectRepoRows(baseDir, runner)
  var lines: seq[string] = @[]
  for r in rows:
    lines.add(r.url & "|" & r.path)

  outp.writeLine("")
  discard table("Remote|Path\n" & lines.join("\n"), raw, runner, outp, errp)
  outp.writeLine("")
  return 0

when isMainModule:
  cliMain(run(commandLineParams()))
