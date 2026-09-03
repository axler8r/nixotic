## Shared vault-name/path resolver for the Vault family. Mount-Vault,
## Remove-Vault, and Resize-Vault all accept either a bare vault name or a
## full path to a vault file and resolve both to the same triple; this
## module gives that resolution one implementation instead of three
## copies. New-Vault takes a bare name only (no path form) and
## Dismount-Vault resolves from the live `mount` table instead -- neither
## needs resolveVault, though Dismount-Vault does reuse mapperPresent.
import std/os

type
  VaultRef* = object
    vaultFile*: string   ## absolute path to the vault's backing file
    vaultName*: string   ## bare name, e.g. "mydata"
    mapperName*: string  ## dm-crypt mapper name; always equals vaultName

proc resolveVault*(input: string): VaultRef =
  ## A `/`-containing input is treated as a path (`~` expanded); its vault
  ## name is the basename with the extension removed and one leading dot
  ## stripped, mirroring the zsh original's `${vault_file:t:r:s/^\.//}`
  ## (tail, remove extension, strip one leading dot). Anything else is a
  ## bare vault name resolved under `$HOME/Vaults/.<name>.vault`.
  if '/' in input:
    result.vaultFile = expandTilde(input)
    let (_, name, _) = splitFile(result.vaultFile)
    result.vaultName =
      if name.len > 0 and name[0] == '.': name[1 .. ^1]
      else: name
  else:
    result.vaultName = input
    result.vaultFile = getHomeDir() / "Vaults" / ("." & input & ".vault")
  result.mapperName = result.vaultName

proc mapperPresent*(mapperName: string): bool =
  ## True if /dev/mapper/<mapperName> exists, mirroring the zsh original's
  ## `[[ -e "/dev/mapper/${mapper_name}" ]]` check that Remove-Vault and
  ## Resize-Vault use to detect a currently-open (mounted) vault.
  try:
    discard getFileInfo("/dev/mapper" / mapperName)
    true
  except OSError:
    false
