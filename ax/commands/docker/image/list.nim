import std/[os, algorithm, strutils]
import "../../../lib/context"
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["docker", "image", "list"],
  kind: ckVerb,
  summary: "list local Docker images",
  usage: "ax docker image list [--dangling]",
  flags: @[
    FlagSpec(long: "dangling", takesValue: false,
             description: "only dangling images (untagged, unreferenced)")
  ],
  deps: @["docker"],
  dryRun: false
)

proc parseDockerList*(output: string): seq[string] =
  ## Splits `docker ... list` output on newlines, dropping the empty
  ## trailing line `splitLines` produces for a final "\n" (and any other
  ## blank lines) — matches the identical helper in prune.nim and the
  ## volume commands.
  result = @[]
  for line in output.splitLines():
    if line.len == 0: continue
    result.add(line)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax docker image list [--dangling]

List installed Docker images. By default dangling images are excluded;
--dangling lists ONLY the dangling ones (untagged, not referenced by any
container), adding a Size column.

Options:
    -h, --help    Show this help message
    --dangling    Only dangling images
    --raw         Deprecated alias for -o plain

Examples:
    ax docker image list
    ax docker image list --dangling
    ax docker image list -o json | jq '.[].repository'"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  var ctx = ctxFromEnv()
  var dangling = false
  for arg in args:
    if arg == "--raw":
      ctx.output = omPlain
    elif arg == "--dangling":
      dangling = true

  if not checkDeps(["docker"], errp): return 2

  let format =
    if dangling:
      "--format={{.Repository}}|{{.Tag}}|{{.CreatedSince}}|{{.Size}}|{{.ID}}"
    else:
      "--format={{.Repository}}|{{.Tag}}|{{.CreatedSince}}|{{.ID}}"
  let filter =
    if dangling: "--filter=dangling=true" else: "--filter=dangling=false"
  let header =
    if dangling: @["Repository", "Tag", "Created", "Size", "ID"]
    else: @["Repository", "Tag", "Created", "ID"]

  let listing = runner.capture(
    "docker", @["image", "list", format, filter])
  if listing.exitCode != 0:
    error("Cannot list Docker images: " & listing.error.strip(), errp)
    return 1
  var lines = parseDockerList(listing.output)
  lines.sort()
  var rows: seq[seq[string]] = @[]
  for line in lines:
    rows.add line.split("|")

  # Blank-line padding is cosmetic gum spacing; plain and json output stay
  # unpadded so they remain script- and jq-clean.
  if ctx.output == omTable:
    outp.writeLine("")
  let renderCode = render(header, rows, ctx, runner, outp, errp)
  if ctx.output == omTable:
    outp.writeLine("")
  return renderCode

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
