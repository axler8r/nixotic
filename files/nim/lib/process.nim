## Every subprocess in files/nim/functions/ runs through this module.
##
## Two reasons it exists. First, correctness: osproc creates a pipe per
## stream, and a child that fills an undrained pipe blocks forever. Reading
## stdout to completion before touching stderr is a deadlock whenever the
## child writes enough to both. `capture` drains both concurrently.
##
## Second, testability: a Runner is a value, so a function takes the runner
## it should use rather than reaching for osproc directly. A test can
## therefore substitute its own implementation and assert exactly which
## command and arguments a function builds, with no process spawned. The
## shared recorder for that is `newRecordingRunner` in lib/testing.nim:
## it records every invocation and answers with canned values.
import std/[osproc, streams, strtabs]

type
  CommandResult* = object
    exitCode*: int
    output*: string
    error*: string

  Runner* = ref object
    runInheritedImpl*: proc (cmd: string, args: seq[string],
                             env: StringTableRef): int
    captureImpl*: proc (cmd: string, args: seq[string],
                        input: string): CommandResult

proc runInherited*(r: Runner, cmd: string, args: seq[string],
                   env: StringTableRef = nil): int =
  ## Runs `cmd` with the parent's real stdin/stdout/stderr. For output that
  ## must stream to the user live.
  ##
  ## A nil `env`, the default, gives the child this process's own
  ## environment. Pass a table only to override it wholesale: the table
  ## replaces the environment rather than adding to it, so it must carry
  ## every variable the child needs, PATH included.
  r.runInheritedImpl(cmd, args, env)

proc capture*(r: Runner, cmd: string, args: seq[string],
              input = ""): CommandResult =
  ## Runs `cmd` with both output streams captured and drained concurrently.
  ## `input`, when non-empty, is written to the child's stdin.
  ##
  ## Both streams are accumulated in memory in full, so this is for command
  ## output sized for a terminal, not for arbitrarily large data.
  ##
  ## Writing `input` is best-effort. A child that exits, or closes its
  ## stdin, before reading the whole payload is not an error: the write
  ## stops there, the child is still reaped, and the call returns that
  ## child's real exit code along with whatever it did emit. `capture`
  ## raises nothing in that case, because for a program piping into a pager
  ## or a `head`-shaped filter an early exit is the normal outcome and the
  ## exit code is the answer the caller wants. A caller that must know the
  ## payload arrived in full has to arrange its own acknowledgement.
  r.captureImpl(cmd, args, input)

proc runQuiet*(r: Runner, cmd: string, args: seq[string]): int =
  ## Runs `cmd`, discarding both output streams, returning the exit code.
  ## Drains rather than ignoring the pipes, so it cannot deadlock.
  ##
  ## Draining means the output is read into memory before being discarded;
  ## this saves nothing over `capture` but the caller's attention.
  r.capture(cmd, args).exitCode

type DrainArg = tuple[s: Stream, dest: ptr string]

proc drainProc(arg: DrainArg) {.thread.} =
  arg.dest[] = arg.s.readAll()

proc realRunInherited(cmd: string, args: seq[string],
                      env: StringTableRef): int =
  var p = startProcess(cmd, args = args, env = env,
                       options = {poUsePath, poParentStreams})
  defer: p.close()
  p.waitForExit()

proc realCapture(cmd: string, args: seq[string],
                 input: string): CommandResult =
  var p = startProcess(cmd, args = args, options = {poUsePath})

  var outBuf, errBuf: string
  var outThread, errThread: Thread[DrainArg]
  # Drain threads start BEFORE stdin is written. A child that answers while
  # we are still writing would otherwise fill its stdout pipe and block,
  # while we block filling its stdin pipe.
  createThread(outThread, drainProc, (p.outputStream, addr outBuf))
  createThread(errThread, drainProc, (p.errorStream, addr errBuf))

  try:
    try:
      if input.len > 0:
        p.inputStream.write(input)
    except IOError:
      # The child stopped reading: Nim ignores SIGPIPE process-wide, so a
      # dead reader surfaces here as EPIPE rather than as a signal. Per the
      # `capture` contract this is not an error, but it MUST NOT skip the
      # reaping below, or the drain threads outlive the streams they read
      # and the child is never waited for.
      discard
    finally:
      # Give the child EOF, join both drains, and only then let p.close()
      # near the end of this proc pull the streams out from under them.
      try:
        p.inputStream.close()
      except CatchableError:
        discard
      joinThread(outThread)
      joinThread(errThread)

    result.exitCode = p.waitForExit()
    result.output = outBuf
    result.error = errBuf
  finally:
    p.close()

let defaultRunner* = Runner(
  runInheritedImpl: realRunInherited,
  captureImpl: realCapture
)
