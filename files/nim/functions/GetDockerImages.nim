import std/[os, algorithm, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"

proc parseDockerList*(output: string): seq[string] =
  ## Splits `docker ... list` output on newlines, dropping the empty
  ## trailing line `splitLines` produces for a final "\n" (and any other
  ## blank lines) — matches the identical helper in
  ## RemoveDockerDanglingImages.nim/RemoveDockerDanglingVolumes.nim.
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
    outp.writeLine """Usage: Get-DockerImages [--raw]

List all installed Docker images (excluding dangling).

Options:
    -h, --help    Show this help message
    --raw         Plain text output

Examples:
    Get-DockerImages
    Get-DockerImages --raw | grep nginx"""
    return 0

  var raw = false
  for arg in args:
    if arg == "--raw":
      raw = true

  if not checkDeps(["docker"], errp): return 2

  let listing = runner.capture(
    "docker",
    @["image", "list", "--format={{.Repository}}|{{.Tag}}|{{.CreatedSince}}|{{.ID}}",
      "--filter=dangling=false"]
  ).output
  var rows = parseDockerList(listing)
  rows.sort()

  outp.writeLine("")
  discard table("Repository|Tag|Created|ID\n" & rows.join("\n"), raw, runner, outp, errp)
  outp.writeLine("")
  return 0

when isMainModule:
  cliMain(run(commandLineParams()))
