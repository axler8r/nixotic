import std/os
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["script", "create"],
  kind: ckVerb,
  summary: "write stdin to an executable zsh script",
  usage: "ax script create <filename>",
  args: @[
    ArgSpec(name: "filename", required: true,
            description: "the script file to create")
  ],
  deps: @["chmod"],
  dryRun: false
)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  inp: File = stdin,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax script create <filename>

Read input from stdin and write it to a script file adding a zsh shebang at
the top of the file, and making it executable.

Options:
    -h, --help  Show this help message

Examples:
    ax git repo root -o plain | sed -e 's/^/git clone /' | ax script create clone-gitrepository
    echo 'foreach file in *(.); do echo $file; done' | ax script create list-file"""
    return 0

  if not validateArgs(cmdSpec, args, errp): return 64

  let positional = if args[0] == "--": args[1 .. ^1] else: args
  let filename = positional[0]

  if not requireArg(filename, "filename", errp): return 64
  if not checkDeps(["chmod"], errp): return 2

  var content = inp.readAll()
  # `$(cat)` (command substitution) strips all trailing newlines from
  # captured output -- verified against real zsh, not just the one
  # nearest EOF. Interior newlines are left untouched.
  while content.len > 0 and content[^1] == '\n':
    content.setLen(content.len - 1)

  var outFile: File
  try:
    outFile = open(filename, fmWrite)
  except IOError, OSError:
    error("Cannot write to '" & filename & "': " & getCurrentExceptionMsg(), errp)
    return 1
  outFile.writeLine("#! /usr/bin/env zsh")
  outFile.writeLine("")
  outFile.writeLine(content)
  outFile.close()

  if runner.runInherited("chmod", @["+x", "--", filename]) != 0:
    error("Could not make script executable: " & filename, errp)
    return 1

  success("Created executable script: " & filename, errp)
  return 0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
