import std/[os, terminal, algorithm, strutils]
import "../lib/output"

const groupedVerbs = """Common
    Add Clear Close Copy Enter Exit Find Format Get Hide Join Lock Move New Open
    Optimize Push Pop Redo Remove Rename Reset Resize Search Select Set Show
    Skip Split Step Switch Undo Unlock Watch
Communications
    Connect Disconnect Read Receive Send Write
Data
    Backup Checkpoint Compare Compress Convert ConvertFrom ConvertTo Dismount
    Edit Expand Export Group Import Initialize Limit Merge Mount Out Publish
    Restore Save Sync Unpublish Update
Diagnostic
    Debug Measure Ping Repair Resolve Test Trace
Lifecycle
    Approve Assert Build Complete Confirm Deny Deploy Disable Enable Install
    Invoke Register Request Restart Resume Start Stop Submit Suspend Uninstall
    Unregister Wait
Other
    Use
Security
    Block Grant Protect Revoke Unblock Unprotect"""

proc rawVerbs(): seq[string] =
  for line in groupedVerbs.splitLines():
    if line.startsWith("    "):
      for word in line.strip().splitWhitespace():
        result.add(word)
  result.sort()

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Get-Verb [--raw] [--group]

Display the approved verb list used for ZSH function naming conventions.

Options:
    -h, --help    Show this help message
    --group       Show verbs grouped by category (default)
    --raw         One verb per line, alphabetically sorted

Examples:
    Get-Verb
    Get-Verb --raw | grep -i convert"""
    return 0

  var raw = false
  for arg in args:
    if arg == "--raw":
      raw = true
    elif arg == "--group":
      discard
    elif arg.len > 0 and arg[0] == '-':
      error("Unknown option: " & arg, errp)
      return 1

  if raw or not isatty(outp):
    for verb in rawVerbs():
      outp.writeLine verb
  else:
    outp.writeLine groupedVerbs
  0

when isMainModule:
  quit(run(commandLineParams()))
