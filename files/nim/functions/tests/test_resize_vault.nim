import std/[unittest, os, strutils]
import "../ResizeVault"
import "../../lib/testing"

suite "Resize-Vault parseArgs":
  test "no args: everything empty":
    let p = parseArgs(@[])
    check p.vaultInput == ""
    check p.size == ""
    check p.missingFlagValue == ""

  test "--size sets size, positional sets vaultInput":
    let p = parseArgs(@["mydata", "--size", "5G"])
    check p.vaultInput == "mydata"
    check p.size == "5G"

  test "last positional wins":
    let p = parseArgs(@["first", "--size", "5G", "second"])
    check p.vaultInput == "second"

  test "--size with no following value sets missingFlagValue":
    let p = parseArgs(@["mydata", "--size"])
    check p.missingFlagValue == "--size"

suite "Resize-Vault run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_resize_vault_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Resize-Vault")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_resize_vault_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Resize-Vault")

  test "missing --size value is an error before requireArg checks":
    let tmp = getTempDir() / "test_resize_vault_missing_size_value.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["mydata", "--size"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Missing value for --size")

  test "missing vault name is a requireArg error":
    let tmp = getTempDir() / "test_resize_vault_no_name.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--size", "5G"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Missing required argument: vault name")

  test "missing --size is a requireArg error":
    let tmp = getTempDir() / "test_resize_vault_no_size.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["mydata"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Missing required argument: --size")

  test "missing deps is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_resize_vault"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["mydata", "--size", "5G"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands:")
    check content.contains("fallocate")

  test "a nonexistent vault file is an error":
    let dir = getTempDir() / "stub_resize_vault_missing_file"
    removeDir(dir)
    createDir(dir)
    for exe in ["fallocate", "cryptsetup", "resize2fs", "e2fsck", "blkid", "stat", "numfmt"]:
      writeFakeExe(dir, exe, "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["/nonexistent/.mydata.vault", "--size", "5G"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Vault file not found")

  # No test exercises the "vault is currently mounted" guard here: it
  # requires mapperPresent to answer true, which needs a real /dev/mapper
  # node -- the same hard, unfakeable constraint documented for
  # lib/vault's own mapperPresent tests, Dismount-Vault, and Remove-Vault.

  test "characterization: shrinking is rejected using stat/numfmt-derived byte counts":
    let dir = getTempDir() / "char_resize_vault_shrink"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    writeFakeExe(dir, "stat", "echo 5000000000")
    writeFakeExe(dir, "numfmt", """
case "$1" in
  --from=iec) echo 1000000000 ;;
  --to=iec) echo 5G ;;
esac
""")
    for exe in ["fallocate", "cryptsetup", "resize2fs", "e2fsck", "blkid", "sudo"]:
      writeFakeExe(dir, exe, "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[vaultFile, "--size", "1G"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("does not support shrinking (current: 5G, requested: 1G)")

  test "characterization: an invalid --size value is reported once numfmt --from=iec fails":
    let dir = getTempDir() / "char_resize_vault_invalid_size"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    writeFakeExe(dir, "stat", "echo 100000000")
    writeFakeExe(dir, "numfmt", "exit 1")
    for exe in ["fallocate", "cryptsetup", "resize2fs", "e2fsck", "blkid", "sudo"]:
      writeFakeExe(dir, exe, "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[vaultFile, "--size", "notasize"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Invalid size: notasize")

  test "characterization: a non-ext4 filesystem is rejected and the vault is re-closed":
    let dir = getTempDir() / "char_resize_vault_wrong_fs"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    let log = dir / "calls.log"
    writeFakeExe(dir, "stat", "echo 100000000")
    writeFakeExe(dir, "numfmt", "echo 5000000000")
    writeFakeExe(dir, "fallocate", fakeRecorder(log) & "\nexit 0")
    writeFakeExe(dir, "cryptsetup", "exit 0")
    writeFakeExe(dir, "resize2fs", "exit 0")
    writeFakeExe(dir, "e2fsck", "exit 0")
    writeFakeExe(dir, "blkid", "exit 0")
    writeFakeExe(dir, "sudo", """
""" & fakeRecorder(log) & """

case "$1" in
  blkid) echo btrfs ;;
  *) exit 0 ;;
esac
""")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[vaultFile, "--size", "5G"], f, f)
    f.close()
    let content = readFile(outPath)
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 1
    check content.contains("only supports ext4 filesystems (found: btrfs)")
    check calls[0].startsWith("--length")
    check calls[1].startsWith("cryptsetup open")
    check calls[2].startsWith("blkid")
    check calls[3] == "cryptsetup close mydata"

  test "characterization: e2fsck exit code 1 (fixed, not clean) still continues to resize2fs":
    let dir = getTempDir() / "char_resize_vault_fsck_fixed"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    let log = dir / "calls.log"
    writeFakeExe(dir, "stat", "echo 100000000")
    writeFakeExe(dir, "numfmt", "echo 5000000000")
    writeFakeExe(dir, "fallocate", "exit 0")
    writeFakeExe(dir, "cryptsetup", "exit 0")
    writeFakeExe(dir, "resize2fs", "exit 0")
    writeFakeExe(dir, "e2fsck", "exit 0")
    writeFakeExe(dir, "blkid", "exit 0")
    writeFakeExe(dir, "sudo", """
""" & fakeRecorder(log) & """

case "$1" in
  blkid) echo ext4 ;;
  e2fsck) exit 1 ;;
  *) exit 0 ;;
esac
""")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[vaultFile, "--size", "5G"], f, f)
    f.close()
    let content = readFile(outPath)
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check content.contains("Vault resized successfully")
    check calls.len == 6 # open, blkid, resize, e2fsck, resize2fs, close

  test "characterization: e2fsck exit code 2 (real error) aborts and re-closes the vault":
    let dir = getTempDir() / "char_resize_vault_fsck_error"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    let log = dir / "calls.log"
    writeFakeExe(dir, "stat", "echo 100000000")
    writeFakeExe(dir, "numfmt", "echo 5000000000")
    writeFakeExe(dir, "fallocate", "exit 0")
    writeFakeExe(dir, "cryptsetup", "exit 0")
    writeFakeExe(dir, "resize2fs", "exit 0")
    writeFakeExe(dir, "e2fsck", "exit 0")
    writeFakeExe(dir, "blkid", "exit 0")
    writeFakeExe(dir, "sudo", """
""" & fakeRecorder(log) & """

case "$1" in
  blkid) echo ext4 ;;
  e2fsck) exit 2 ;;
  *) exit 0 ;;
esac
""")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[vaultFile, "--size", "5G"], f, f)
    f.close()
    let content = readFile(outPath)
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 1
    check content.contains("Filesystem check failed")
    check calls[^1] == "cryptsetup close mydata"

  test "contract: full success path runs fallocate then the sudo open/blkid/resize/e2fsck/resize2fs/close sequence in order":
    let dir = getTempDir() / "char_resize_vault_success"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    let log = dir / "calls.log"
    writeFakeExe(dir, "stat", "echo 100000000")
    writeFakeExe(dir, "numfmt", "echo 5000000000")
    writeFakeExe(dir, "fallocate", fakeRecorder(log) & "\nexit 0")
    writeFakeExe(dir, "cryptsetup", "exit 0")
    writeFakeExe(dir, "resize2fs", "exit 0")
    writeFakeExe(dir, "e2fsck", "exit 0")
    writeFakeExe(dir, "blkid", "exit 0")
    writeFakeExe(dir, "sudo", """
""" & fakeRecorder(log) & """

case "$1" in
  blkid) echo ext4 ;;
  *) exit 0 ;;
esac
""")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[vaultFile, "--size", "5G"], f, f)
    f.close()
    let content = readFile(outPath)
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check content.contains("Vault resized successfully: " & vaultFile & " is now 5G")
    check calls.len == 7
    check calls[0].startsWith("--length 5G")
    check calls[1] == "cryptsetup open --type luks " & vaultFile & " mydata"
    check calls[2].startsWith("blkid")
    check calls[3] == "cryptsetup resize mydata"
    check calls[4] == "e2fsck -f /dev/mapper/mydata"
    check calls[5] == "resize2fs /dev/mapper/mydata"
    check calls[6] == "cryptsetup close mydata"
