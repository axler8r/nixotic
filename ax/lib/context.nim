## The cross-cutting execution context (Ctx) every ax command shares:
## output mode, dry-run, colour, quiet, verbose. The driver owns the flags
## (-o, -n, --color, -q, -v) and passes the resolved values down as AX_*
## environment variables; command binaries read Ctx exclusively from the
## environment, so a binary behaves identically whether reached through
## `ax` or invoked directly from libexec/ax/ with AX_* set.
import std/os

const
  axOutputEnv* = "AX_OUTPUT"
  axDryRunEnv* = "AX_DRY_RUN"
  axColorEnv* = "AX_COLOR"
  axQuietEnv* = "AX_QUIET"
  axVerboseEnv* = "AX_VERBOSE"

type
  OutputMode* = enum
    omTable = "table"
    omPlain = "plain"
    omJson = "json"

  ColorMode* = enum
    cmAuto = "auto"
    cmAlways = "always"
    cmNever = "never"

  Ctx* = object
    output*: OutputMode
    dryRun*: bool
    color*: ColorMode
    quiet*: bool
    verbose*: bool

proc ctxFromEnv*(): Ctx =
  ## Unset or unrecognised values fall back to the defaults (table, auto)
  ## rather than erroring: only the driver validates flag values; a stray
  ## AX_OUTPUT from an unrelated environment must not break a binary.
  result.output =
    case getEnv(axOutputEnv)
    of "plain": omPlain
    of "json": omJson
    else: omTable
  result.dryRun = getEnv(axDryRunEnv) == "1"
  result.color =
    case getEnv(axColorEnv)
    of "always": cmAlways
    of "never": cmNever
    else: cmAuto
  result.quiet = getEnv(axQuietEnv) == "1"
  result.verbose = getEnv(axVerboseEnv) == "1"

proc exportCtx*(ctx: Ctx) =
  ## Writes ctx back into the environment for a child process (the driver
  ## calls this immediately before exec'ing a command binary).
  putEnv(axOutputEnv, $ctx.output)
  putEnv(axDryRunEnv, if ctx.dryRun: "1" else: "")
  putEnv(axColorEnv, $ctx.color)
  putEnv(axQuietEnv, if ctx.quiet: "1" else: "")
  putEnv(axVerboseEnv, if ctx.verbose: "1" else: "")
