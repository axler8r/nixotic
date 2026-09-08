## Shared flake.nix content builder and file-writing sequence for the
## dev-environment scaffolder (ax dev create). The command builds a
## package list and optional env-attrs block per template, then hands
## both to flakeNixContent and the resulting text to
## scaffoldDevEnvironment. The template roster lives here so
## ax dev create and ax dev templates (separate binaries with disjoint
## filesets) share one definition.
import std/[os, strutils]
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
  var lines: seq[string] = @[]
  lines.add("{")
  lines.add("  description = \"" & name & " development environment\";")
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
  lines.add("          name = \"" & name & "\";")
  lines.add("          packages = [")
  for l in packageLines:
    lines.add(l)
  lines.add("          ];" & envAttrs)
  lines.add("        };")
  lines.add("      };")
  lines.add("    };")
  lines.add("}")
  lines.join("\n") & "\n"

proc scaffoldDevEnvironment*(
  flakeContent: string,
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  ## The file-writing sequence shared verbatim across the dev-environment
  ## scaffolder family, once each caller has built its own flake.nix
  ## content via flakeNixContent. Mirrors the zsh originals exactly,
  ## including never checking `direnv allow`'s exit code -- the last
  ## thing each zsh function does is an unconditional `echo`, so it
  ## always reports success regardless of whether direnv actually
  ## activated the environment.
  if fileExists("flake.nix"):
    error("flake.nix already exists", errp)
    return 1
  writeFile("flake.nix", flakeContent)
  outp.writeLine("Created flake.nix")

  if fileExists(".envrc"):
    error(".envrc already exists", errp)
    return 1
  writeFile(".envrc", "use flake\n")
  outp.writeLine("Created .envrc")

  if fileExists(".gitignore"):
    var hasDirenv = false
    for line in readFile(".gitignore").splitLines():
      if line == ".direnv":
        hasDirenv = true
        break
    if not hasDirenv:
      let f = open(".gitignore", fmAppend)
      f.writeLine(".direnv")
      f.close()
      outp.writeLine("Added .direnv to .gitignore")

  discard runner.runInherited("direnv", @["allow"])
  outp.writeLine("Environment activated")
  0
