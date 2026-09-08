## Shared vault-name/path resolver for the Vault family. Mount-Vault,
## Remove-Vault, and Resize-Vault all accept either a bare vault name or a
## full path to a vault file and resolve both to the same triple; this
## module gives that resolution one implementation instead of three
## copies. New-Vault takes a bare name only (no path form) and
## Dismount-Vault resolves from the live `mount` table instead -- neither
## needs resolveVault, though Dismount-Vault does reuse mapperPresent.
import std/[os, strutils, posix]
import ./process
import ./output

type
  MapperProbe* = proc (mapperName: string): bool

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
    result.vaultFile = absolutePath(expandTilde(input))
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
  except OSError as e:
    if e.errorCode == ENOENT: return false
    raise

proc closeVault*(runner: Runner, mapperName: string, errp: File): bool =
  ## Cleanup must not mask a pending exception or permit backing-file deletion
  ## when closing failed. The caller retains the file and reports failure.
  try:
    if runner.runInherited("sudo", @["cryptsetup", "close", mapperName]) == 0:
      return true
    error("Could not close vault mapping: " & mapperName &
          "; backing file retained", errp)
  except CatchableError as e:
    error("Could not close vault mapping: " & mapperName & ": " & e.msg &
          "; backing file retained", errp)
  false

proc backingFileIdle*(runner: Runner, vaultFile: string, errp: File): bool =
  ## Inspect the backing file, not only its conventional mapper name: a loop
  ## device can be held by another mapping/name or by a non-crypt consumer.
  ## This is a point-in-time check, not a lock against concurrent opens.
  try:
    let probe = runner.capture("sudo", @["-n", "losetup", "--associated",
        vaultFile, "--noheadings", "--output", "NAME"])
    if probe.exitCode != 0:
      error("Cannot inspect vault loop devices; refusing to modify backing file", errp)
      return false
    if probe.output.strip().len > 0:
      error("Vault backing file is in use by a loop device; dismount it first", errp)
      return false
    true
  except CatchableError as e:
    error("Cannot inspect vault loop devices: " & e.msg, errp)
    false
