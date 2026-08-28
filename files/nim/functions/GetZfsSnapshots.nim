import std/[os, osproc, terminal]
import "../lib/cli"
import "../lib/output"
import "../lib/validation"

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
  ## LAST one wins (e.g. `Get-ZfsSnapshots foo bar` ends with `bar`).
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
  errp: File = stderr
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Get-ZfsSnapshots [--raw] [dataset]

List all ZFS snapshots sorted by creation date (newest first).

Options:
    -h, --help    Show this help message
    --raw         Tab-separated output, no header (suitable for awk/grep)

Arguments:
    dataset       Optional dataset name to filter snapshots

Examples:
    Get-ZfsSnapshots
    Get-ZfsSnapshots dpool/data
    Get-ZfsSnapshots --raw | awk -F'\t' '{print $1}'"""
    return 0

  let parsed = parseArgs(args)
  if parsed.unknownOption.len > 0:
    error("Unknown option: " & parsed.unknownOption, errp)
    return 1

  if not checkDeps(["zfs"], errp):
    return 2

  var zfsArgs = @["-r", "-t", "snapshot", "-S", "creation", "-o",
                  "name,used,referenced,creation"]
  if parsed.raw or not isatty(outp):
    zfsArgs.add("-H")

  if parsed.dataset.len > 0:
    zfsArgs.add(parsed.dataset)

  var p = startProcess("zfs", args = @["list"] & zfsArgs,
                        options = {poUsePath, poParentStreams})
  let code = p.waitForExit()
  p.close()
  code

when isMainModule:
  cliMain(run(commandLineParams()))
