import std/[os, osproc, strutils]
import "../lib/cli"
import "../lib/process"
import "../lib/validation"

proc parseDockerList*(output: string): seq[string] =
  ## Splits `docker ... list` output on newlines, dropping the empty
  ## trailing line `splitLines` produces for a final "\n" (and any other
  ## blank lines, matching zsh's `${(f)_volumes}` word-split-on-newline,
  ## which never yields empty words from a well-formed docker listing).
  result = @[]
  for line in output.splitLines():
    if line.len == 0: continue
    result.add(line)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Remove-DockerDanglingVolumes

Remove all dangling Docker volumes (volumes not attached to any container).

Options:
    -h, --help    Show this help message

Examples:
    Remove-DockerDanglingVolumes"""
    return 0

  if not checkDeps(["docker"], errp): return 2

  let listing = defaultRunner.capture(
    "docker",
    @["volume", "list", "--quiet", "--filter=dangling=true"]
  ).output
  let volumes = parseDockerList(listing)

  if volumes.len == 0:
    outp.writeLine("No dangling volumes to remove.")
    return 0

  for volume in volumes:
    outp.writeLine("Removing volume: " & volume)
    var p = startProcess("docker", args = @["volume", "rm", volume], options = {poUsePath, poParentStreams})
    let code = p.waitForExit()
    p.close()
    if code != 0:
      return 1

  return 0

when isMainModule:
  cliMain(run(commandLineParams()))
