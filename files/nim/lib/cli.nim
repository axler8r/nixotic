import output

template cliMain*(body: untyped) =
  ## Top-level boundary for a function's entry point. Any CatchableError
  ## that escapes `run()` becomes an `Error:` line on stderr and exit 1,
  ## preserving the stdout=data/stderr=status contract instead of printing
  ## a Nim traceback. Local try/except in a function is still preferred
  ## where a specific message beats the raw exception text.
  try:
    quit(body)
  except CatchableError as e:
    error(e.msg)
    quit(1)
