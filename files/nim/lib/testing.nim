## Test-only helpers. Never imported by a function, so this module never
## links into a shipped binary. Lives outside lib/tests/ so the flake's
## test globs do not compile it as a test suite of its own.
import std/os

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
  "echo \"$@\" >> " & logPath.quoteShell

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
