import std/[os, strutils, terminal]
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
  var hasDataset = false
  var positionalOnly = false
  for arg in args:
    if not positionalOnly and arg == "--":
      positionalOnly = true
    elif not positionalOnly and arg == "--raw":
      result.raw = true
    elif not positionalOnly and arg.len > 1 and arg[0] == '-':
      result.unknownOption = arg
      return result
    else:
      if hasDataset:
        result.unknownOption = "extra dataset: " & arg
        return
      result.dataset = arg
      hasDataset = true

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

  if not validateArgs(cmdSpec, args, errp): return 64

  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 64

  if not checkDeps(["zfs"], errp):
    return 2

  let ctx = ctxFromEnv()
  # Preserve native table/plain output; JSON uses the shared renderer.
  var zfsArgs = @["-r", "-t", "snapshot", "-S", "creation", "-o",
                  "name,used,referenced,creation"]
  if parsed.raw or ctx.output != omTable or not isatty(outp):
    zfsArgs.add("-H")

  if parsed.dataset.len > 0:
    zfsArgs.add(parsed.dataset)

  if ctx.output == omJson and not parsed.raw:
    let listing = runner.capture("zfs", @["list"] & zfsArgs)
    if listing.exitCode != 0:
      error("Cannot list ZFS snapshots: " & listing.error.strip(), errp)
      return 1
    var rows: seq[seq[string]] = @[]
    for line in listing.output.splitLines():
      if line.len > 0: rows.add(line.split('\t', maxsplit = 3))
    return render(@["Name", "Used", "Referenced", "Creation"], rows, ctx, runner, outp, errp)
  result = runner.runInherited("zfs", @["list"] & zfsArgs)

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
