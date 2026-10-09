## ax — the nixotic toolbelt driver. Parses the cross-cutting flags,
## exports them as AX_* environment variables, resolves the command path
## against share/ax/registry.json, and execs the matching binary from
## libexec/ax/. All non-trivial logic lives in lib/driver.nim so the test
## suite can reach it; this file only wires it to the real process.
import std/[os, posix, strutils]
import lib/cli
import lib/context
import lib/driver
import lib/output
import lib/spec

const axVersion {.strdefine.} = "dev"

proc execBinary(binPath: string, args: seq[string], ctx: Ctx): int =
  ## Replaces the driver process with the command binary (exit codes and
  ## signals pass straight through). Ctx travels via the environment.
  exportCtx(ctx)
  let argv = allocCStringArray(@[binPath] & args)
  defer: deallocCStringArray(argv)
  discard execv(binPath.cstring, argv)
  error("cannot exec " & binPath & ": " & $strerror(errno))
  1

proc helpCmd(specs: seq[CommandSpec], groups: auto,
             paths: seq[seq[string]], words: seq[string],
             libexecDir: string, ctx: Ctx): int =
  if words.len == 0:
    return renderHelp(overviewText(specs, groups, axVersion))
  let res = resolveCommand(words, words.len, paths)
  case res.kind
  of rkFull:
    commandHelp(libexecDir / ("ax-" & res.path.join("-")), ctx)
  of rkPrefix:
    renderHelp(subtreeText(specs, groups, words))
  of rkNone:
    # Not in the ax tree: fall back to Get-Help's original role — render
    # ANY command's --help through bat (`ax help git commit`, `ax help fd`;
    # the `help`/`h` aliases lean on this daily).
    if findExe(words[0]).len > 0:
      return commandHelp(words[0], ctx, words[1 .. ^1])
    error("no such command or group: ax " & words.join(" "))
    if res.children.len > 0:
      stderr.writeLine("Available here: " & res.children.join(", "))
    64

proc main(): int =
  let ex = extractCommon(commandLineParams(), ctxFromEnv())
  # Builtins, diagnostics, help children and renderers all read AX_* too.
  exportCtx(ex.ctx)
  if ex.badFlag.len > 0:
    error(ex.badFlag)
    return 64
  if ex.version:
    echo "ax " & axVersion
    return 0

  let prefix = getAppFilename().parentDir.parentDir
  let libexecDir = prefix / "libexec" / "ax"
  let registryFile = prefix / "share" / "ax" / "registry.json"
  let groupsFile = prefix / "share" / "ax" / "groups.json"

  # self runs before the registry loads: `ax self build-registry` is what
  # CREATES the registry during the package build.
  if ex.words.len > 0 and ex.words[0] == "self":
    return selfCmd(ex.words[1 .. ^1], ex.ctx, libexecDir, registryFile,
                   groupsFile, help = ex.help)
  if ex.words.len > 1 and ex.words[0 .. 1] == @["help", "self"]:
    return selfCmd(ex.words[2 .. ^1], ex.ctx, libexecDir, registryFile,
                   groupsFile, help = true)
  if ex.words.len > 0 and ex.words[0] == "version":
    if ex.help:
      return renderHelp("Usage: ax version\nPrint the ax version.\n")
    if ex.words.len != 1:
      error("usage: ax version")
      return 64
    echo "ax " & axVersion
    return 0
  if ex.words.len > 1 and ex.words[0 .. 1] == @["help", "version"]:
    return renderHelp("Usage: ax version\nPrint the ax version.\n")

  let specs = loadRegistry(registryFile)
  let groups = loadGroups(groupsFile)
  let paths = registryPaths(specs)

  if ex.words.len == 0:
    return renderHelp(overviewText(specs, groups, axVersion))

  case ex.words[0]
  of "help":
    return helpCmd(specs, groups, paths, ex.words[1 .. ^1], libexecDir, ex.ctx)
  else:
    discard

  let res = resolveCommand(ex.words, ex.resolvable, paths)
  case res.kind
  of rkFull:
    let binPath = libexecDir / ("ax-" & res.path.join("-"))
    if ex.help:
      return commandHelp(binPath, ex.ctx)
    for s in specs:
      if s.path == res.path:
        if not validateInvocation(s, res.rest, ex.ctx.dryRun):
          return 64
        break
    execBinary(binPath, res.rest, ex.ctx)
  of rkPrefix:
    if ex.help:
      return renderHelp(subtreeText(specs, groups, ex.words))
    stderr.write(subtreeText(specs, groups, ex.words))
    64
  of rkNone:
    error("unknown command: ax " & ex.words.join(" "))
    let at = if res.deepest.len > 0: "ax " & res.deepest.join(" ") else: "ax"
    if res.children.len > 0:
      stderr.writeLine("Available under " & at & ": " &
                       res.children.join(", "))
    stderr.writeLine("Run `ax help` for the command tree.")
    64

when isMainModule:
  cliMain(main())
