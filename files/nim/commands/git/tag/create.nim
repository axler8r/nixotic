import std/[os, strutils, times]
import "../../../lib/context"
import "../../../lib/git"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["git", "tag", "create"],
  kind: ckVerb,
  summary: "tag HEAD from its commit type: v<MAJOR>.<MINOR>.0+<timestamp>",
  usage: "ax git tag create [-n]",
  deps: @["git"],
  dryRun: true
)

proc extractCommitType*(subject: string): string =
  ## Conventional commits: type(scope)!: subject; scope and ! are optional.
  var i = 0
  while i < subject.len and subject[i] in {'a'..'z'}:
    inc i
  if i == 0:
    return ""
  let typ = subject[0 ..< i]
  if i < subject.len and subject[i] == '(':
    let closeIdx = subject.find(')', i)
    if closeIdx <= i + 1 or subject[i + 1 ..< closeIdx].contains('('):
      return ""
    i = closeIdx + 1
  if i < subject.len and subject[i] == '!':
    inc i
  if i < subject.len and subject[i] == ':':
    return typ
  ""

proc parseLastTag*(tag: string): tuple[major, minor: int, valid: bool] =
  ## Mirrors the zsh original's `^v([0-9]+)\.([0-9]+)\.0\+[0-9]{14}$`
  ## validation before trusting a "last tag" as the base to bump from.
  if tag.len == 0 or tag[0] != 'v':
    return (0, 0, false)
  let rest = tag[1 .. ^1]
  let plusIdx = rest.find('+')
  if plusIdx == -1: return (0, 0, false)
  let versionPart = rest[0 ..< plusIdx]
  let suffix = rest[plusIdx + 1 .. ^1]
  if suffix.len != 14 or not suffix.allCharsInSet({'0'..'9'}):
    return (0, 0, false)
  let segments = versionPart.split(".")
  if segments.len != 3 or segments[2] != "0":
    return (0, 0, false)
  if segments[0].len == 0 or not segments[0].allCharsInSet({'0'..'9'}):
    return (0, 0, false)
  if segments[1].len == 0 or not segments[1].allCharsInSet({'0'..'9'}):
    return (0, 0, false)
  try:
    (parseInt(segments[0]), parseInt(segments[1]), true)
  except ValueError:
    (0, 0, false)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax git tag create [-n]

Compute the next tag from HEAD's commit type and the last matching tag,
then create it as a signed annotated tag: v<MAJOR>.<MINOR>.0+<timestamp>.

  MAJOR bump (MINOR resets to 0): feat, feat!
  MINOR bump:                     refactor, defect, dep, sec
  no tag:                         everything else

Options:
  -n, --dry-run   Print the computed tag without creating it.

Requirements:
  - Inside a Git repository
  - HEAD not already tagged"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  # The driver consumes -n and passes it down as AX_DRY_RUN; a literal
  # --dry-run still works for direct libexec invocation.
  let dryRun = ctxFromEnv().dryRun or "--dry-run" in args or "-n" in args

  let repoCode = requireGitRepo(runner, errp)
  if repoCode != 0: return repoCode

  let existingResult = runner.capture("git", @["tag", "--points-at", "HEAD"])
  if existingResult.exitCode != 0:
    error("Cannot inspect HEAD tags: " & existingResult.error.strip(), errp)
    return 1
  let existing = existingResult.output.strip()
  if existing.len > 0:
    error("HEAD is already tagged: " & existing, errp)
    return 1

  let logResult = runner.capture("git", @["log", "-1", "--format=%s"])
  if logResult.exitCode != 0:
    error("Cannot read HEAD commit: " & logResult.error.strip(), errp)
    return 1
  let subject = logResult.output.strip()
  let commitType = extractCommitType(subject)
  if commitType.len == 0:
    success("No tag needed: could not determine a commit type.", errp)
    return 0

  var tier: string
  case commitType
  of "feat": tier = "major"
  of "refactor", "defect", "dep", "sec": tier = "minor"
  else:
    success("No tag needed for type: " & commitType & ".", errp)
    return 0

  let tagList = runner.capture("git", @["tag", "-l", "v*.*.0+*", "--sort=-v:refname"])
  if tagList.exitCode != 0:
    error("Cannot list previous tags: " & tagList.error.strip(), errp)
    return 1
  var major = 0
  var minor = 0
  for line in tagList.output.splitLines():
    let parsed = parseLastTag(line)
    if parsed.valid and (parsed.major > major or
        (parsed.major == major and parsed.minor > minor)):
      major = parsed.major
      minor = parsed.minor

  if (tier == "major" and major == high(int)) or
      (tier == "minor" and minor == high(int)):
    error("Tag version exceeds supported integer range.", errp)
    return 1

  if tier == "major":
    major += 1
    minor = 0
  else:
    minor += 1

  let timestamp = now().format("yyyyMMddHHmmss")
  let tag = "v" & $major & "." & $minor & ".0+" & timestamp

  if dryRun:
    outp.writeLine(tag)
    return 0

  let msg = $major & "." & $minor & ".0"
  if runner.runInherited("git", @["tag", "-s", "-a", tag, "-m", msg]) != 0:
    error("Could not create tag: " & tag, errp)
    return 1

  success("Tagged " & tag & ".", errp)
  0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
