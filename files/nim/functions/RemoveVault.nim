import std/os
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"
import "../lib/vault"

type ParsedArgs* = object
  vaultInput*: string
  force*: bool

proc parseArgs*(args: seq[string]): ParsedArgs =
  for a in args:
    if a == "--force":
      result.force = true
    else:
      result.vaultInput = a

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner,
  inp: File = stdin
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Remove-Vault <vault-name> [--force]

Description:
    Delete a LUKS encrypted vault file. Ensures the vault is not mounted before deletion.
    Specify a vault name (e.g., 'mydata') to remove ~/Vaults/.<name>.vault
    Prompts for confirmation unless --force is specified.

Options:
    --force    Skip confirmation prompt

Arguments:
    vault-name    Vault name (e.g., mydata) or full path to vault file

Examples:
    Remove-Vault mydata
    Remove-Vault secrets --force
    Remove-Vault ~/Vaults/.mydata.vault      # Explicit path"""
    return 0

  let parsed = parseArgs(args)
  if not requireArg(parsed.vaultInput, "vault name", errp): return 1
  if not checkDeps(["rm"], errp): return 2

  let v = resolveVault(parsed.vaultInput)
  if not fileExists(v.vaultFile):
    error("Vault file not found: " & v.vaultFile, errp)
    return 1

  if mapperPresent(v.mapperName):
    error("Vault is currently mounted. Dismount first with:", errp)
    outp.writeLine("  dismount-vault " & v.vaultName)
    return 1

  if not parsed.force:
    warn("This will permanently delete the vault file: " & v.vaultFile, errp)
    if not confirm("Are you sure?", inp, outp):
      outp.writeLine("Aborted")
      return 0

  outp.writeLine("Removing vault file: " & v.vaultFile)
  if runner.runInherited("rm", @["--force", v.vaultFile]) != 0:
    return 1

  outp.writeLine("Vault removed successfully")
  0

when isMainModule:
  cliMain(run(commandLineParams()))
