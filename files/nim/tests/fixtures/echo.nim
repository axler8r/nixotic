## Executable boundary fixture; never packaged as an ax command.
import std/[json, os]
import "../../lib/spec"

let cmdSpec = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["test", "get"],
  summary: "report received arguments and context",
  usage: "ax test get [--fail] [--throw] [args...]",
  args: @[ArgSpec(name: "args", variadic: true)],
  flags: @[FlagSpec(long: "fail"), FlagSpec(long: "throw")])

proc run(args: seq[string]): int =
  if args == @["--help"]:
    echo "Usage: ax test get"
    return 0
  if args == @["--fail"]: return 7
  if args == @["--throw"]: raise newException(IOError, "fixture exception")
  echo $(%*{"args": args, "output": getEnv("AX_OUTPUT"),
            "color": getEnv("AX_COLOR"), "quiet": getEnv("AX_QUIET")})

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
