import std/[unittest, os]
import "../vault"

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
