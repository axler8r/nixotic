import std/[os, random, times]
import "../../../lib/git"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"

randomize()

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["git", "wip", "start"],
  kind: ckVerb,
  summary: "create and switch to a fresh wip/* branch",
  usage: "ax git wip start",
  deps: @["git"],
  dryRun: false
)

proc randomAlnum*(length: int): string =
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  result = newString(length)
  for i in 0 ..< length:
    result[i] = chars[rand(chars.len - 1)]

proc generateWipBranchName*(exists: proc(name: string): bool): string =
  ## Tries up to 10 candidate names of the form wip/YYYYMMDD-<7 random
  ## alnum chars>, calling `exists` to check for a collision on each.
  ## Returns "" if all 10 attempts collided, matching the zsh original's
  ## retry count and give-up behavior.
  let datePart = now().format("yyyyMMdd")
  for _ in 1 .. 10:
    let candidate = "wip/" & datePart & "-" & randomAlnum(7)
    if not exists(candidate):
      return candidate
  ""

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax git wip start

Create and switch to a new branch named:
  wip/YYYYMMDD-<random7>

Requirements:
  - Inside a Git repository
  - Clean Git worktree
  - Currently on stable"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  var code = requireGitRepo(runner, errp)
  if code != 0: return code
  code = requireCleanGitWorktree(runner, errp)
  if code != 0: return code
  code = requireBranchExists("stable", runner, errp)
  if code != 0: return code

  let current = gitCurrentBranch(runner, errp)
  if current.len == 0: return 1
  if current != "stable":
    error("Current branch must be stable: " & current, errp)
    return 1

  let branch = generateWipBranchName(
    proc(name: string): bool =
      runner.runQuiet("git", @["show-ref", "--verify", "--quiet", "refs/heads/" & name]) == 0
  )
  if branch.len == 0:
    error("Could not generate a unique WIP branch name.", errp)
    return 1

  if runner.runQuiet("git", @["checkout", "-b", branch]) != 0:
    error("Could not create branch: " & branch, errp)
    return 1

  success("Created " & branch & ".", errp)
  0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
