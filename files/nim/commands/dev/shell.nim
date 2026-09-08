import std/[os, strtabs, strutils]
import "../../lib/output"
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["dev", "shell"],
  kind: ckVerb,
  summary: "enter an ephemeral Nix shell with ad-hoc packages",
  usage: "ax dev shell <packages...>",
  args: @[
    ArgSpec(name: "packages", required: true, variadic: true,
            description: "Nix packages (bare names, or full flake refs containing '#')")
  ],
  deps: @["nix"],
  dryRun: false
)

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
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax dev shell <packages...>

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
    ax dev shell jq ripgrep                  # nix shell nixpkgs#jq nixpkgs#ripgrep
    ax dev shell github:foo/bar#baz          # Ad-hoc shell from another flake"""
    return 0

  var packages: seq[string] = @[]
  for a in args:
    if a.startsWith("-"):
      error("Unknown option: " & a, errp)
      return 64
    packages.add(a)

  if not checkDeps(["nix"], errp): return 2

  if packages.len == 0:
    error("Usage: ax dev shell <packages...>", errp)
    info("Use --help for more information", errp)
    return 64

  let installables = buildInstallables(packages)

  var env = newStringTable(modeCaseSensitive)
  for k, v in envPairs():
    env[k] = v
  env["IN_NIX_SHELL"] = "impure"
  env["name"] = buildShellName(packages)

  result = runner.runInherited(
    "nix", @["shell"] & installables, env)

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
