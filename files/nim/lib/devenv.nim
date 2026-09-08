## Shared flake.nix content builder and file-writing sequence for the
## dev-environment scaffolder (ax dev create). The command builds a
## package list and optional env-attrs block per template, then hands
## both to flakeNixContent and the resulting text to
## scaffoldDevEnvironment. The template roster lives here so
## ax dev create and ax dev templates (separate binaries with disjoint
## filesets) share one definition.
import std/[os, strutils, posix, tempfiles]
import output
import process

type DevTemplate* = object
  name*: string
  description*: string

const devTemplates* = [
  DevTemplate(name: "tool",
              description: "ad-hoc tool shell; packages required"),
  DevTemplate(name: "python",
              description: "Python + uv; --target 3.12 selects a version"),
  DevTemplate(name: "dotnet",
              description: ".NET SDK; --target 8|9|10, default all three"),
  DevTemplate(name: "elixir",
              description: "Elixir; --target 1.17 selects a version")
]

proc isDevTemplate*(name: string): bool =
  for t in devTemplates:
    if t.name == name:
      return true
  false

proc formatPackageLines*(prefix: string, names: openArray[string]): seq[string] =
  ## One "            <prefix><name>" line per name (12-space indent),
  ## matching the zsh originals' `printf '            pkgs.%s\n'`.
  result = @[]
  for n in names:
    result.add("            " & prefix & n)

proc flakeNixContent*(name: string, packageLines: seq[string], envAttrs = ""): string =
  ## Builds the flake.nix content shared verbatim (aside from the package
  ## list and envAttrs) across the dev-environment scaffolder family.
  ## `envAttrs`, when non-empty, is a block of already-newline-prefixed,
  ## 10-space-indented lines inserted right after the packages list's
  ## closing "];" -- only New-DotNetDevEnvironment uses this
  ## (DOTNET_CLI_TELEMETRY_OPTOUT/DOTNET_NOLOGO).
  # Escape backslashes first so the escapes introduced below stay literal.
  let escapedName = name.replace("\\", "\\\\").replace("\"", "\\\"")
    .replace("${", "\\${").replace("\n", "\\n").replace("\r", "\\r")
    .replace("\t", "\\t")
  var lines: seq[string] = @[]
  lines.add("{")
  lines.add("  description = \"" & escapedName & " development environment\";")
  lines.add("")
  lines.add("  inputs = {")
  lines.add("    nixpkgs.url = \"github:NixOS/nixpkgs/nixos-unstable\";")
  lines.add("    flake-parts.url = \"github:hercules-ci/flake-parts\";")
  lines.add("  };")
  lines.add("")
  lines.add("  outputs = inputs@{ flake-parts, ... }:")
  lines.add("    flake-parts.lib.mkFlake { inherit inputs; } {")
  lines.add("      systems = [ \"x86_64-linux\" \"aarch64-linux\" \"x86_64-darwin\" \"aarch64-darwin\" ];")
  lines.add("")
  lines.add("      perSystem = { pkgs, ... }: {")
  lines.add("        devShells.default = pkgs.mkShell {")
  lines.add("          name = \"" & escapedName & "\";")
  lines.add("          packages = [")
  for l in packageLines:
    lines.add(l)
  lines.add("          ];" & envAttrs)
  lines.add("        };")
  lines.add("      };")
  lines.add("    };")
  lines.add("}")
  lines.join("\n") & "\n"

type DevFileWriter* = proc (file: File, content: string) {.closure.}
  ## Injectable file write for deterministic short-write/disk-full tests.

proc writeDevFile(file: File, content: string) =
  file.write(content)
  file.flushFile()

proc scaffoldDevEnvironment*(
  flakeContent: string,
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner,
  writer: DevFileWriter = writeDevFile
): int =
  ## Preflight every destination, create new files exclusively, and stage
  ## the optional ignore update for atomic replacement. On write failure
  ## remove only the new files; never overwrite an existing scaffold.
  var ignoreContent = ""
  var updateIgnore = false
  var ignorePermissions: set[FilePermission]
  try:
    for path in ["flake.nix", ".envrc", ".gitignore"]:
      var st: Stat
      if lstat(path.cstring, st) != 0:
        if errno == ENOENT: continue
        raiseOSError(osLastError(), path)
      if path != ".gitignore":
        error(path & " already exists", errp)
        return 1
      if not S_ISREG(st.st_mode):
        error(".gitignore must be a regular file, not a symlink or directory", errp)
        return 1
      ignoreContent = readFile(path)
      ignorePermissions = getFilePermissions(path)
      updateIgnore = ".direnv" notin ignoreContent.splitLines()
    if updateIgnore:
      if ignoreContent.len > 0 and not ignoreContent.endsWith("\n"):
        ignoreContent.add('\n')
      ignoreContent.add(".direnv\n")
  except IOError, OSError:
    error("Cannot preflight development environment: " & getCurrentExceptionMsg(), errp)
    return 1

  var created: seq[string] = @[]
  var ignoreTemp = ""
  proc createFile(path, content: string) =
    # O_EXCL also refuses dangling symlinks introduced after preflight.
    let fd = posix.open(path.cstring, O_WRONLY or O_CREAT or O_EXCL, Mode(0o666))
    if fd < 0: raiseOSError(osLastError(), path)
    created.add(path)
    var file: File
    if not open(file, FileHandle(fd), fmWrite):
      discard posix.close(fd)
      raise newException(IOError, "Cannot open created file: " & path)
    try:
      writer(file, content)
    finally:
      file.close()

  try:
    createFile("flake.nix", flakeContent)
    createFile(".envrc", "use flake\n")
    if updateIgnore:
      let (file, path) = createTempFile(".ax-gitignore-", ".tmp", ".")
      ignoreTemp = path
      try:
        writer(file, ignoreContent)
      finally:
        file.close()
      setFilePermissions(ignoreTemp, ignorePermissions)
      moveFile(ignoreTemp, ".gitignore")
  except IOError, OSError:
    error("Cannot write development environment: " & getCurrentExceptionMsg(), errp)
    for i in countdown(created.high, 0):
      try:
        removeFile(created[i])
      except OSError:
        warn("Cannot roll back created file: " & created[i], errp)
    return 1
  finally:
    if ignoreTemp.len > 0 and fileExists(ignoreTemp):
      try:
        removeFile(ignoreTemp)
      except OSError:
        warn("Cannot remove temporary ignore file: " & ignoreTemp, errp)

  outp.writeLine("Created flake.nix")
  outp.writeLine("Created .envrc")
  if updateIgnore:
    outp.writeLine("Added .direnv to .gitignore")
  let allowCode = runner.runInherited("direnv", @["allow"])
  if allowCode != 0:
    error("direnv allow failed; environment files were created but not authorised", errp)
    return allowCode
  outp.writeLine("Environment authorised; direnv will load it on the next shell hook")
  0
