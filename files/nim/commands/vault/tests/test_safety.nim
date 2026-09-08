## Callback-only subprocess regressions: no command, sudo or mapper is real.
import std/[unittest, os, strutils, strtabs, sequtils]
import "../create" as createVault
import "../mount" as mountVault
import "../unmount" as unmountVault
import "../remove" as removeVault
import "../resize" as resizeVault
import "../../../lib/process"
import "../../../lib/testing"

type Harness = ref object
  runner: Runner
  calls: seq[CallRecord]
  failAt, throwAt: string
  closeCount, failClose, throwClose: int
  currentSize, targetSize, fsType, mountOutput, loopOutput: string

proc key(cmd: string, args: seq[string]): string =
  if cmd != "sudo": return cmd
  if args[0] == "-n": return args[1]
  if args[0] == "cryptsetup": return "cryptsetup " & args[1]
  args[0]

proc newHarness(): Harness =
  let h = Harness(currentSize: "100000000", targetSize: "5000000000", fsType: "ext4")
  proc reply(kind, cmd: string, args: seq[string]): CommandResult =
    h.calls.add CallRecord(kind: kind, cmd: cmd, args: args)
    let step = key(cmd, args)
    if step == "cryptsetup close":
      inc h.closeCount
      if h.throwClose == h.closeCount:
        raise newException(IOError, "injected close exception")
      if h.failClose == h.closeCount: return CommandResult(exitCode: 1)
    if h.throwAt == step: raise newException(IOError, "injected " & step)
    if h.failAt == step: return CommandResult(exitCode: 1)
    case step
    of "stat": result.output = h.currentSize
    of "numfmt": result.output = h.targetSize
    of "blkid": result.output = h.fsType
    of "mount": result.output = h.mountOutput
    of "losetup": result.output = h.loopOutput
    else: discard
  h.runner = Runner(
    runInheritedImpl: proc(cmd: string, args: seq[string], env: StringTableRef): int =
      reply("inherited", cmd, args).exitCode,
    captureImpl: proc(cmd: string, args: seq[string], input: string): CommandResult =
      reply("capture", cmd, args))
  h

proc steps(h: Harness): seq[string] =
  h.calls.mapIt(key(it.cmd, it.args))

proc absent(name: string): bool = false
proc present(name: string): bool = true

suite "vault cleanup safety with injected runners":
  setup:
    let dir = getTempDir() / "ax_vault_callback_safety"
    removeDir(dir)
    createDir(dir)
    for dep in createVault.cmdSpec.deps & mountVault.cmdSpec.deps &
               unmountVault.cmdSpec.deps & removeVault.cmdSpec.deps & resizeVault.cmdSpec.deps:
      writeFakeExe(dir, dep, "exit 99") # presence only; callbacks execute nothing
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "backing file")
    let f = open(dir / "output.txt", fmWrite)
    let h = newHarness()
  teardown:
    f.close()
    removeDir(dir)

  test "all runs reject unknown options and excess positionals before effects":
    withPath(dir):
      for args in [@["mydata", "--bogus"], @["mydata", "extra"], @["mydata", "--dry-run"]]:
        check createVault.run(args, f, f, h.runner) == 64
        check removeVault.run(args, f, f, h.runner) == 64
        check unmountVault.run(args, f, f, h.runner) == 64
        check resizeVault.run(args, f, f, h.runner) == 64
      check mountVault.run(@[vaultFile, "--bogus"], f, f, h.runner) == 64
      check mountVault.run(@[vaultFile, "a", "b"], f, f, h.runner) == 64
      check mountVault.run(@[vaultFile, "--dry-run"], f, f, h.runner) == 64
    check h.calls.len == 0

  test "help bypasses argument and dependency validation in all runs":
    let emptyPath = dir / "empty"
    createDir(emptyPath)
    withPath(emptyPath):
      check createVault.run(@["--help", "--bogus"], f, f, h.runner) == 0
      check mountVault.run(@["--help", "--bogus"], f, f, h.runner) == 0
      check unmountVault.run(@["--help", "--bogus"], f, f, h.runner) == 0
      check removeVault.run(@["--help", "--bogus"], f, f, h.runner) == 0
      check resizeVault.run(@["--help", "--bogus"], f, f, h.runner) == 0
    check h.calls.len == 0

  test "parsers honor attached values and the option terminator accepted by validation":
    let created = createVault.parseArgs(@["--size=2G", "--location=/tmp/vaults", "--", "--size"])
    check created.size == "2G"
    check created.location == "/tmp/vaults"
    check created.vaultName == "--size"
    let resized = resizeVault.parseArgs(@["--size=5G", "--", "--size"])
    check resized.size == "5G"
    check resized.vaultInput == "--size"
    let removed = removeVault.parseArgs(@["--", "--force"])
    check removed.vaultInput == "--force"
    check not removed.force
    let mounted = mountVault.parseArgs(@["--", "--name", "--mountpoint"])
    check mounted.vaultInput == "--name"
    check mounted.mountPoint == "--mountpoint"
    withPath(dir):
      check unmountVault.run(@["--", "mydata"], f, f, h.runner, present) == 0
    check h.calls[^1].args == @["cryptsetup", "close", "mydata"]

  test "missing mkfs dependency refuses creation before allocation":
    removeFile(dir / "mkfs.ext4")
    withPath(dir):
      check createVault.run(@["newdata", "--location", dir], f, f, h.runner) == 2
    check h.calls.len == 0

  test "create reports final close failure and retains backing file":
    h.failClose = 1
    withPath(dir):
      check createVault.run(@["newdata", "--location", dir], f, f, h.runner) == 1
    check h.closeCount == 1
    check "rm" notin h.steps
    f.flushFile()
    check not readFile(dir / "output.txt").contains("Vault created successfully")

  test "failed mkfs plus failed close must not delete backing file":
    h.failAt = "mkfs.ext4"
    h.failClose = 1
    withPath(dir):
      check createVault.run(@["newdata", "--location", dir], f, f, h.runner) == 1
    check h.closeCount == 1
    check "rm" notin h.steps

  test "mkfs exception closes before removing the failed creation":
    h.throwAt = "mkfs.ext4"
    withPath(dir):
      expect IOError:
        discard createVault.run(@["newdata", "--location", dir], f, f, h.runner)
    check h.steps[^2 .. ^1] == @["cryptsetup close", "rm"]

  test "mkfs and close exceptions retain backing file and preserve original failure":
    h.throwAt = "mkfs.ext4"
    h.throwClose = 1
    withPath(dir):
      try:
        discard createVault.run(@["newdata", "--location", dir], f, f, h.runner)
        check false
      except IOError as e:
        check e.msg == "injected mkfs.ext4"
    check h.closeCount == 1
    check "rm" notin h.steps

  test "mount capture failure cannot open a mapping":
    h.failAt = "mount"
    withPath(dir):
      check mountVault.run(@[vaultFile, dir / "mnt"], f, f, h.runner) == 1
    check h.steps == @["mount"]

  test "mkdir exception after open attempts close":
    h.throwAt = "mkdir"
    withPath(dir):
      expect IOError:
        discard mountVault.run(@[vaultFile, dir / "mnt"], f, f, h.runner)
    check h.steps[^1] == "cryptsetup close"
    check h.closeCount == 1

  test "mount exception after open attempts close":
    # Bypass the capture exception to throw only during the mount action.
    let capture = h.runner.captureImpl
    h.runner.captureImpl = proc(cmd: string, args: seq[string], input: string): CommandResult =
      if cmd == "mount": return CommandResult()
      capture(cmd, args, input)
    h.throwAt = "mount"
    withPath(dir):
      expect IOError:
        discard mountVault.run(@[vaultFile, dir / "mnt"], f, f, h.runner)
    check h.closeCount == 1

  test "mount success keeps mapping and never invokes id or chown":
    withPath(dir):
      check mountVault.run(@[vaultFile, dir / "mnt"], f, f, h.runner) == 0
    check h.steps == @["mount", "cryptsetup open", "mkdir", "mount"]
    check h.closeCount == 0

  test "unmount missing dependencies does not capture":
    removeFile(dir / "cryptsetup")
    withPath(dir):
      check unmountVault.run(@["mydata"], f, f, h.runner, present) == 2
    check h.calls.len == 0

  test "unmount failed mount inspection does not unmount or close":
    h.failAt = "mount"
    withPath(dir):
      check unmountVault.run(@["mydata"], f, f, h.runner, present) == 1
    check h.steps == @["mount"]

  test "unmount recovers open but unmounted mapper without umount empty":
    withPath(dir):
      check unmountVault.run(@["mydata"], f, f, h.runner, present) == 0
    check h.steps == @["mount", "cryptsetup close"]

  test "unmount close exception is a failure, not success":
    h.throwClose = 1
    withPath(dir):
      check unmountVault.run(@["mydata"], f, f, h.runner, present) == 1
    check h.closeCount == 1

  test "mounted vault is unmounted before close":
    h.mountOutput = "/dev/mapper/mydata on /mnt/mydata type ext4 (rw)\n"
    withPath(dir):
      check unmountVault.run(@["mydata"], f, f, h.runner, present) == 0
    check h.steps == @["mount", "umount", "cryptsetup close"]

  test "failed unmount leaves still-mounted mapping open":
    h.mountOutput = "/dev/mapper/mydata on /mnt/mydata type ext4 (rw)\n"
    h.failAt = "umount"
    withPath(dir):
      check unmountVault.run(@["mydata"], f, f, h.runner, present) == 1
    check h.closeCount == 0

  test "unmount exception does not close a possibly mounted filesystem":
    h.mountOutput = "/dev/mapper/mydata on /mnt/mydata type ext4 (rw)\n"
    h.throwAt = "umount"
    withPath(dir):
      expect IOError:
        discard unmountVault.run(@["mydata"], f, f, h.runner, present)
    check h.closeCount == 0

  test "conventional open mapper prevents both removal and resize":
    withPath(dir):
      check removeVault.run(@[vaultFile, "--force"], f, f, h.runner,
                            mapperProbe = present) == 1
      check resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, present) == 1
    check h.calls.len == 0

  test "loop associated under another mapper name prevents removal and growth":
    h.loopOutput = "/dev/loop42\n"
    withPath(dir):
      check removeVault.run(@[vaultFile, "--force"], f, f, h.runner,
                            mapperProbe = absent) == 1
      check resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, absent) == 1
    check "rm" notin h.steps
    check "fallocate" notin h.steps
    check "cryptsetup open" notin h.steps
    check fileExists(vaultFile)

  test "loop inspection failure refuses removal and growth":
    h.failAt = "losetup"
    withPath(dir):
      check removeVault.run(@[vaultFile, "--force"], f, f, h.runner,
                            mapperProbe = absent) == 1
      check resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, absent) == 1
    check "rm" notin h.steps
    check "fallocate" notin h.steps
    check "cryptsetup open" notin h.steps

  test "inspection exceptions refuse removal and growth":
    h.throwAt = "losetup"
    withPath(dir):
      check removeVault.run(@[vaultFile, "--force"], f, f, h.runner,
                            mapperProbe = absent) == 1
      check resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, absent) == 1
    check "rm" notin h.steps
    check "fallocate" notin h.steps

  test "second loop inspection failure prevents allocation after preflight cleanup":
    let capture = h.runner.captureImpl
    var loopProbes = 0
    h.runner.captureImpl = proc(cmd: string, args: seq[string], input: string): CommandResult =
      if key(cmd, args) == "losetup":
        inc loopProbes
        if loopProbes == 2: return CommandResult(exitCode: 1)
      capture(cmd, args, input)
    withPath(dir):
      check resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, absent) == 1
    check h.closeCount == 1
    check "fallocate" notin h.steps

  test "resize unsupported filesystem closes without allocating":
    h.fsType = "btrfs"
    withPath(dir):
      check resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, absent) == 1
    check h.closeCount == 1
    check "fallocate" notin h.steps

  test "failed blkid capture closes without allocating":
    h.failAt = "blkid"
    withPath(dir):
      check resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, absent) == 1
    check h.closeCount == 1
    check "fallocate" notin h.steps

  test "blkid exception closes without allocating":
    h.throwAt = "blkid"
    withPath(dir):
      expect IOError:
        discard resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, absent)
    check h.closeCount == 1
    check "fallocate" notin h.steps

  test "preflight close failure forbids allocation and reopening":
    h.failClose = 1
    withPath(dir):
      check resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, absent) == 1
    check h.closeCount == 1
    check "fallocate" notin h.steps
    check h.steps.count("cryptsetup open") == 1

  test "resize final close failure is propagated":
    h.failClose = 2
    withPath(dir):
      check resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, absent) == 1
    check h.closeCount == 2
    f.flushFile()
    check not readFile(dir / "output.txt").contains("Vault resized successfully")

  test "resize operation exceptions close both acquired mappings":
    for step in ["cryptsetup resize", "e2fsck", "resize2fs"]:
      let failing = newHarness()
      failing.throwAt = step
      withPath(dir):
        expect IOError:
          discard resizeVault.run(@[vaultFile, "--size", "5G"], f, f, failing.runner, absent)
      check failing.closeCount == 2
      check failing.steps[^1] == "cryptsetup close"

  test "equal target resumes filesystem growth without allocating again":
    h.targetSize = h.currentSize
    withPath(dir):
      check resizeVault.run(@[vaultFile, "--size", h.targetSize], f, f, h.runner, absent) == 0
    check "fallocate" notin h.steps
    check "resize2fs" in h.steps
    check h.closeCount == 2

  test "growth validates and closes before allocating, then reopens":
    withPath(dir):
      check resizeVault.run(@[vaultFile, "--size", "5G"], f, f, h.runner, absent) == 0
    check h.steps == @["stat", "numfmt", "losetup", "cryptsetup open", "blkid",
        "cryptsetup close", "losetup", "fallocate", "cryptsetup open",
        "cryptsetup resize", "e2fsck", "resize2fs", "cryptsetup close"]
