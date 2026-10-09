## CommandSpec: the machine-readable self-description every ax command
## binary carries. A binary answers the hidden `--ax-spec` flag with its
## spec as JSON; the build concatenates those answers into
## share/ax/registry.json, which is the sole source for dispatch, help,
## and completion. A registry derived from the binaries actually built
## cannot disagree with them.
import std/[json, os, strutils]
import lexicon
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

proc validPathSegment*(word: string): bool =
  word.len > 0 and word[0] in {'a'..'z'} and
    word.allCharsInSet({'a'..'z', '0'..'9'})

proc invalidSpec(message: string) {.noreturn.} =
  raise newException(ValueError, "invalid command spec: " & message)

proc singleLine(text: string): bool =
  text.strip().len > 0 and '\n' notin text and '\r' notin text and '\0' notin text

proc validateSpec*(s: CommandSpec) =
  ## Shared semantic checks for decoded specs and generated scaffolds.
  ## Global flags belong to the driver, never to a command's flag table.
  if s.specVersion != specVersionCurrent:
    invalidSpec("unsupported specVersion " & $s.specVersion)
  if s.path.len notin 2 .. 3:
    invalidSpec("path depth must be 2 or 3")
  for word in s.path:
    if not validPathSegment(word):
      invalidSpec("path segment '" & word & "' must match [a-z][a-z0-9]*")
  if s.path[0] in ["help", "version", "self"]:
    invalidSpec("path uses a reserved builtin group")
  let leaf = s.path[^1]
  if not isAllowedLeaf(leaf):
    invalidSpec("leaf '" & leaf & "' is not a lexicon verb or report-noun")
  if (s.kind == ckReport) != (leaf in reportNouns):
    invalidSpec("kind does not match the lexicon for '" & leaf & "'")
  if not singleLine(s.summary):
    invalidSpec("summary must be a nonempty single line")
  let invocation = "ax " & s.path.join(" ")
  if not singleLine(s.usage) or
     not (s.usage == invocation or s.usage.startsWith(invocation & " ")):
    invalidSpec("usage must begin with '" & invocation & "'")

  var argNames, longNames, shortNames, deps: seq[string]
  var optionalSeen = false
  for i, a in s.args:
    if not singleLine(a.name) or a.name.contains(' ') or a.name in argNames:
      invalidSpec("argument names must be nonempty and unique")
    argNames.add a.name
    if a.required and optionalSeen:
      invalidSpec("required argument follows an optional argument")
    optionalSeen = optionalSeen or not a.required
    if a.variadic and i != s.args.high:
      invalidSpec("only the last argument may be variadic")
  for f in s.flags:
    if f.long.len == 0 and f.short.len == 0:
      invalidSpec("flag needs a long or short name")
    if f.long.len > 0:
      if f.long[0] notin {'a'..'z'} or
         not f.long.allCharsInSet({'a'..'z', '0'..'9', '-'}) or
         f.long.endsWith("-") or f.long in longNames:
        invalidSpec("invalid or duplicate long flag '" & f.long & "'")
      if f.long in ["output", "raw", "dry-run", "color", "quiet", "verbose",
                    "help", "version", "ax-spec"]:
        invalidSpec("reserved global flag --" & f.long)
      longNames.add f.long
    if f.short.len > 0:
      if f.short.len != 1 or
         not f.short.allCharsInSet({'a'..'z', 'A'..'Z', '0'..'9'}) or
         f.short in shortNames:
        invalidSpec("invalid or duplicate short flag '" & f.short & "'")
      if f.short in ["o", "n", "q", "v", "h", "V"]:
        invalidSpec("reserved global flag -" & f.short)
      shortNames.add f.short
  for dep in s.deps:
    if dep.len == 0 or dep.contains({' ', '\t', '\r', '\n', '\0'}) or dep in deps:
      invalidSpec("dependencies must be nonempty, unique executable names")
    deps.add dep

proc requireKind(n: JsonNode, kind: JsonNodeKind, label: string) =
  if n.isNil or n.kind != kind:
    invalidSpec(label & " must be " & $kind)

proc requireFields(n: JsonNode, fields: openArray[string], label: string) =
  requireKind(n, JObject, label)
  for field in fields:
    if not n.hasKey(field):
      invalidSpec(label & " is missing " & field)
  for field, value in n:
    if field notin fields:
      invalidSpec(label & " has unknown field " & field)

proc field(n: JsonNode, name: string, kind: JsonNodeKind): JsonNode =
  result = n[name]
  requireKind(result, kind, name)

proc commandSpecFromJson*(n: JsonNode): CommandSpec =
  ## JsonNode getters silently default on wrong kinds. Check the entire
  ## schema explicitly before decoding, then validate its semantics.
  requireFields(n, ["specVersion", "path", "kind", "summary", "usage",
                    "args", "flags", "deps", "dryRun"], "spec")
  let version = field(n, "specVersion", JInt).getBiggestInt
  if version != specVersionCurrent:
    invalidSpec("unsupported specVersion " & $version)
  result.specVersion = specVersionCurrent
  for p in field(n, "path", JArray):
    requireKind(p, JString, "path segment")
    result.path.add p.getStr
  let kind = field(n, "kind", JString).getStr
  if kind notin ["verb", "report"]:
    invalidSpec("kind must be verb or report")
  result.kind = parseEnum[CommandKind](kind)
  result.summary = field(n, "summary", JString).getStr
  result.usage = field(n, "usage", JString).getStr
  for a in field(n, "args", JArray):
    requireFields(a, ["name", "required", "variadic", "description"], "argument")
    result.args.add ArgSpec(
      name: field(a, "name", JString).getStr,
      required: field(a, "required", JBool).getBool,
      variadic: field(a, "variadic", JBool).getBool,
      description: field(a, "description", JString).getStr)
  for f in field(n, "flags", JArray):
    requireFields(f, ["long", "short", "takesValue", "description"], "flag")
    result.flags.add FlagSpec(
      long: field(f, "long", JString).getStr,
      short: field(f, "short", JString).getStr,
      takesValue: field(f, "takesValue", JBool).getBool,
      description: field(f, "description", JString).getStr)
  for d in field(n, "deps", JArray):
    requireKind(d, JString, "dependency")
    result.deps.add d.getStr
  result.dryRun = field(n, "dryRun", JBool).getBool
  validateSpec(result)

proc validateArgs*(s: CommandSpec, args: openArray[string],
                   errp: File = stderr): bool =
  ## Run after a command's help branch and before dependencies or effects.
  ## Accept --long=value and the existing -eVALUE/-e=VALUE/-e:VALUE forms;
  ## boolean short flags are not clustered. `--` ends option recognition.
  var positional = 0
  var variadicSupplied = false
  var positionalOnly = false
  var i = 0
  while i < args.len:
    let token = args[i]
    if not positionalOnly and token == "--":
      positionalOnly = true
      inc i
      continue
    if not positionalOnly and token.len > 1 and token[0] == '-':
      # Compatibility for direct libexec callers; the driver consumes this
      # global alias, so it must never be redeclared in a command spec.
      if token == "--raw":
        inc i
        continue
      if s.dryRun and token in ["-n", "--dry-run"]:
        inc i
        continue
      var found = -1
      var attached = false
      var value = ""
      for j, flag in s.flags:
        if flag.long.len > 0 and token == "--" & flag.long:
          found = j
          break
        if flag.long.len > 0 and token.startsWith("--" & flag.long & "="):
          found = j
          attached = true
          value = token[flag.long.len + 3 .. ^1]
          break
        if flag.short.len > 0 and token.startsWith("-" & flag.short):
          found = j
          attached = token.len > 2
          if attached:
            value = token[2 .. ^1]
            if value[0] in {'=', ':'}: value = value[1 .. ^1]
          break
      if found < 0:
        error("Unknown option: " & token, errp)
        return false
      if s.flags[found].takesValue:
        if not attached:
          if i + 1 >= args.len or args[i + 1].startsWith("-"):
            error("Missing value for " & token, errp)
            return false
          inc i
          value = args[i]
        if value.len == 0:
          error("Missing value for " & token, errp)
          return false
      elif attached:
        error("Option does not take a value: " & token, errp)
        return false
    else:
      if positional >= s.args.len:
        error("Unexpected argument: " & token, errp)
        return false
      if s.args[positional].required and token.len == 0:
        error("Missing required argument: " & s.args[positional].name, errp)
        return false
      if not s.args[positional].variadic:
        inc positional
      else:
        variadicSupplied = true
    inc i
  for j in positional ..< s.args.len:
    if s.args[j].required:
      # A final required variadic slot is satisfied by at least one positional.
      if s.args[j].variadic and variadicSupplied:
        continue
      error("Missing required argument: " & s.args[j].name, errp)
      return false
  true

proc validateInvocation*(s: CommandSpec, args: openArray[string],
                         dryRun: bool, errp: File = stderr): bool =
  ## Help must bypass both missing-argument and unsupported-dry-run checks.
  ## Match run*'s help-first contract; --help after `--` is only data.
  if args.len > 0 and args[0] in ["-h", "--help"]:
    return true
  if dryRun and not s.dryRun:
    error("ax " & s.path.join(" ") & " does not support --dry-run", errp)
    return false
  validateArgs(s, args, errp)

proc axPreamble*(s: CommandSpec) =
  ## Runs before a command's run*(): answers --ax-spec, and refuses to run
  ## under AX_DRY_RUN=1 unless the spec declares dry-run support — so -n
  ## can never silently mutate through a command that ignores it.
  let params = commandLineParams()
  if params.len == 1 and params[0] == "--ax-spec":
    stdout.writeLine($s.toJson)
    quit(0)
  if not validateInvocation(s, params, getEnv("AX_DRY_RUN") == "1"):
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
