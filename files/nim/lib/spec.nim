## CommandSpec: the machine-readable self-description every ax command
## binary carries. A binary answers the hidden `--ax-spec` flag with its
## spec as JSON; the build concatenates those answers into
## share/ax/registry.json, which is the sole source for dispatch, help,
## and completion. A registry derived from the binaries actually built
## cannot disagree with them.
import std/[json, os, strutils]
import output

type
  ArgSpec* = object
    name*: string
    required*: bool
    variadic*: bool
    description*: string

  FlagSpec* = object
    long*: string        ## without the leading "--"
    short*: string       ## without the leading "-"; "" for none
    takesValue*: bool
    description*: string

  CommandKind* = enum
    ckVerb = "verb"
    ckReport = "report"

  CommandSpec* = object
    specVersion*: int
    path*: seq[string]   ## e.g. @["vault", "mount"]
    kind*: CommandKind
    summary*: string     ## one line, lowercase first word, no trailing period
    usage*: string       ## e.g. "ax vault mount <name> [mountpoint]"
    args*: seq[ArgSpec]
    flags*: seq[FlagSpec]
    deps*: seq[string]   ## the external commands checkDeps guards
    dryRun*: bool        ## true when the command implements -n itself

const specVersionCurrent* = 1

proc toJson*(s: CommandSpec): JsonNode =
  result = %*{
    "specVersion": s.specVersion,
    "path": s.path,
    "kind": $s.kind,
    "summary": s.summary,
    "usage": s.usage,
    "args": newJArray(),
    "flags": newJArray(),
    "deps": s.deps,
    "dryRun": s.dryRun
  }
  for a in s.args:
    result["args"].add %*{
      "name": a.name, "required": a.required,
      "variadic": a.variadic, "description": a.description
    }
  for f in s.flags:
    result["flags"].add %*{
      "long": f.long, "short": f.short,
      "takesValue": f.takesValue, "description": f.description
    }

proc commandSpecFromJson*(n: JsonNode): CommandSpec =
  ## Raises JsonKindError/KeyError on a malformed node; the caller
  ## (ax self build-registry, the driver's registry loader) turns that
  ## into its own diagnostic.
  result.specVersion = n["specVersion"].getInt
  for p in n["path"]:
    result.path.add p.getStr
  result.kind = parseEnum[CommandKind](n["kind"].getStr)
  result.summary = n["summary"].getStr
  result.usage = n["usage"].getStr
  for a in n["args"]:
    result.args.add ArgSpec(
      name: a["name"].getStr, required: a["required"].getBool,
      variadic: a["variadic"].getBool, description: a["description"].getStr)
  for f in n["flags"]:
    result.flags.add FlagSpec(
      long: f["long"].getStr, short: f["short"].getStr,
      takesValue: f["takesValue"].getBool, description: f["description"].getStr)
  for d in n["deps"]:
    result.deps.add d.getStr
  result.dryRun = n["dryRun"].getBool

proc axPreamble*(s: CommandSpec) =
  ## Runs before a command's run*(): answers --ax-spec, and refuses to run
  ## under AX_DRY_RUN=1 unless the spec declares dry-run support — so -n
  ## can never silently mutate through a command that ignores it.
  let params = commandLineParams()
  if params.len == 1 and params[0] == "--ax-spec":
    stdout.writeLine($s.toJson)
    quit(0)
  if not s.dryRun and getEnv("AX_DRY_RUN") == "1":
    error("ax " & s.path.join(" ") & " does not support --dry-run")
    quit(64)

template axMain*(s: CommandSpec, body: untyped) =
  ## Top-level boundary for an ax command binary. Supersedes lib/cli's
  ## cliMain for the commands/ tree: same CatchableError-to-exit-1
  ## contract, plus the --ax-spec and dry-run handling in axPreamble.
  axPreamble(s)
  try:
    quit(body)
  except CatchableError as e:
    error(e.msg)
    quit(1)
