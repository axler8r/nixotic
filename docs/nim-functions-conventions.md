# Nim Command Conventions

Implementation patterns for the compiled toolbelt under `files/nim/`. The CLI's
design — grammar, verb lexicon, cross-cutting flags, exit codes, registry
mechanics, and how to add a command — lives in `docs/ax-cli-design.md`; this doc
covers how a command's Nim is written and tested. The surviving zsh functions
are governed by `docs/zsh-functions-conventions.md`.

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
  if not validateArgs(cmdSpec, args, errp): return 64
  ... # parse validated options; check their domain-specific values

  if not requireArg(name, "name", errp): return 64
  if not checkDeps(cmdSpec.deps, errp): return 2
  ...
  result = runner.runInherited("cryptsetup", @[...])

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
```

- Help-before-parsing is unchanged from the zsh era: the `-h`/`--help` check is
  the first thing in `run()`.
- Call `validateArgs(cmdSpec, args, errp)` immediately after help. The driver
  and executable preamble also validate, but direct `run()` callers must be safe
  too. Unknown flags, missing values, and excess positionals exit 64 before
  dependency checks or effects. Never preserve “last positional wins” or
  ignored-option behaviour from the old shell implementation.
- Parsers must handle the forms validation accepts: `--long=value`, short
  attached values (`-fVALUE`, `-f=VALUE`, `-f:VALUE`), and the `--` terminator.
  Domain checks (positive counts, supported formats, package names) remain the
  command's responsibility. Global flags must not appear in `cmdSpec`.
- Logic lives in `run()`, separate from the entry point, so `std/unittest` calls
  `run()` directly with fake argv — no subprocess spawning for most cases.
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

`axMain` (`lib/spec.nim`) supersedes the old `cliMain` for commands: it answers
`--ax-spec` with the spec as JSON, refuses `AX_DRY_RUN=1` when the spec does not
declare dry-run support (help is exempt), validates arguments, and keeps the
CatchableError-to-exit-1 boundary that preserves stdout=data/stderr=status
instead of printing a traceback. Treat that boundary as a backstop: a local
check with a specific message ("Not a git repository") still beats the generic
exception text.

Specification decoding checks JSON field kinds explicitly: `getStr`, `getInt`,
and `getBool` are not validators and silently return defaults on wrong kinds.
Both registry loading and generation check schema versions, canonical command
paths, kind/lexicon agreement, and reserved flag names.

## Safety and error handling

- Check every captured process's exit code **before** interpreting stdout.
  Failed discovery is not an empty collection, a clean worktree, or a successful
  inspection. Propagate renderer failures too.
- Use `defer`/`finally` immediately after resource acquisition. Cleanup must be
  attempted on exceptions, and a cleanup failure must not become success or mask
  the primary error. Do not delete a vault backing file when closing its mapping
  failed.
- Preflight the complete operation before mutation. Inspect symlinks without
  following them before recursive deletion: Nim's `removeDir` follows a
  top-level directory symlink. Use `walkDir(checkDir = true)` when failed
  discovery would otherwise cause reconciliation against an empty set.
- Replace existing data via an adjacent temporary file and rename after a
  complete write; preserve permissions and clean up temporary files. This
  provides atomic replacement, not a guarantee of power-loss durability.
- File discovery uses NUL-delimited paths. Display cells escape delimiters and
  control characters; JSON retains original cell data.
- These local preflight checks are not concurrency locks. Do not concurrently
  mutate a project tree or open a vault while removal/resizing is running.

Vault removal/resizing additionally inspect loop associations by backing-file
identity, using non-interactive `sudo -n losetup`. Inspection failure refuses
the operation; cached or non-interactive sudo authorisation is required.
Resizing accepts an equal target to resume filesystem growth after partial
success. Creation sets only the new ext4 root's owner; mounting never changes
existing ownership.

## Shared libraries

`lib/output.nim` and `lib/validation.nim` hold the generic helper surface
(`error`, `warn`, `info`, `success`, `confirm`, `render`, `requireArg`,
`checkDeps`, `requireFile`, ...). Grow them **only with procs an actual command
needs.** A plain `import "../../lib/output"` brings exported procs into scope
unqualified — call sites write `error(...)`, not `output.error(...)`.

Colour is suppressed when the stream isn't a TTY or `NO_COLOR` is set to **any**
value including empty (`existsEnv`, matching zsh's `${NO_COLOR+x}` set-ness
test); `AX_COLOR=always|never` (from `--color`) overrides that detection.
`info`/`success` are suppressed under `AX_QUIET`; `error`/`warn` never are.

Prefer `func` for genuinely side-effect-free transformations and `openArray` for
borrowed read-only collections. Use these selectively, not as a mechanical
rewrite of existing command signatures. Prefer iteration over whole-file
tokenisation when inputs can be large.

When several commands in the same family reimplement identical logic, that logic
gets its own small `lib/<family>.nim` rather than being force-fit into the
generic surface: `lib/vault.nim`, `lib/devenv.nim` (which also carries the
`ax dev create`/`ax dev templates` template roster — separate binaries with
disjoint filesets can only share code through `lib/`), `lib/git.nim`, and
`lib/fdscan.nim`. Each gets its own `lib/tests/test_<family>.nim`.

`lib/git.nim` breaks one convention deliberately: its `require*` procs return
`int`, not `bool`, because `requireGitRepo` wraps a `checkDeps` call and its
callers must distinguish "git is missing" (2) from "not a repository" (1). Reach
for the `int` shape only when a helper genuinely conveys more than pass/fail.
Its zsh source (`files/zsh/lib/git.zsh`) stays in the repo:
`Update-GitWIPBranchHistory` still sources it.

## Regex avoidance

No command has needed `std/re`, and none should reach for it casually: it wraps
a runtime `libpcre` this project's derivations don't carry. Simple format checks
(`ax dev create`'s `3.12`/`8`/`1.17` targets, `ax git tag create`'s tag parsing)
are all `strutils.split` plus `allCharsInSet`, the approach `validation.nim`'s
`xattrChars` already uses.

## Process execution

Every subprocess goes through `lib/process.nim`. Never call `std/osproc`
directly from a command. Three primitives, one per shape of use:

- `runner.runInherited(cmd, args)` — child gets the parent's real
  stdin/stdout/stderr. For output that streams live (`zfs list`, `docker pull`).
  Returns the exit code. A privileged command is just
  `runner.runInherited("sudo", @[realCmd, ...])`; `checkDeps` lists the real
  command, never `sudo`.
- `runner.capture(cmd, args, input = "")` — both streams captured and drained
  concurrently, optional stdin payload. For output the command parses before it
  reaches the user. Returns `CommandResult`.
- `runner.runQuiet(cmd, args)` — discards both streams, returns the exit code.

Draining is not optional: `osproc` gives each stream a small fixed pipe, and a
child that fills an undrained pipe blocks forever — `capture` drains both
concurrently on separate threads, and `runQuiet` is built on `capture` for the
same reason.

`capture`'s early-exit contract: a child that exits, or closes stdin, before
consuming all of `input` is not an error — the write stops, the child is reaped,
and the call returns its real exit code with whatever it emitted. A pager or
`head`-shaped filter exiting early is the normal case. Also: `capture`'s output
is the child's bytes verbatim (no trailing-newline normalisation) — consumers
drop empty lines or `strip()` accordingly.

Process handles are owned entirely inside `process.nim`; a command's `run()`
only ever sees the `Runner` it was given and the values a call through it
returns.

## Test doubles

Two mechanisms; which applies depends on what's under test.

**`newRecordingRunner`** (`lib/testing.nim`) is the default for a command's own
tests. It spawns nothing: pass `rec.runner` as `run()`'s `runner` argument, then
assert on `rec.calls` — each entry records the kind (`"inherited"`/`"capture"`),
`cmd`, `args`, and `input`. Its canned `exitCode`/`output`/`error` are what
every call through it sees, so a test drives post-processing of subprocess
output without a real process. This is what argv-pinning "contract" tests use.

The recorder also snapshots inherited-call environments and supports queued
responses for multi-step failure paths. Use custom `Runner` callbacks to inject
exceptions or command-dependent responses. Safety tests must assert that
rejected requests make **no mutating calls**. Characterization tests must not
make incorrect legacy success/cleanup behaviour a permanent contract.

**`withPath` + `writeFakeExe`** cover what the recorder can't:
`lib/process.nim`'s own fork/exec round-trip tests, and the dependency-missing
branch, which needs `findExe` to genuinely fail. `withPath(dir): body` swaps
`$PATH` for the block; `writeFakeExe` writes a `/bin/sh` stand-in (with the
pristine `$PATH` baked in so the fake's own body can still call real utilities).

The common wrinkle: a recorder-based contract test often still needs a
`writeFakeExe` stub purely so `checkDeps` passes — the sandbox has no
`docker`/`zfs`; the stub is found on `$PATH` but never executed because
`rec.runner` intercepts the spawn its presence unlocks.

`lib/testing.nim` sits directly under `lib/`, not `lib/tests/`, deliberately: it
is a helper module imported by test files, and the flake's test glob would
otherwise compile it as a suite of its own.

## Testing

`std/unittest` (stdlib, no nimble dependency). One test file per command at
`commands/<group>/[<subgroup>/]tests/test_<leaf>.nim`; shared-module suites in
`lib/tests/`. `nix/nim.nix` and `nix/ax.nix` turn every test file into its own
check derivation, discovered from the tree at eval time once the file belongs to
the Git flake source. Untracked files are not included until staged by the user.
All run under `nix flake check`, and a failure names the suite.

The vault `tests/test_safety.nim` matrix deliberately imports all five vault
commands; its explicit family fileset is the exception to the one-subject rule.
`tests/integration.sh` exercises real executable dispatch, context, exit codes,
exception handling, and builtin help/dry-run non-mutation through the
`ax-integration` check. Local invocation runs from `files/nim` with Bash.

Each check is fileset-scoped: a command test sees `nim.cfg` + `lib/` +
`lexicon.json` + the one command module it exercises, derived from the test's
own path — so editing a command preserves unrelated command compilations. Its
tests, relevant family checks, final assembly, and smoke checks also invalidate.
Nix runs suites in parallel; Nim receives `NIX_BUILD_CORES` rather than
independently claiming every CPU. Test executables have a 120-second timeout.
Test-only `lib/testing.nim` is excluded from production sources.

Dependency checks are testable in both directions: `findExe` reads `$PATH` at
runtime, so pointing `withPath` at an empty directory constructs the "command
missing" branch for real (exit 2, `Missing commands:` on stderr). A test needing
a genuinely-present tool past the `checkDeps` gate (the attr suite uses real
`getfattr`) gets it from `nimToolchain` in `nix/nim.nix`, which feeds both the
check derivations' `nativeBuildInputs` and the devShell — one list, cannot
drift.

## Compile flags

`files/nim/nim.cfg` sets `--styleCheck:error`; every derivation roots its source
at `files/nim` so it always applies. The package build passes `-d:release`, the
test build deliberately does not, to retain stack and line traces. In Nim 2.2,
release mode retains ordinary assertions; `doAssert` remains enabled even under
`--assertions:off`. `-d:danger`, not release, disables runtime checks. Resist
blanket `--warningAsError`: compiling a command module as a test's import
dependency triggers benign `UnusedImport` warnings for entry-point-only imports.

## Local development

`devShells.${system}.default` provides `nim` plus the runtime deps for
editor/`nim-lsp` support; `.envrc` (`use flake`) activates it via direnv.
Neither is required for the build — `nix build .#ax` and `nix flake check`
provide their own build/test environments. Run them only with user approval.

The resulting `ax` package is a **host-integrated toolbelt**, not a standalone
runtime closure: external programs resolve through the host's `PATH`.
`cmdSpec.deps` and matching checks describe command requirements; plain table
rendering additionally needs `column` (util-linux), with `gum` optional.
Privilege infrastructure (`sudo`), services, devices, and authorisation remain
host-managed. Optional-operation dependencies must be checked before mutation.
