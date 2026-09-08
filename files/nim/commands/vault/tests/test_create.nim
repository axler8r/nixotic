import std/[unittest, os, strutils]
import "../create"
import "../../../lib/testing"

suite "ax vault create parseArgs":
  test "defaults: 1G size, $HOME/Vaults location, empty name":
    let home = getTempDir() / "test_new_vault_parseargs_home"
    createDir(home)
    let saved = getEnv("HOME")
    putEnv("HOME", home)
    let p = parseArgs(@[])
    putEnv("HOME", saved)
    removeDir(home)
    check p.vaultName == ""
    check p.size == "1G"
    check p.location == home / "Vaults"
    check p.missingFlagValue == ""

  test "a bare positional becomes the vault name":
    let p = parseArgs(@["mydata"])
    check p.vaultName == "mydata"

  test "--size and --location override their defaults":
    let p = parseArgs(@["mydata", "--size", "5G", "--location", "/mnt/storage"])
    check p.vaultName == "mydata"
    check p.size == "5G"
    check p.location == "/mnt/storage"

  test "last positional wins when multiple stray args are given":
    let p = parseArgs(@["first", "--size", "5G", "second"])
    check p.vaultName == "second"
    check p.size == "5G"

  test "--size with no following value sets missingFlagValue":
    let p = parseArgs(@["mydata", "--size"])
    check p.missingFlagValue == "--size"

  test "--location with no following value sets missingFlagValue":
    let p = parseArgs(@["mydata", "--location"])
    check p.missingFlagValue == "--location"

suite "ax vault create run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_new_vault_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax vault create")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_new_vault_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax vault create")

  test "missing --size value is an error before requireArg":
    let tmp = getTempDir() / "test_new_vault_missing_size.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["mydata", "--size"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Missing value for --size")

  test "missing vault name is a requireArg error":
    let tmp = getTempDir() / "test_new_vault_no_name.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Missing required argument: vault name")

  test "missing deps is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_new_vault"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["mydata"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands:")
    check content.contains("fallocate")

  test "an already-existing vault file is an error":
    let home = getTempDir() / "test_new_vault_exists_home"
    let vaultsDir = home / "Vaults"
    createDir(vaultsDir)
    writeFile(vaultsDir / ".mydata.vault", "x")
    let dir = getTempDir() / "stub_new_vault_exists"
    removeDir(dir)
    createDir(dir)
    for exe in ["fallocate", "cryptsetup", "mkdir", "rm"]:
      writeFakeExe(dir, exe, "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["mydata", "--location", vaultsDir], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(home)
    removeDir(dir)
    check code == 1
    check content.contains("Vault already exists")

  test "contract: full success path calls fallocate, luksFormat, open, mkfs, close in order":
    let dir = getTempDir() / "contract_new_vault_success"
    removeDir(dir)
    createDir(dir)
    for exe in ["fallocate", "cryptsetup", "sudo", "mkdir", "rm"]:
      writeFakeExe(dir, exe, "")
    let rec = newRecordingRunner(exitCode = 0)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["mydata", "--location", dir / "Vaults", "--size", "2G"],
                 f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 6
    check rec.calls[0].cmd == "mkdir"
    check rec.calls[0].args == @["--parents", dir / "Vaults"]
    check rec.calls[1].cmd == "fallocate"
    check rec.calls[1].args == @["--length", "2G", dir / "Vaults" / ".mydata.vault"]
    check rec.calls[2].cmd == "cryptsetup"
    check rec.calls[2].args == @["luksFormat", "--verify-passphrase",
                                  dir / "Vaults" / ".mydata.vault"]
    check rec.calls[3].cmd == "sudo"
    check rec.calls[3].args == @["cryptsetup", "open", "--type", "luks",
                                  dir / "Vaults" / ".mydata.vault", "mydata"]
    check rec.calls[4].cmd == "sudo"
    check rec.calls[4].args == @["mkfs.ext4", "-L", "mydata", "/dev/mapper/mydata"]
    check rec.calls[5].cmd == "sudo"
    check rec.calls[5].args == @["cryptsetup", "close", "mydata"]

  test "characterization: a failing luksFormat rolls back with rm --force":
    let dir = getTempDir() / "char_new_vault_luksformat_fails"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "mkdir", "exit 0")
    writeFakeExe(dir, "fallocate", fakeRecorder(log) & "\nexit 0")
    writeFakeExe(dir, "cryptsetup", fakeRecorder(log) & "\nexit 1")
    writeFakeExe(dir, "rm", fakeRecorder(log) & "\nexit 0")
    writeFakeExe(dir, "sudo", fakeRecorder(log) & "\nexit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["mydata", "--location", dir / "Vaults"], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 1
    check calls[0].contains("--length")
    check calls[1] == "luksFormat --verify-passphrase " & (dir / "Vaults" / ".mydata.vault")
    check calls[2] == "--force " & (dir / "Vaults" / ".mydata.vault")

  test "characterization: a failing sudo cryptsetup open rolls back with rm --force":
    let dir = getTempDir() / "char_new_vault_open_fails"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "mkdir", "exit 0")
    writeFakeExe(dir, "fallocate", "exit 0")
    writeFakeExe(dir, "cryptsetup", "exit 0")
    writeFakeExe(dir, "rm", fakeRecorder(log) & "\nexit 0")
    writeFakeExe(dir, "sudo", fakeRecorder(log) & "\nexit 1")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["mydata", "--location", dir / "Vaults"], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 1
    check calls[0].startsWith("cryptsetup open")
    check calls[1] == "--force " & (dir / "Vaults" / ".mydata.vault")

  test "characterization: a failing mkfs.ext4 rolls back with close then rm":
    let dir = getTempDir() / "char_new_vault_mkfs_fails"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "mkdir", "exit 0")
    writeFakeExe(dir, "fallocate", "exit 0")
    writeFakeExe(dir, "cryptsetup", "exit 0")
    writeFakeExe(dir, "rm", fakeRecorder(log) & "\nexit 0")
    writeFakeExe(dir, "sudo", """
""" & fakeRecorder(log) & """

case "$1" in
  mkfs.ext4) exit 1 ;;
  *) exit 0 ;;
esac
""")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["mydata", "--location", dir / "Vaults"], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 1
    check calls[0].startsWith("cryptsetup open")
    check calls[1].startsWith("mkfs.ext4")
    check calls[2] == "cryptsetup close mydata"
    check calls[3] == "--force " & (dir / "Vaults" / ".mydata.vault")
