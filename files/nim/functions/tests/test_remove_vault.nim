import std/[unittest, os, strutils]
import "../RemoveVault"
import "../../lib/testing"

suite "Remove-Vault parseArgs":
  test "no args: empty input, force false":
    let p = parseArgs(@[])
    check p.vaultInput == ""
    check p.force == false

  test "--force sets the flag regardless of position":
    let p1 = parseArgs(@["--force", "mydata"])
    check p1.force == true
    check p1.vaultInput == "mydata"
    let p2 = parseArgs(@["mydata", "--force"])
    check p2.force == true
    check p2.vaultInput == "mydata"

  test "last non-flag positional wins":
    let p = parseArgs(@["first", "second"])
    check p.vaultInput == "second"

suite "Remove-Vault run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_remove_vault_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Remove-Vault")

  test "prints usage and returns 0 for -h (fixed: zsh original only checked --help)":
    let tmp = getTempDir() / "test_remove_vault_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Remove-Vault")

  test "missing vault name is a requireArg error":
    let tmp = getTempDir() / "test_remove_vault_no_name.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Missing required argument: vault name")

  test "missing deps is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_remove_vault"
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
    check content.contains("Missing commands: rm")

  test "a nonexistent vault file is an error":
    let dir = getTempDir() / "stub_remove_vault_missing"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "rm", "exit 0")
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

  # No test exercises the "vault is currently mounted" guard here: it
  # requires mapperPresent to answer true, which needs a real /dev/mapper
  # node -- the same hard, unfakeable constraint documented for
  # lib/vault's own mapperPresent tests and for Dismount-Vault.

  test "contract: --force skips the confirmation prompt entirely and removes the file":
    let dir = getTempDir() / "contract_remove_vault_force"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    writeFakeExe(dir, "rm", "")
    let rec = newRecordingRunner(exitCode = 0)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    # inp is left at its default (stdin) -- if confirm() were reached, this
    # test would hang or fail on a real terminal read, so reaching rm
    # without doing so proves --force truly bypassed the prompt.
    var code: int
    withPath(dir):
      code = run(@[vaultFile, "--force"], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "rm"
    check rec.calls[0].args == @["--force", vaultFile]

  test "contract: declining the confirmation prompt aborts without calling rm":
    let dir = getTempDir() / "contract_remove_vault_decline"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    writeFakeExe(dir, "rm", "")
    let rec = newRecordingRunner(exitCode = 0)
    let inTmp = dir / "in.txt"
    writeFile(inTmp, "n\n")
    let inp = open(inTmp, fmRead)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[vaultFile], f, f, rec.runner, inp)
    inp.close()
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 0
    check content.contains("Aborted")
    check rec.calls.len == 0

  test "contract: accepting the confirmation prompt removes the file":
    let dir = getTempDir() / "contract_remove_vault_accept"
    removeDir(dir)
    createDir(dir)
    let vaultFile = dir / ".mydata.vault"
    writeFile(vaultFile, "x")
    writeFakeExe(dir, "rm", "")
    let rec = newRecordingRunner(exitCode = 0)
    let inTmp = dir / "in.txt"
    writeFile(inTmp, "y\n")
    let inp = open(inTmp, fmRead)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[vaultFile], f, f, rec.runner, inp)
    inp.close()
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 0
    check content.contains("Vault removed successfully")
    check rec.calls.len == 1
    check rec.calls[0].cmd == "rm"
    check rec.calls[0].args == @["--force", vaultFile]
