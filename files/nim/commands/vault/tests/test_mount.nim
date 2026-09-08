import std/[unittest, os, strutils]
import "../mount"
import "../../../lib/testing"

suite "ax vault mount parseArgs":
  test "no args: both fields empty":
    let p = parseArgs(@[])
    check p.vaultInput == ""
    check p.mountPoint == ""

  test "first positional is the vault input":
    let p = parseArgs(@["mydata"])
    check p.vaultInput == "mydata"
    check p.mountPoint == ""

  test "second positional is the mount point":
    let p = parseArgs(@["mydata", "/mnt/x"])
    check p.vaultInput == "mydata"
    check p.mountPoint == "/mnt/x"

  test "a third positional overwrites the mount point (last wins)":
    let p = parseArgs(@["mydata", "/mnt/x", "/mnt/y"])
    check p.vaultInput == "mydata"
    check p.mountPoint == "/mnt/y"

suite "ax vault mount run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_mount_vault_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax vault mount")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_mount_vault_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax vault mount")

  test "missing vault input is a requireArg error (no dead _synopsis call)":
    let tmp = getTempDir() / "test_mount_vault_no_input.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Missing required argument: vault file")

  test "missing deps is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_mount_vault"
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
    check content.contains("cryptsetup")

  test "a nonexistent vault file is an error":
    let dir = getTempDir() / "stub_mount_vault_missing_file"
    removeDir(dir)
    createDir(dir)
    for exe in ["cryptsetup", "mount", "umount", "chown", "mkdir"]:
      writeFakeExe(dir, exe, "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["/nonexistent/.mydata.vault"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Vault file not found")

  test "contract: already-mounted is detected from mount's own output and reported":
    let dir = getTempDir() / "contract_mount_vault_already_mounted"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    for exe in ["cryptsetup", "mount", "umount", "chown", "mkdir"]:
      writeFakeExe(dir, exe, "")
    let rec = newRecordingRunner(
      output = "/dev/mapper/mydata on " & (dir / "Vaults" / "mydata") &
               " type ext4 (rw,relatime)\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[vaultFile], f, f, rec.runner)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Vault already mounted")
    check rec.calls.len == 1
    check rec.calls[0].cmd == "mount"

  test "contract: full success path opens, creates the mount point, mounts, and chowns":
    let dir = getTempDir() / "contract_mount_vault_success"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    for exe in ["cryptsetup", "mount", "umount", "chown", "mkdir", "sudo", "id"]:
      writeFakeExe(dir, exe, "")
    let rec = newRecordingRunner(exitCode = 0, output = "1000\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    let mountPoint = dir / "mnt"
    withPath(dir):
      code = run(@[vaultFile, mountPoint], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 7
    check rec.calls[0].cmd == "mount" # already-mounted probe, empty output
    check rec.calls[1].cmd == "sudo"
    check rec.calls[1].args == @["cryptsetup", "open", "--type", "luks",
                                  vaultFile, "mydata"]
    check rec.calls[2].cmd == "mkdir"
    check rec.calls[2].args == @["--parents", mountPoint]
    check rec.calls[3].cmd == "sudo"
    check rec.calls[3].args == @["mount", "/dev/mapper/mydata", mountPoint]
    check rec.calls[4].cmd == "id"
    check rec.calls[4].args == @["-u"]
    check rec.calls[5].cmd == "id"
    check rec.calls[5].args == @["-g"]
    check rec.calls[6].cmd == "sudo"
    check rec.calls[6].args == @["chown", "-R", "1000:1000", mountPoint]

  test "characterization: a failing sudo mount rolls back with cryptsetup close":
    let dir = getTempDir() / "char_mount_vault_mount_fails"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    let log = dir / "calls.log"
    writeFakeExe(dir, "mount", "exit 0") # already-mounted probe: no output
    writeFakeExe(dir, "cryptsetup", "exit 0")
    writeFakeExe(dir, "mkdir", "exit 0")
    writeFakeExe(dir, "umount", "exit 0")
    writeFakeExe(dir, "chown", "exit 0")
    writeFakeExe(dir, "sudo", """
""" & fakeRecorder(log) & """

case "$1" in
  mount) exit 1 ;;
  *) exit 0 ;;
esac
""")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[vaultFile, dir / "mnt"], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 1
    check calls[0].startsWith("cryptsetup open")
    check calls[1].startsWith("mount")
    check calls[2] == "cryptsetup close mydata"
