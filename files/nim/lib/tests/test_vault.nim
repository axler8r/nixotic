import std/[unittest, os]
import "../vault"
import "../process"
import "../testing"

suite "vault.resolveVault":
  test "bare name resolves under $HOME/Vaults with a leading-dot filename":
    let home = getTempDir() / "test_vault_resolve_home"
    createDir(home)
    let savedHome = getEnv("HOME")
    putEnv("HOME", home)
    let v = resolveVault("mydata")
    putEnv("HOME", savedHome)
    removeDir(home)
    check v.vaultFile == home / "Vaults" / ".mydata.vault"
    check v.vaultName == "mydata"
    check v.mapperName == "mydata"

  test "a full path with the standard .<name>.vault shape resolves the name":
    let v = resolveVault("/mnt/storage/.secrets.vault")
    check v.vaultFile == "/mnt/storage/.secrets.vault"
    check v.vaultName == "secrets"
    check v.mapperName == "secrets"

  test "a path without a leading dot still strips only the extension":
    let v = resolveVault("/mnt/storage/data.vault")
    check v.vaultFile == "/mnt/storage/data.vault"
    check v.vaultName == "data"

  test "a path with no extension at all keeps the whole basename":
    let v = resolveVault("/mnt/storage/mydata")
    check v.vaultFile == "/mnt/storage/mydata"
    check v.vaultName == "mydata"

  test "a leading ~ is expanded against $HOME":
    let home = getTempDir() / "test_vault_resolve_tilde_home"
    createDir(home)
    let savedHome = getEnv("HOME")
    putEnv("HOME", home)
    let v = resolveVault("~/Vaults/.mydata.vault")
    putEnv("HOME", savedHome)
    removeDir(home)
    check v.vaultFile == home / "Vaults" / ".mydata.vault"
    check v.vaultName == "mydata"

suite "vault.mapperPresent":
  test "false when /dev/mapper/<name> does not exist":
    # The true branch needs a real dm-crypt mapper node, which requires
    # root and a real block device -- not constructible in this sandbox.
    # See the Global Constraints note on this gap.
    check mapperPresent("definitely-not-a-real-mapper-xyz123") == false

suite "vault.backingFileIdle":
  test "only a successful empty associated-loop query is idle":
    let f = open(getTempDir() / "test_vault_idle.txt", fmWrite)
    defer:
      f.close()
      removeFile(getTempDir() / "test_vault_idle.txt")
    for reply in [CommandResult(), CommandResult(output: "/dev/loop7\n"),
                  CommandResult(exitCode: 1), CommandResult(exitCode: 1, output: "/dev/loop7")]:
      let rec = newRecordingRunner(replies = @[reply])
      check backingFileIdle(rec.runner, "/tmp/vault with spaces", f) ==
          (reply.exitCode == 0 and reply.output.len == 0)
      check rec.calls.len == 1
      check rec.calls[0].kind == "capture"
      check rec.calls[0].cmd == "sudo"
      check rec.calls[0].args == @["-n", "losetup", "--associated",
          "/tmp/vault with spaces", "--noheadings", "--output", "NAME"]

  test "inspection exceptions fail closed":
    let f = open(getTempDir() / "test_vault_idle_exception.txt", fmWrite)
    defer:
      f.close()
      removeFile(getTempDir() / "test_vault_idle_exception.txt")
    let runner = Runner(captureImpl:
      proc(cmd: string, args: seq[string], input: string): CommandResult =
        raise newException(IOError, "injected inspection failure"))
    check not backingFileIdle(runner, "/tmp/test.vault", f)
