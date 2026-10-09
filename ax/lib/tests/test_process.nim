import std/[unittest, os, strutils, strtabs]
import "../process"
import "../testing"

proc zombieChildren(): seq[string] =
  ## Names of this process's own un-reaped children, read straight from
  ## /proc so the test needs no external tool on $PATH (withPath has
  ## replaced $PATH with a fixture dir anyway). A capture that abandons a
  ## child leaves an entry here; a capture that reaps it leaves none.
  let me = $getCurrentProcessId()
  for kind, path in walkDir("/proc"):
    if kind != pcDir: continue
    let pid = path.extractFilename
    if pid.len == 0 or not pid.allCharsInSet({'0' .. '9'}): continue
    var status: string
    try:
      status = readFile(path / "status")
    except CatchableError:
      continue  # exited between the walk and the read
    var name, state, parent = ""
    for line in status.splitLines():
      let f = line.splitWhitespace()
      if f.len < 2: continue
      case f[0]
      of "Name:": name = f[1]
      of "State:": state = f[1]
      of "PPid:": parent = f[1]
      else: discard
    if state == "Z" and parent == me:
      result.add(name)

suite "process runner":
  test "capture returns stdout, stderr and exit code separately":
    let dir = getTempDir() / "test_process_capture"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "noisy", "echo to-stdout\necho to-stderr >&2\nexit 7")
    var r: CommandResult
    withPath(dir):
      r = defaultRunner.capture("noisy", @[])
    removeDir(dir)
    check r.exitCode == 7
    check r.output.strip() == "to-stdout"
    check r.error.strip() == "to-stderr"

  test "capture does not deadlock on output larger than the pipe buffer":
    # 512KB on each stream, well past the ~64KB pipe buffer. A sequential
    # read of stdout-then-stderr hangs here; a concurrent drain does not.
    let dir = getTempDir() / "test_process_bigoutput"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "flood", """
i=0
while [ $i -lt 8192 ]; do
  echo "0123456789012345678901234567890123456789012345678901234567890123"
  echo "0123456789012345678901234567890123456789012345678901234567890123" >&2
  i=$((i + 1))
done
exit 0
""")
    var r: CommandResult
    withPath(dir):
      r = defaultRunner.capture("flood", @[])
    removeDir(dir)
    check r.exitCode == 0
    check r.output.len >= 500_000
    check r.error.len >= 500_000

  test "capture writes input to the child's stdin":
    let dir = getTempDir() / "test_process_stdin"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "upper", "cat")
    var r: CommandResult
    withPath(dir):
      r = defaultRunner.capture("upper", @[], "hello stdin")
    removeDir(dir)
    check r.exitCode == 0
    check r.output.strip() == "hello stdin"

  test "capture does not deadlock writing large input to a chatty child":
    # The GetHelp shape: write a large payload to stdin while the child
    # writes a large payload back. Write-then-read deadlocks; drain-first
    # does not. 4MB, not 400KB: stdin pipe, child read buffer and stdout
    # pipe together absorb ~700KB on Linux before a write-first
    # implementation blocks, so a smaller payload passes either way and
    # proves nothing.
    let dir = getTempDir() / "test_process_stdin_big"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "echoback", "cat")
    let payload = repeat("x", 4_000_000)
    var r: CommandResult
    withPath(dir):
      r = defaultRunner.capture("echoback", @[], payload)
    removeDir(dir)
    check r.exitCode == 0
    check r.output.len == payload.len

  test "capture passes arguments through unmodified":
    let dir = getTempDir() / "test_process_args"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "argecho", "for a in \"$@\"; do echo \"[$a]\"; done")
    var r: CommandResult
    withPath(dir):
      r = defaultRunner.capture("argecho", @["one two", "--flag=x y"])
    removeDir(dir)
    check r.output.strip().splitLines() == @["[one two]", "[--flag=x y]"]

  test "runQuiet returns the exit code and discards output":
    let dir = getTempDir() / "test_process_quiet"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "chatty", "echo noise\necho more >&2\nexit 3")
    var code: int
    withPath(dir):
      code = defaultRunner.runQuiet("chatty", @[])
    removeDir(dir)
    check code == 3

  test "runInherited returns the child's exit code":
    let dir = getTempDir() / "test_process_inherited"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "failer", "exit 42")
    var code: int
    withPath(dir):
      code = defaultRunner.runInherited("failer", @[])
    removeDir(dir)
    check code == 42

  test "runInherited passes a custom environment to the child":
    let dir = getTempDir() / "test_process_env"
    removeDir(dir)
    createDir(dir)
    let log = dir / "env.log"
    writeFakeExe(dir, "envdump", "echo \"MARKER=$MARKER\" > " & log.quoteShell)
    var env = newStringTable(modeCaseSensitive)
    env["PATH"] = dir
    env["MARKER"] = "present"
    var code: int
    withPath(dir):
      code = defaultRunner.runInherited("envdump", @[], env)
    let recorded = readFile(log).strip()
    removeDir(dir)
    check code == 0
    check recorded == "MARKER=present"

  test "capture survives a child that exits without reading its stdin":
    # Nim ignores SIGPIPE process-wide, so a dead reader surfaces as an
    # EPIPE IOError out of the stdin write. Left unhandled that unwinds
    # past both joins into p.close(), closing the streams under two live
    # drain threads and skipping waitForExit. Contract: not an error --
    # the child's real exit code comes back and the child is reaped.
    let dir = getTempDir() / "test_process_deaf"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "deaf", "exit 9")
    let payload = repeat("x", 4_000_000)
    var r: CommandResult
    withPath(dir):
      r = defaultRunner.capture("deaf", @[], payload)
    removeDir(dir)
    check r.exitCode == 9
    check zombieChildren() == newSeq[string]()

  test "runInherited with a nil environment gives the child this process's own":
    # This is what every other runInherited call site relies on: all of
    # them pass no `env` argument (Enter-NixShell is the one exception --
    # EnterNixShell.nim:70 builds and passes an explicit table), so each
    # expects its child to see the parent's real environment via this nil
    # default. Distinct from the custom-env test above, which only proves a
    # nil-env child can execute at all.
    let dir = getTempDir() / "test_process_inheritenv"
    removeDir(dir)
    createDir(dir)
    let log = dir / "env.log"
    writeFakeExe(dir, "envdump", "echo \"INHERITED=$INHERITED\" > " & log.quoteShell)
    putEnv("INHERITED", "from-parent")
    var code: int
    withPath(dir):
      code = defaultRunner.runInherited("envdump", @[])
    let recorded = readFile(log).strip()
    removeDir(dir)
    delEnv("INHERITED")
    check code == 0
    check recorded == "INHERITED=from-parent"
