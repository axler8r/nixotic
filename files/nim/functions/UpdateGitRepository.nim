import std/os
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"

const usage = """Usage: Update-GitRepository [path...]

Pull and update git repositories. With no arguments, scans the current
directory for git repositories.

Options:
    -h, --help    Show this help message

Arguments:
    path          One or more git repository paths

Examples:
    Update-GitRepository
    Update-GitRepository ~/Projects/foo ~/Projects/bar
    Update-GitRepository ~/Projects/*/"""

proc stripTrailingSlash*(path: string): string =
  ## Mirrors zsh's `${_arg%/}` — removes at most one trailing `/`.
  if path.len > 0 and path[^1] == '/':
    path[0 ..^ 2]
  else:
    path

proc resolveGivenDirs*(args: seq[string], errp: File = stderr): seq[string] =
  ## For each positional arg: strip a single trailing slash, check
  ## `<stripped>/.git` is a directory. Warns using the ORIGINAL arg (not
  ## the stripped version) when it doesn't qualify.
  result = @[]
  for arg in args:
    let stripped = stripTrailingSlash(arg)
    if dirExists(stripped / ".git"):
      result.add(stripped)
    else:
      warn("Not a git repository: " & arg, errp)

proc scanCurrentDirGitRepos*(root: string): seq[string] =
  ## One-level-only scan of `root`'s immediate subdirectories, mirroring
  ## the zsh `*/` glob — not recursive. Returns absolute paths.
  result = @[]
  for kind, path in walkDir(root):
    if kind == pcDir or kind == pcLinkToDir:
      if dirExists(path / ".git"):
        result.add(path)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine(usage)
    return 0

  if not checkDeps(["git", "parallel"], errp): return 2

  var dirs: seq[string]

  if args.len > 0:
    dirs = resolveGivenDirs(args, errp)
  else:
    dirs = scanCurrentDirGitRepos(getCurrentDir())

  if dirs.len == 0:
    info("No git repositories found.", errp)
    return 0

  var parallelArgs = @["echo {} && git -C {} pull && git -C {} submodule update", ":::"]
  for dir in dirs:
    parallelArgs.add(dir)

  result = defaultRunner.runInherited("parallel", parallelArgs)

when isMainModule:
  cliMain(run(commandLineParams()))
