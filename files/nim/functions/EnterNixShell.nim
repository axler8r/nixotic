import std/[os, osproc, strtabs, strutils]
import "../lib/cli"
import "../lib/output"
import "../lib/validation"

proc buildInstallables*(packages: seq[string]): seq[string] =
  ## For each package: if it already contains '#' it's a full flake ref,
  ## passed through unchanged; otherwise it's a bare package name, prefixed
  ## with `nixpkgs#`.
  result = @[]
  for pkg in packages:
    if pkg.contains('#'):
      result.add(pkg)
    else:
      result.add("nixpkgs#" & pkg)

proc buildShellName*(packages: seq[string]): string =
  ## The `name` env var shown in the nested shell's prompt: the ORIGINAL
  ## package args, space-joined -- not the `nixpkgs#`-prefixed installables.
  packages.join(" ")

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: Enter-NixShell packages...

Description:
    Enter an ephemeral Nix shell with an ad-hoc set of packages. Nothing is
    written to disk (no flake.nix, no .envrc) -- the shell exists only for
    the current terminal session. The prompt shows the active package set
    for the duration of the shell.

Arguments:
    packages                Nix packages (bare names, e.g. jq ripgrep)
                             An argument containing '#' is treated as a full
                             flake ref and passed through unchanged.

Examples:
    Enter-NixShell jq ripgrep                  # nix shell nixpkgs#jq nixpkgs#ripgrep
    Enter-NixShell github:foo/bar#baz          # Ad-hoc shell from another flake"""
    return 0

  var packages: seq[string] = @[]
  for a in args:
    if a.startsWith("-"):
      error("Unknown option: " & a, errp)
      return 1
    packages.add(a)

  if not checkDeps(["nix"], errp): return 2

  if packages.len == 0:
    error("Usage: Enter-NixShell packages...", errp)
    info("Use --help for more information", errp)
    return 1

  let installables = buildInstallables(packages)

  var env = newStringTable(modeCaseSensitive)
  for k, v in envPairs():
    env[k] = v
  env["IN_NIX_SHELL"] = "impure"
  env["name"] = buildShellName(packages)

  var p = startProcess(
    "nix",
    args = @["shell"] & installables,
    env = env,
    options = {poUsePath, poParentStreams}
  )
  result = p.waitForExit()
  p.close()

when isMainModule:
  cliMain(run(commandLineParams()))
