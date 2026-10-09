import std/[os, strutils]
import "../../../lib/input"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["git", "repo", "optimize"],
  kind: ckVerb,
  summary: "fetch, fsck, and gc git repositories in parallel",
  usage: "ax git repo optimize [--log <path>] [dir...]",
  args: @[
    ArgSpec(name: "dir", required: false, variadic: true,
            description: "directories to optimise (default: one per line on stdin)")
  ],
  flags: @[
    FlagSpec(long: "log", takesValue: true,
             description: "write a GNU parallel job log to this path")
  ],
  deps: @["git", "parallel"],
  dryRun: false
)

const usage = """Usage: ax git repo optimize [--log <path>] [dir...]

Fetch, fsck, and gc git repositories in parallel. Directories come from the
arguments, or one per line on stdin when none are given.

Options:
    -h, --help    Show this help message
    --log <path>  Write a GNU parallel job log to this path

Arguments:
    dir           Directories to optimise

Examples:
    ax git repo optimize ~/Projects/foo ~/Projects/bar
    ax git repo optimize --log /tmp/gc.log ~/Projects/*/
    ls -d ~/Projects/*/ | ax git repo optimize"""

const gcCommand = "git -C {} fetch --prune && git -C {} fsck --full && " &
  "git -C {} reflog expire --expire=90.days.ago && git -C {} gc --prune=90.days.ago"

proc filterGitDirs*(dirs: seq[string]): seq[string] =
  ## An entry survives if it both exists as a directory AND contains a
  ## `.git` subdirectory — mirrors the zsh original's
  ## `[[ -d "$_dir" && -d "$_dir/.git" ]]` filter.
  result = @[]
  for dir in dirs:
    if dirExists(dir) and (dirExists(dir / ".git") or fileExists(dir / ".git")):
      result.add(dir)

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

  var logPath = ""
  var dirs: seq[string] = @[]
  var positionalOnly = false
  var i = 0
  while i < args.len:
    let arg = args[i]
    if positionalOnly:
      dirs.add(arg)
      inc i
      continue
    if arg == "--":
      positionalOnly = true
      inc i
      continue
    if arg.startsWith("--log="):
      logPath = arg[6 .. ^1]
      inc i
      continue
    case arg
    of "--log":
      inc i
      let next = if i < args.len: args[i] else: ""
      if not requireArg(next, "log path", errp): return 64
      logPath = next
    of "-h", "--help":
      outp.writeLine(usage)
      return 0
    else:
      if arg.len > 1 and arg[0] == '-':
        error("Unknown option: " & arg, errp)
        return 64
      else:
        dirs.add(arg)
    inc i

  dirs = resolveItems(dirs, inp)
  if dirs.len == 0:
    error("Missing required argument: dir (pass directories or pipe them on stdin)", errp)
    return 64

  let gitDirs = filterGitDirs(dirs)

  if gitDirs.len == 0:
    warn("No git repositories found in the provided directories.", errp)
    return 0

  var parallelArgs = @["--jobs", "4", "--progress"]
  if logPath.len > 0:
    parallelArgs.add("--joblog")
    parallelArgs.add(logPath)
  parallelArgs.add(gcCommand)
  parallelArgs.add(":::")
  for dir in gitDirs:
    parallelArgs.add(dir)

  result = runner.runInherited("parallel", parallelArgs)

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
