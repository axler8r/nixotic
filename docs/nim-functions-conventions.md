# Nim Command Conventions

Implementation patterns for the compiled toolbelt under `files/nim/`. The
CLI's design — grammar, verb lexicon, cross-cutting flags, exit codes,
registry mechanics, and how to add a command — lives in
`docs/ax-cli-design.md`; this doc covers how a command's Nim is written and
tested. The surviving zsh functions are governed by
`docs/zsh-functions-conventions.md`.

## Command structure

```nim
import std/os
import "../../lib/output"      # ../../../lib from a depth-3 command
import "../../lib/process"
import "../../lib/spec"
import "../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["vault", "mount"],
  kind: ckVerb,
  summary: "mount a LUKS vault",
  usage: "ax vault mount <name> [mountpoint]",
  args: @[...], flags: @[...],
  deps: @["cryptsetup", "mount"],   # what checkDeps guards
  dryRun: false
)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax vault mount ..."""
    return 0

  # manual option parsing over `args`, same shape as the zsh while/case loop
  ...

  if not requireArg(name, "name", errp): return 64
  if not checkDeps(["cryptsetup"], errp): return 2
  ...
  result = runner.runInherited("cryptsetup", @[...])

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
```

- Help-before-parsing is unchanged from the zsh era: the `-h`/`--help` check
  is the first thing in `run()`.
- Logic lives in `run()`, separate from the entry point, so `std/unittest`
  calls `run()` directly with fake argv — no subprocess spawning for most
  cases.
- `run()` takes optional `outp`/`errp` `File` params so tests can redirect
  output to a temp file and assert on it.
- A command that spawns any subprocess also takes
  `runner: Runner = defaultRunner`, the seam tests intercept.
- A command that prompts (`confirm`) also takes `inp: File = stdin`
  (`ax vault remove`); `ax script create` reads its payload the same way.
- A list/report command reads its output mode with `ctxFromEnv()`
  (`lib/context.nim`) and renders through `output.render()` — never by
  formatting JSON or tables by hand.
- `proc run*` and any helper a test needs are exported (`*`); the test file
  imports the module by relative path (`import "../mount"`).

`axMain` (`lib/spec.nim`) supersedes the old `cliMain` for commands: it
answers `--ax-spec` with the spec as JSON, refuses `AX_DRY_RUN=1` when the
spec does not declare dry-run support, and keeps the CatchableError-to-exit-1
boundary that preserves stdout=data/stderr=status instead of printing a
traceback. Treat that boundary as a backstop: a local check with a specific
message ("Not a git repository") still beats the generic exception text.

## Shared libraries

`lib/output.nim` and `lib/validation.nim` hold the generic helper surface
(`error`, `warn`, `info`, `success`, `confirm`, `render`, `requireArg`,
`checkDeps`, `requireFile`, ...). Grow them **only with procs an actual
command needs.** A plain `import "../../lib/output"` brings exported procs
into scope unqualified — call sites write `error(...)`, not
`output.error(...)`.

Colour is suppressed when the stream isn't a TTY or `NO_COLOR` is set to
**any** value including empty (`existsEnv`, matching zsh's `${NO_COLOR+x}`
set-ness test); `AX_COLOR=always|never` (from `--color`) overrides that
detection. `info`/`success` are suppressed under `AX_QUIET`; `error`/`warn`
never are.

When several commands in the same family reimplement identical logic, that
logic gets its own small `lib/<family>.nim` rather than being force-fit into
the generic surface: `lib/vault.nim`, `lib/devenv.nim` (which also carries
the `ax dev create`/`ax dev templates` template roster — separate binaries
with disjoint filesets can only share code through `lib/`), `lib/git.nim`,
and `lib/fdscan.nim`. Each gets its own `lib/tests/test_<family>.nim`.

`lib/git.nim` breaks one convention deliberately: its `require*` procs return
`int`, not `bool`, because `requireGitRepo` wraps a `checkDeps` call and its
callers must distinguish "git is missing" (2) from "not a repository" (1).
Reach for the `int` shape only when a helper genuinely conveys more than
pass/fail. Its zsh source (`files/zsh/lib/git.zsh`) stays in the repo:
`Update-GitWIPBranchHistory` still sources it.

## Regex avoidance

No command has needed `std/re`, and none should reach for it casually: it
wraps a runtime `libpcre` this project's derivations don't carry. Simple
format checks (`ax dev create`'s `3.12`/`8`/`1.17` targets,
`ax git tag create`'s tag parsing) are all `strutils.split` plus
`allCharsInSet`, the approach `validation.nim`'s `xattrChars` already uses.

## Process execution

Every subprocess goes through `lib/process.nim`. Never call `std/osproc`
directly from a command. Three primitives, one per shape of use:

- `runner.runInherited(cmd, args)` — child gets the parent's real
  stdin/stdout/stderr. For output that streams live (`zfs list`,
  `docker pull`). Returns the exit code. A privileged command is just
  `runner.runInherited("sudo", @[realCmd, ...])`; `checkDeps` lists the real
  command, never `sudo`.
- `runner.capture(cmd, args, input = "")` — both streams captured and
  drained concurrently, optional stdin payload. For output the command
  parses before it reaches the user. Returns `CommandResult`.
- `runner.runQuiet(cmd, args)` — discards both streams, returns the exit
  code.

Draining is not optional: `osproc` gives each stream a small fixed pipe, and
a child that fills an undrained pipe blocks forever — `capture` drains both
concurrently on separate threads, and `runQuiet` is built on `capture` for
the same reason.

`capture`'s early-exit contract: a child that exits, or closes stdin, before
consuming all of `input` is not an error — the write stops, the child is
reaped, and the call returns its real exit code with whatever it emitted. A
pager or `head`-shaped filter exiting early is the normal case. Also:
`capture`'s output is the child's bytes verbatim (no trailing-newline
normalisation) — consumers drop empty lines or `strip()` accordingly.

Process handles are owned entirely inside `process.nim`; a command's `run()`
only ever sees the `Runner` it was given and the values a call through it
returns.

## Test doubles

Two mechanisms; which applies depends on what's under test.

**`newRecordingRunner`** (`lib/testing.nim`) is the default for a command's
own tests. It spawns nothing: pass `rec.runner` as `run()`'s `runner`
argument, then assert on `rec.calls` — each entry records the kind
(`"inherited"`/`"capture"`), `cmd`, `args`, and `input`. Its canned
`exitCode`/`output`/`error` are what every call through it sees, so a test
drives post-processing of subprocess output without a real process. This is
what argv-pinning "contract" tests use.

**`withPath` + `writeFakeExe`** cover what the recorder can't:
`lib/process.nim`'s own fork/exec round-trip tests, and the
dependency-missing branch, which needs `findExe` to genuinely fail.
`withPath(dir): body` swaps `$PATH` for the block; `writeFakeExe` writes a
`/bin/sh` stand-in (with the pristine `$PATH` baked in so the fake's own body
can still call real utilities).

The common wrinkle: a recorder-based contract test often still needs a
`writeFakeExe` stub purely so `checkDeps` passes — the sandbox has no
`docker`/`zfs`; the stub is found on `$PATH` but never executed because
`rec.runner` intercepts the spawn its presence unlocks.

`lib/testing.nim` sits directly under `lib/`, not `lib/tests/`, deliberately:
it is a helper module imported by test files, and the flake's test glob would
otherwise compile it as a suite of its own.

## Testing

`std/unittest` (stdlib, no nimble dependency). One test file per command at
`commands/<group>/[<subgroup>/]tests/test_<leaf>.nim`; shared-module suites
in `lib/tests/`. `flake.nix` turns every test file into its own check
derivation, discovered from the tree at eval time — adding a file is enough.
All run under `nix flake check`, and a failure names the suite.

Each check is fileset-scoped: a command test sees `nim.cfg` + `lib/` +
`lexicon.json` + the one command module it exercises, derived from the test's
own path — so editing one command invalidates only its own build and test,
and Nix runs suites in parallel.

Dependency checks are testable in both directions: `findExe` reads `$PATH` at
runtime, so pointing `withPath` at an empty directory constructs the
"command missing" branch for real (exit 2, `Missing commands:` on stderr). A
test needing a genuinely-present tool past the `checkDeps` gate (the attr
suite uses real `getfattr`) gets it from `nimToolchain` in `flake.nix`, which
feeds both the check derivations' `nativeBuildInputs` and the devShell — one
list, cannot drift.

## Compile flags

`files/nim/nim.cfg` sets `--styleCheck:error`; every derivation roots its
source at `files/nim` so it always applies. The package build passes
`-d:release`, the test build deliberately does not — live
`assert`/`doAssert` and readable stack traces are worth more in a test binary
than speed. Don't "fix" this to match; see the comment beside `mkNimTest` in
`flake.nix`. Resist `--warningAsError`: compiling a command module as a
test's import dependency triggers benign `UnusedImport` warnings for
entry-point-only imports.

## Local development

`devShells.${system}.default` provides `nim` plus the runtime deps for
editor/`nim-lsp` support; `.envrc` (`use flake`) activates it via direnv.
Neither is required for the build — `nix build`/`nix flake check` are
self-contained.
