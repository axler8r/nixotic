import std/[os, posix]
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["dev", "remove"],
  kind: ckVerb,
  summary: "remove the dev environment from the current directory",
  usage: "ax dev remove [--gc]",
  flags: @[
    FlagSpec(long: "gc", takesValue: false,
             description: "run nix store gc after removal")
  ],
  dryRun: false
)

type ParsedArgs* = object
  gc*: bool
  unknownOption*: string
  unexpectedArg*: string

proc parseArgs*(args: seq[string]): ParsedArgs =
  ## Mirrors the zsh original's while/case loop: --gc sets the flag and
  ## keeps looping (so a later bad token is still caught); any other
  ## `-`-prefixed token is an unknown option and any other token is an
  ## unexpected positional argument, both stopping the loop immediately
  ## (an actual early exit, matching the zsh original's `return 1` from
  ## inside the loop -- not a `break`).
  for a in args:
    if a == "--gc":
      result.gc = true
    elif a.len > 0 and a[0] == '-':
      result.unknownOption = a
      return result
    else:
      result.unexpectedArg = a
      return result

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner,
  inp: File = stdin
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax dev remove [opts]

Description:
    Remove a direnv + Nix Flakes development environment from the current
    directory. Deletes flake.nix, .envrc, and .direnv/ (including the
    nix-direnv GC root that pins store paths). Run --gc to also collect
    unreachable Nix store paths.

Options:
    -h, --help    Show this help message
    --gc          Run nix store gc after removal

Examples:
    ax dev remove        # Remove dev environment in current directory
    ax dev remove --gc   # Remove and collect unreachable Nix store paths"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64
  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 64
  if parsed.unexpectedArg.len > 0:
    error("Unexpected argument: " & parsed.unexpectedArg, errp)
    return 64

  if parsed.gc and not checkDeps(["nix"], errp): return 2

  # Discover the entire post-order deletion plan before removing anything.
  # In particular, Nim's removeDir traverses a top-level directory symlink.
  var plan: seq[tuple[path: string, directory: bool]] = @[]
  proc collect(path: string) =
    let kind = getFileInfo(path, followSymlink = false).kind
    if access(parentDir(absolutePath(path)).cstring, W_OK or X_OK) != 0:
      raise newException(IOError, "Cannot remove '" & path & "': parent is not writable")
    if kind == pcDir:
      for _, child in walkDir(path, checkDir = true):
        collect(child)
    plan.add((path, kind == pcDir))

  try:
    if not fileExists("flake.nix"):
      error("No flake.nix found in current directory", errp)
      return 1
    for path in ["flake.nix", ".envrc", ".direnv"]:
      var st: Stat
      if lstat(path.cstring, st) != 0:
        if errno == ENOENT: continue
        raiseOSError(osLastError(), path)
      if path == ".direnv":
        if not S_ISDIR(st.st_mode):
          error("Refusing .direnv: expected a directory, not a symlink or file", errp)
          return 1
      elif not (S_ISREG(st.st_mode) or S_ISLNK(st.st_mode)):
        error("Refusing '" & path & "': expected a file or symlink", errp)
        return 1
      collect(path)
  except IOError, OSError:
    error("Cannot plan removal: " & getCurrentExceptionMsg(), errp)
    return 1

  if not confirm("Remove dev environment in " & lastPathPart(getCurrentDir()) & "?", inp, outp):
    return 0

  try:
    for item in plan:
      if item.directory:
        # Non-recursive rmdir cannot start traversing a substituted symlink.
        if posix.rmdir(item.path.cstring) != 0:
          raiseOSError(osLastError(), item.path)
      else:
        removeFile(item.path)
      if item.path in ["flake.nix", ".envrc", ".direnv"]:
        outp.writeLine("Removed " & item.path & (if item.directory: "/" else: ""))
  except IOError, OSError:
    error("Removal failed: " & getCurrentExceptionMsg(), errp)
    return 1

  if parsed.gc:
    outp.writeLine("Collecting unreachable Nix store paths...")
    return runner.runInherited("nix", @["store", "gc"])

  0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
