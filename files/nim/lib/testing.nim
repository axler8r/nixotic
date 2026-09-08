## Test-only helpers. Never imported by a function, so this module never
## links into a shipped binary. Lives outside lib/tests/ so the flake's
## test globs do not compile it as a test suite of its own.
import std/[os, strtabs]
import process

let pristinePath = getEnv("PATH")
  ## Captured once, at module init, before any test can have called
  ## withPath. Baked into every fake's script body so a fake can still
  ## call real external utilities (cat, wc, ...) even while withPath has
  ## replaced the test process's own $PATH with a fixture directory.

proc writeFakeExe*(dir, name, script: string) =
  ## Writes an executable /bin/sh script at dir/name. Used to stand in for
  ## a real external command on a temporary $PATH. The pristine $PATH is
  ## baked in so the fake's own body can call real utilities (cat, wc)
  ## even while withPath has replaced the test process's $PATH with a
  ## fixture dir.
  let path = dir / name
  writeFile(path, "#!/bin/sh\nPATH=" & pristinePath.quoteShell & "\nexport PATH\n" &
                  script & "\n")
  setFilePermissions(path, {fpUserRead, fpUserWrite, fpUserExec})

proc fakeRecorder*(logPath: string): string =
  ## Shell body that appends the invocation's arguments, one call per line,
  ## to logPath. Pair with writeFakeExe.
  "printf '%s\\n' \"$*\" >> " & logPath.quoteShell

template withPath*(dir: string, body: untyped) =
  ## Replaces $PATH with `dir` for the duration of `body`. findExe reads
  ## $PATH at runtime, so this makes both "command present" and "command
  ## missing" branches constructible in tests.
  let savedPath = getEnv("PATH")
  putEnv("PATH", dir)
  try:
    body
  finally:
    putEnv("PATH", savedPath)

type
  CallRecord* = object
    ## One recorded invocation of a RecordingRunner.
    kind*: string        ## "inherited" or "capture"
    cmd*: string
    args*: seq[string]
    input*: string       ## stdin payload; always "" for "inherited"
    env*: StringTableRef ## snapshot of the effective child environment

  RecordingRunner* = ref object
    ## Holds the recorded calls and the canned answers. `runner` is the
    ## value to pass as a function's `runner` argument.
    calls*: seq[CallRecord]
    exitCode*: int
    output*: string
    error*: string
    replies*: seq[CommandResult] ## FIFO; exhausted queues use the canned defaults
    runner*: Runner

proc newRecordingRunner*(exitCode = 0, output = "",
               error = "",
               replies: seq[CommandResult] = @[]): RecordingRunner =
  ## A Runner that spawns nothing, records every invocation, and answers
  ## with canned values. Pass `rec.runner` as a function's `runner`
  ## argument, then assert on `rec.calls`.
  ##
  ## RecordingRunner is a ref, so the closures below capture the one
  ## object the caller holds: calls made through `rec.runner` accumulate
  ## in `rec.calls` rather than in a copy the caller cannot see.
  let rec = RecordingRunner(calls: @[], exitCode: exitCode,
                            output: output, error: error, replies: replies)

  proc nextReply(): CommandResult =
    if rec.replies.len > 0:
      result = rec.replies[0]
      rec.replies.delete(0)
    else:
      result = CommandResult(exitCode: rec.exitCode, output: rec.output,
                             error: rec.error)

  proc snapshotEnv(env: StringTableRef = nil): StringTableRef =
    result = newStringTable(modeCaseSensitive)
    if env.isNil:
      for key, value in envPairs():
        result[key] = value
    else:
      for key, value in env:
        result[key] = value

  rec.runner = Runner(
    runInheritedImpl: proc (cmd: string, args: seq[string],
                            env: StringTableRef): int =
      rec.calls.add(CallRecord(kind: "inherited", cmd: cmd,
                               args: args, input: "", env: snapshotEnv(env)))
      nextReply().exitCode,
    captureImpl: proc (cmd: string, args: seq[string],
                       input: string): CommandResult =
      rec.calls.add(CallRecord(kind: "capture", cmd: cmd,
                               args: args, input: input, env: snapshotEnv()))
      nextReply()
  )
  rec
