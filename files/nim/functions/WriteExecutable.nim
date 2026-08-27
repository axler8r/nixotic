import std/[os, osproc]
import "../lib/validation"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  inp: File = stdin
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Write-Executable <filename>

Read input from stdin and write it to a script file adding a zsh shebang at
the top of the file, and making it executable.

Options:
    -h, --help  Show this help message

Examples:
    Resolve-GitPathRepository | sed -e 's/^/git clone /' | Write-Executable clone-gitrepository
    echo 'foreach file in *(.); do echo $file; done' | Write-Executable list-file"""
    return 0

  # No option handling at all -- every positional arg overwrites `filename`
  # in turn, so the LAST arg wins if more than one is given. This matches
  # the zsh original's catch-all `case` branch exactly; do not add "too
  # many arguments" validation the original doesn't have.
  var filename = ""
  for a in args:
    filename = a

  if not requireArg(filename, "filename", errp): return 1
  if not checkDeps(["chmod"], errp): return 2

  var content = inp.readAll()
  # `$(cat)` (command substitution) strips all trailing newlines from
  # captured output -- verified against real zsh, not just the one
  # nearest EOF. Interior newlines are left untouched.
  while content.len > 0 and content[^1] == '\n':
    content.setLen(content.len - 1)

  let outFile = open(filename, fmWrite)
  outFile.writeLine("#! /usr/bin/env zsh")
  outFile.writeLine("")
  outFile.writeLine(content)
  outFile.close()

  var chmodProc = startProcess(
    "chmod",
    args = @["+x", filename],
    options = {poUsePath, poParentStreams}
  )
  discard chmodProc.waitForExit()
  chmodProc.close()

  outp.writeLine("Created executable script: " & filename)
  return 0

when isMainModule:
  quit(run(commandLineParams()))
