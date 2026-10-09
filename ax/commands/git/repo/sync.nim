import std/os
import "../../../lib/input"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["git", "repo", "sync"],
  kind: ckVerb,
  summary: "pull and update git repositories in parallel",
  usage: "ax git repo sync [path...]",
  args: @[
    ArgSpec(name: "path", required: false, variadic: true,
            description: "git repository paths (default: one per line on stdin, else scan the current directory)")
  ],
  deps: @["git", "parallel"],
  dryRun: false
)

const usage = """Usage: ax git repo sync [path...]

Pull and update git repositories. Paths come from the arguments, or one per
line on stdin when none are given; with neither, scans the current directory
for git repositories.

Options:
    -h, --help    Show this help message

Arguments:
    path          One or more git repository paths

Examples:
    ax git repo sync
    ax git repo sync ~/Projects/foo ~/Projects/bar
    ax git repo sync ~/Projects/*/
    ls -d ~/Projects/*/ | ax git repo sync"""

proc stripTrailingSlash*(path: string): string =
  ## Mirrors zsh's `${_arg%/}` — removes at most one trailing `/`.
  if path.len > 1 and path[^1] == '/':
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
    if dirExists(stripped / ".git") or fileExists(stripped / ".git"):
      result.add(stripped)
    else:
      warn("Not a git repository: " & arg, errp)

proc scanCurrentDirGitRepos*(root: string): seq[string] =
  ## One-level-only scan of `root`'s immediate subdirectories, mirroring
  ## the zsh `*/` glob — not recursive. Returns absolute paths.
  result = @[]
  for kind, path in walkDir(root, checkDir = true):
    if kind == pcDir or kind == pcLinkToDir:
      if dirExists(path / ".git") or fileExists(path / ".git"):
        result.add(path)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner,
  inp: File = stdin
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine(usage)
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  if not checkDeps(["git", "parallel"], errp): return 2

  var dirs: seq[string]
  var positional: seq[string]
  var positionalOnly = false
  for arg in args:
    if not positionalOnly and arg == "--":
      positionalOnly = true
    else:
      positional.add(arg)

  positional = resolveItems(positional, inp)
  if positional.len > 0:
    dirs = resolveGivenDirs(positional, errp)
  else:
    try:
      dirs = scanCurrentDirGitRepos(getCurrentDir())
    except CatchableError as e:
      error(e.msg, errp)
      return 1

  if dirs.len == 0:
    info("No git repositories found.", errp)
    return 0

  var parallelArgs = @["echo {} && git -C {} pull && git -C {} submodule update", ":::"]
  for dir in dirs:
    parallelArgs.add(dir)

  result = runner.runInherited("parallel", parallelArgs)

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
