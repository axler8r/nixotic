import std/os
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"
import "../../lib/vault"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["vault", "remove"],
  kind: ckVerb,
  summary: "delete a LUKS vault file",
  usage: "ax vault remove <name> [--force]",
  args: @[
    ArgSpec(name: "name", required: true,
            description: "vault name (e.g. mydata) or full path to the vault file")
  ],
  flags: @[
    FlagSpec(long: "force", takesValue: false,
             description: "skip the confirmation prompt")
  ],
  deps: @["rm"],
  dryRun: false
)

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
    outp.writeLine """Usage: ax vault remove <name> [--force]

Description:
    Delete a LUKS encrypted vault file. Ensures the vault is not mounted before deletion.
    Specify a vault name (e.g., 'mydata') to remove ~/Vaults/.<name>.vault
    Prompts for confirmation unless --force is specified.

Options:
    --force    Skip confirmation prompt

Arguments:
    name    Vault name (e.g., mydata) or full path to vault file

Examples:
    ax vault remove mydata
    ax vault remove secrets --force
    ax vault remove ~/Vaults/.mydata.vault      # Explicit path"""
    return 0

  let parsed = parseArgs(args)
  if not requireArg(parsed.vaultInput, "vault name", errp): return 64
  if not checkDeps(["rm"], errp): return 2

  let v = resolveVault(parsed.vaultInput)
  if not fileExists(v.vaultFile):
    error("Vault file not found: " & v.vaultFile, errp)
    return 1

  if mapperPresent(v.mapperName):
    error("Vault is currently mounted. Dismount first with:", errp)
    outp.writeLine("  ax vault unmount " & v.vaultName)
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
  axMain(cmdSpec):
    run(commandLineParams())
