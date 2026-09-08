import std/[os, terminal]
import "../../../lib/context"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["zfs", "snapshot", "list"],
  kind: ckVerb,
  summary: "list ZFS snapshots, newest first",
  usage: "ax zfs snapshot list [dataset]",
  args: @[
    ArgSpec(name: "dataset", required: false,
            description: "dataset name to filter snapshots")
  ],
  deps: @["zfs"],
  dryRun: false
)

type ParsedArgs* = object
  raw*: bool
  dataset*: string
  unknownOption*: string ## empty when no unknown option was encountered

proc parseArgs*(args: seq[string]): ParsedArgs =
  ## Mirrors the zsh original's `while`/`case` loop: `--raw` sets the flag
  ## and keeps looping; any other `-`-prefixed token is an unknown option
  ## and stops the loop immediately (matching the zsh original's `return 1`
  ## from inside the loop -- not a `break`, an actual early exit of the
  ## whole function); anything else is treated as the dataset name and
  ## OVERWRITES `dataset` each time, so with multiple non-flag args the
  ## LAST one wins.
  for arg in args:
    if arg == "--raw":
      result.raw = true
    elif arg.len > 0 and arg[0] == '-':
      result.unknownOption = arg
      return result
    else:
      result.dataset = arg

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax zfs snapshot list [dataset]

List all ZFS snapshots sorted by creation date (newest first).

Options:
    -h, --help    Show this help message
    --raw         Tab-separated output, no header (suitable for awk/grep);
                  deprecated alias for -o plain

Arguments:
    dataset       Optional dataset name to filter snapshots

Examples:
    ax zfs snapshot list
    ax zfs snapshot list dpool/data
    ax zfs snapshot list -o plain | awk -F'\t' '{print $1}'"""
    return 0

  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 64

  if not checkDeps(["zfs"], errp):
    return 2

  # The listing is zfs's own formatting, not the shared renderer: -o plain
  # (or --raw) maps to zfs list -H. AX_OUTPUT=json is ignored here.
  var zfsArgs = @["-r", "-t", "snapshot", "-S", "creation", "-o",
                  "name,used,referenced,creation"]
  if parsed.raw or ctxFromEnv().output == omPlain or not isatty(outp):
    zfsArgs.add("-H")

  if parsed.dataset.len > 0:
    zfsArgs.add(parsed.dataset)

  result = runner.runInherited("zfs", @["list"] & zfsArgs)

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
