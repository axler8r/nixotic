import std/os
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"

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

  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 64
  if parsed.unexpectedArg.len > 0:
    error("Unexpected argument: " & parsed.unexpectedArg, errp)
    return 64

  if not fileExists("flake.nix"):
    error("No flake.nix found in current directory", errp)
    return 1

  if not confirm("Remove dev environment in " & lastPathPart(getCurrentDir()) & "?", inp, outp):
    return 0

  if fileExists("flake.nix"):
    removeFile("flake.nix")
    outp.writeLine("Removed flake.nix")
  if fileExists(".envrc"):
    removeFile(".envrc")
    outp.writeLine("Removed .envrc")
  if dirExists(".direnv"):
    removeDir(".direnv")
    outp.writeLine("Removed .direnv/")

  if parsed.gc:
    outp.writeLine("Collecting unreachable Nix store paths...")
    return runner.runInherited("nix", @["store", "gc"])

  0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
