import std/[unittest, os]
import "../context"

template withCleanEnv(body: untyped) =
  ## Snapshots and clears the AX_* variables around body so a test's
  ## environment writes cannot leak into another test.
  let saved = [
    (axOutputEnv, getEnv(axOutputEnv)),
    (axDryRunEnv, getEnv(axDryRunEnv)),
    (axColorEnv, getEnv(axColorEnv)),
    (axQuietEnv, getEnv(axQuietEnv)),
    (axVerboseEnv, getEnv(axVerboseEnv))
  ]
  for (name, _) in saved:
    delEnv(name)
  try:
    body
  finally:
    for (name, value) in saved:
      if value.len > 0: putEnv(name, value) else: delEnv(name)

suite "context ctxFromEnv":
  test "defaults with a clean environment":
    withCleanEnv:
      let ctx = ctxFromEnv()
      check ctx.output == omTable
      check ctx.dryRun == false
      check ctx.color == cmAuto
      check ctx.quiet == false
      check ctx.verbose == false

  test "recognised values are read back":
    withCleanEnv:
      putEnv(axOutputEnv, "json")
      putEnv(axDryRunEnv, "1")
      putEnv(axColorEnv, "never")
      putEnv(axQuietEnv, "1")
      putEnv(axVerboseEnv, "1")
      let ctx = ctxFromEnv()
      check ctx.output == omJson
      check ctx.dryRun == true
      check ctx.color == cmNever
      check ctx.quiet == true
      check ctx.verbose == true

  test "unrecognised values fall back to the defaults instead of erroring":
    withCleanEnv:
      putEnv(axOutputEnv, "yaml")
      putEnv(axColorEnv, "sometimes")
      let ctx = ctxFromEnv()
      check ctx.output == omTable
      check ctx.color == cmAuto

suite "context exportCtx":
  test "round-trips through the environment":
    withCleanEnv:
      var ctx = ctxFromEnv()
      ctx.output = omPlain
      ctx.dryRun = true
      ctx.color = cmAlways
      exportCtx(ctx)
      check getEnv(axOutputEnv) == "plain"
      check getEnv(axDryRunEnv) == "1"
      check getEnv(axColorEnv) == "always"
      check ctxFromEnv() == ctx
