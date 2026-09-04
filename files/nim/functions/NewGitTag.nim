import std/[os, strutils, times]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/git"

proc extractCommitType*(subject: string): string =
  ## Mirrors the zsh original's `^([a-z]+)(!)?(\([^)]*\))?:` extraction:
  ## a leading run of lowercase letters, optionally followed by "!",
  ## optionally followed by a "(...)" scope, then a literal ":". Returns
  ## the leading letters (group 1), or "" if the subject doesn't match
  ## this exact shape. No std/re -- see docs/nim-functions-conventions.md's
  ## "Regex avoidance" section.
  var i = 0
  while i < subject.len and subject[i] in {'a'..'z'}:
    inc i
  if i == 0:
    return ""
  let typ = subject[0 ..< i]
  if i < subject.len and subject[i] == '!':
    inc i
  if i < subject.len and subject[i] == '(':
    let closeIdx = subject.find(')', i)
    if closeIdx == -1:
      return ""
    i = closeIdx + 1
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
  (parseInt(segments[0]), parseInt(segments[1]), true)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: New-GitTag [--dry-run]

Compute the next tag from HEAD's commit type and the last matching tag,
then create it as a signed annotated tag: v<MAJOR>.<MINOR>.0+<timestamp>.

  MAJOR bump (MINOR resets to 0): feat, feat!
  MINOR bump:                     refactor, defect, dep, sec
  no tag:                         everything else

Options:
  --dry-run   Print the computed tag without creating it.

Requirements:
  - Inside a Git repository
  - HEAD not already tagged"""
    return 0

  let dryRun = args.len > 0 and args[0] == "--dry-run"

  let repoCode = requireGitRepo(runner, errp)
  if repoCode != 0: return repoCode

  let existing = runner.capture("git", @["tag", "--points-at", "HEAD"]).output.strip()
  if existing.len > 0:
    error("HEAD is already tagged: " & existing, errp)
    return 1

  let subject = runner.capture("git", @["log", "-1", "--format=%s"]).output.strip()
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

  let tagList = runner.capture("git", @["tag", "-l", "v*.*.0+*", "--sort=-v:refname"]).output
  let lastTagLine = if tagList.len > 0: tagList.splitLines()[0] else: ""
  let parsed = parseLastTag(lastTagLine)
  var major = if parsed.valid: parsed.major else: 0
  var minor = if parsed.valid: parsed.minor else: 0

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
  cliMain(run(commandLineParams()))
