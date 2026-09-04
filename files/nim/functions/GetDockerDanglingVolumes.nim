import std/[os, strutils]
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
    outp.writeLine """Usage: Get-DockerDanglingVolumes [--raw]

List all dangling Docker volumes (not attached to any container).

Options:
    -h, --help    Show this help message
    --raw         Plain text output

Examples:
    Get-DockerDanglingVolumes
    Get-DockerDanglingVolumes --raw | awk -F'|' '{print $2}'"""
    return 0

  var raw = false
  for arg in args:
    if arg == "--raw":
      raw = true

  if not checkDeps(["docker"], errp): return 2

  let listing = runner.capture(
    "docker",
    @["volume", "list", "--filter=dangling=true", "--format={{.Driver}}|{{.Name}}"]
  ).output
  let volumes = parseDockerList(listing)

  if volumes.len == 0:
    outp.writeLine("No dangling volumes found.")
    return 0

  outp.writeLine("")
  discard table("Driver|Volume Name\n" & volumes.join("\n"), raw, runner, outp, errp)
  outp.writeLine("")
  return 0

when isMainModule:
  cliMain(run(commandLineParams()))
