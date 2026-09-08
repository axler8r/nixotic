import std/[os, strutils]
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["claude", "init"],
  kind: ckVerb,
  summary: "set up the Claude GitHub-MCP workflow in the current project",
  usage: "ax claude init",
  deps: @["git"],
  dryRun: false
)

const templateRelPath = ".claude/templates/project/axler8r.md"

proc gitSucceeds(runner: Runner, args: seq[string]): bool =
  ## Exit code only; output is drained and discarded.
  if findExe("git").len == 0: return false
  runner.runQuiet("git", args) == 0

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax claude init

Description:
    Set up the Claude GitHub-MCP developer workflow in the current project.
    Writes .claude/axler8r.md from the nixotic project template and ensures
    .claude/CLAUDE.md imports it via @axler8r.md.

    The /axler8r:start, /axler8r:resume, and /axler8r:complete slash commands
    are personal commands deployed by home-manager (~/.claude/commands/axler8r/)
    and are available in every project — no per-project setup required.

    Safe to re-run: refreshes .claude/axler8r.md from the current template.

    Prerequisites:
      - Current directory is a git repository with a remote named 'origin'

Options:
    -h, --help          Show this help message

Examples:
    ax claude init"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  if not checkDeps(["git"], errp): return 2

  if not gitSucceeds(runner, @["rev-parse", "--git-dir"]):
    error("Not a git repository", errp)
    return 1

  if not gitSucceeds(runner, @["remote", "get-url", "origin"]):
    error("No git remote 'origin' configured", errp)
    return 1

  let templatePath = getHomeDir() / templateRelPath
  if not fileExists(templatePath):
    error("Project template not found: " & templatePath, errp)
    error("Run 'nh os switch' to apply the latest nixotic configuration", errp)
    return 1

  try:
    createDir(".claude")
    copyFile(templatePath, ".claude/axler8r.md")

    const claudeMdPath = ".claude/CLAUDE.md"
    if not fileExists(claudeMdPath):
      writeFile(claudeMdPath, "@axler8r.md\n")
    else:
      let content = readFile(claudeMdPath)
      if not content.contains("@axler8r.md"):
        let f = open(claudeMdPath, fmAppend)
        f.write("\n@axler8r.md\n")
        f.close()
  except IOError, OSError:
    error("Cannot write .claude/ in the current directory: " &
          getCurrentExceptionMsg(), errp)
    return 1

  success("Claude workflow initialised", errp)
  outp.writeLine ""
  outp.writeLine "  Files:"
  outp.writeLine "    .claude/axler8r.md"
  outp.writeLine "    .claude/CLAUDE.md"
  outp.writeLine ""
  outp.writeLine "  Next: commit .claude/ and create your first issue with /axler8r:start"
  0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
