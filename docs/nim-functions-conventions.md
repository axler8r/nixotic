# Nim Function Migration Conventions

Companion to `docs/zsh-functions-conventions.md` — the naming table, output
contract (stdout=data/stderr=status), `--raw` convention, and help pattern
described there still apply regardless of implementation language. This doc
covers what's specific to a Nim port, learned while migrating `Get-Attribute` as
the pilot.

## Scope: when to migrate a function

Threshold-based, mapped onto the tier system in
`docs/zsh-functions-conventions.md`:

- `wrapper` tier (1–15 lines, straight command pass-through, no validation
  beyond `-h`) → stays zsh, or becomes a `zshalias` entry if it's pure
  flag-forwarding.
- `function` tier (16–80 lines) and `script` tier (81+) → migration candidates.
  Still a per-function judgment call, not an auto-migrate trigger — a
  `function`-tier script that's just "validate one arg, call one command" can
  reasonably stay zsh.

No backfill deadline. Un-migrated functions keep working exactly as today,
indefinitely, via the existing zsh path.

## Repo layout

Mirrors `files/zsh/`:

```
files/nim/
├── nim.cfg              # --styleCheck:error — see "Compile flags" below
├── lib/
│   ├── output.nim       # replaces lib/output.zsh
│   ├── validation.nim   # replaces lib/validation.zsh
│   ├── process.nim      # subprocess execution — see "Process execution" below
│   ├── cli.nim          # cliMain safety net — see "Error handling" below
│   ├── testing.nim      # test doubles — see "Test doubles" below
│   └── tests/
└── functions/
    ├── GetAttribute.nim
    ├── GetAttributes.nim
    ├── SetAttribute.nim
    ├── RemoveAttribute.nim
    └── tests/
```

`lib/testing.nim` sits directly under `lib/`, not `lib/tests/`, deliberately:
the flake's test globs are `lib/tests/*.nim` and `functions/tests/*.nim`, and
`testing.nim` is a helper module `import`ed by other test files, not a test
suite of its own — placing it under `lib/tests/` would make the check derivation
try to compile and run it as one.

## Naming: source file vs. installed binary

**The costly lesson from the pilot.** Nim's `import` statement requires the
target module's basename to be a valid Nim identifier — hyphens aren't allowed,
even with quoted-path import syntax (`import "../Get-Attribute"` fails to
compile with `invalid module name`). Compiling a hyphenated filename directly as
a program's root file (no `import` involved) works fine — that's how the binary
itself still ends up named correctly — but a _test_ file needs to `import` the
module to call its `run()` proc, and that's where the hyphen breaks.

So: **the Nim source file drops the hyphen** (PascalCase, e.g.
`GetAttribute.nim`), while **the installed binary keeps it** (`Get-Attribute`),
matching the PowerShell Verb-Noun convention that aliases and `$PATH` lookups
expect.

That mapping is spelled out explicitly per function in `flake.nix`'s `let` block
as the `nimFunctionBinaries` attrset, not derived from the source filename:

```nix
nimFunctionBinaries = {
  "Get-Attribute" = "GetAttribute.nim";
  "Get-Attributes" = "GetAttributes.nim";
  "Set-Attribute" = "SetAttribute.nim";
  "Remove-Attribute" = "RemoveAttribute.nim";
};
```

Add one entry like this per migrated function. This is deliberately not
automated: a generic "strip the hyphen" / "re-insert a hyphen before capitals"
transform isn't safe in general — e.g. `ConvertTo-H264Video` has two capitalized
words before the hyphen, so a mechanical reversal would misplace it. One
explicit entry per function is boring and correct.

The `packages.${system}.nim-functions` derivation's build phase uses this
attrset to construct one `nim c` invocation per function, and fails loudly if
any `functions/*.nim` file has no matching entry — no more silently-missing
binaries.

## Function structure

```nim
import std/os
import "../lib/cli"
import "../lib/output"
import "../lib/process"
import "../lib/validation"

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ..."""
    return 0

  # manual option parsing over `args`, same shape as the zsh while/case loop
  ...

  if not requireArg(attribute, "attribute", errp): return 1
  if not checkDeps(["some-tool"], errp): return 2
  ...
  result = runner.runInherited("some-tool", @[...])

when isMainModule:
  cliMain(run(commandLineParams()))
```

- Help-before-parsing (Pattern 1 from the zsh conventions doc) is unchanged.
- Logic lives in `run()`, separate from the `when isMainModule` entry point, so
  `std/unittest` can call `run()` directly with fake argv — no subprocess
  spawning needed for most test cases.
- `run()` takes optional `outp`/`errp` `File` params (default `stdout`/`stderr`)
  so tests can redirect a case to a temp file and assert on captured output
  (used for the `--help` case in `Get-Attribute`'s tests).
- A function that spawns any subprocess also takes an optional
  `runner: Runner = defaultRunner` param, so tests can substitute
  `newRecordingRunner`'s runner instead — see Process execution and Test doubles
  below.
- A function whose zsh original calls `__ax_confirm` also takes an optional
  `inp: File = stdin` param, appended **after** `runner`, so a test can redirect
  what the confirmation prompt reads — mirrors how `outp`/`errp` are already
  redirectable. `Remove-Vault` is the first example.
- `when isMainModule` calls `cliMain(run(commandLineParams()))`, not a bare
  `quit(run(...))` — see Error handling and the exit-code contract below.
- `proc run*` and any helper `proc`s a test needs must be marked `*` (exported)
  — the test file `import`s the function's module directly by relative path
  (e.g. `import "../GetAttribute"`).

## The `ax` module

`files/nim/lib/output.nim` and `validation.nim` replace `lib/output.zsh` and
`lib/validation.zsh`. Grow this module **only with procs an actual function
needs** — don't port the full zsh helper surface speculatively.

Ported so far:

| zsh                                 | Nim                                                                              |
| ----------------------------------- | -------------------------------------------------------------------------------- |
| `__ax_error`                        | `output.error*(msg: string, errp: File = stderr)`                                |
| `__ax_require_arg`                  | `validation.requireArg*(value, name, errp): bool`                                |
| `__ax_check_deps`                   | `validation.checkDeps*(cmds: openArray[string], errp): bool`                     |
| `__ax_require_path_target`          | `validation.requirePathTarget*(path, errp): bool`                                |
| `__ax_require_xattr_name`           | `validation.requireXattrName*(attribute, errp): bool`                            |
| `__ax_require_writable_path_target` | `validation.requireWritablePathTarget*(path, errp): bool`                        |
| `__ax_info`                         | `output.info*(msg: string, errp: File = stderr)`                                 |
| `__ax_success`                      | `output.success*(msg: string, errp: File = stderr)`                              |
| `__ax_require_file`                 | `validation.requireFile*(path, errp): bool`                                      |
| `__ax_warn`                         | `output.warn*(msg: string, errp: File = stderr)`                                 |
| `__ax_confirm`                      | `output.confirm*(message: string, inp: File = stdin, outp: File = stdout): bool` |

**Not yet ported** (add when the first function that needs one migrates):
`__ax_verbose`, `__ax_table`, `__ax_require_dir`, `__ax_require_root`,
`__ax_require_extension`.

Naming convention: procs drop the `__ax_` prefix and use camelCase (Nim style).
Functions import `output` and `validation` as needed with a plain
`import "../lib/output"` / `import "../lib/validation"` (no `as` alias), which
brings their exported procs into scope unqualified — call sites write
`error(...)`, `requireArg(...)`, and `checkDeps(...)`, not `output.error(...)`
or `validation.requireArg(...)`. Reach for a module-qualified call only if two
imported modules ever export a proc with the same name and a collision needs
resolving; that hasn't happened yet.

Output contract carries over exactly: stdout for data, stderr for status; color
suppressed when stderr isn't a TTY, or when `NO_COLOR` is set to **any** value
including empty string (`os.existsEnv("NO_COLOR")`, not a truthiness check on
its value — this matches zsh's `${NO_COLOR+x}` set-ness test, which a naive
`getEnv("NO_COLOR") == ""` check would get wrong).

## Family-specific shared libraries

Not every shared Nim module is a growth of the generic `ax` module
(`output.nim`/`validation.nim`). When several functions in the same _family_
independently reimplement identical logic in zsh, that logic gets its own small
`lib/<family>.nim` instead of being force-fit into `ax` or duplicated per
function — `lib/vault.nim` (`resolveVault`, `mapperPresent`), forced by the
Vault family (`Mount-Vault`, `Remove-Vault`, `Resize-Vault` all resolve a bare
name-or-path input to a vault file + mapper name the same way), is the first
instance of this pattern. `lib/devenv.nim` (`formatPackageLines`,
`flakeNixContent`, `scaffoldDevEnvironment`), forced by the dev-environment
scaffolder family, is the second. `lib/git.nim` (`requireGitRepo`,
`gitCurrentBranch`, `requireCleanGitWorktree`, `requireBranchExists`,
`requireNotBranch`, `requireWipBranch`), a port of the existing
`files/zsh/lib/git.zsh` rather than logic newly extracted from duplicated zsh,
is the third — and the first of these three whose zsh source file is *not*
deleted after the port, since `Update-GitWIPBranchHistory` (excluded from
migration) still sources it.

These modules follow the same import convention as `ax`: a plain
`import "../lib/vault"` brings its exported procs into scope unqualified. They
are not tracked in the "ported so far" / "not yet ported" tables above — those
are specific to the generic `ax` surface — but do get their own
`lib/tests/test_<family>.nim` file, compiled by the same
`checks.${system}.nim-functions-tests` glob as everything else in `lib/tests/`.

`lib/git.nim` breaks one `ax`-established convention deliberately: its
`require*` procs return `int`, not `bool`. The zsh original's
`__ax_require_git_repo` calls `__ax_check_deps git` internally and its callers
propagate `$?` verbatim, so callers need to distinguish "git is missing" (2)
from "not a repository" (1) — a `bool` can't carry that third state. Every
other `require*`-shaped proc in this codebase (`validation.nim`'s,
`lib/vault.nim`'s) returns `bool` because none of them wrap a `checkDeps` call
themselves; reach for the `int` shape only when a helper genuinely needs to
convey more than pass/fail.

## Regex avoidance

No function has needed `std/re` so far, and none should reach for it casually:
it wraps a runtime `libpcre`, a new build dependency this project's Nix
derivations don't currently carry. Simple format checks
(`New-PythonDevEnvironment`'s `3.12`, `New-DotNetDevEnvironment`'s `8`/`9`/`10`,
`New-ElixirDevEnvironment`'s `1.17`) are all doable with `strutils.split` plus a
charset check (`allCharsInSet`), the same approach `validation.nim`'s
`xattrChars` already uses for attribute-name validation. Reach for `std/re` only
if a genuinely regex-shaped requirement shows up that a manual check can't
express reasonably.

## Process execution

Every subprocess a function spawns goes through `files/nim/lib/process.nim`.
Never call `std/osproc`'s `startProcess` or `execProcess` directly from a
`functions/*.nim` file. `run()` takes an optional
`runner: Runner = defaultRunner` parameter and calls through it, which is also
the seam tests use to intercept the spawn (see Test doubles below).

A privileged command needs no special handling: it is just
`runner.runInherited("sudo", @[real_cmd, ...])`. `sudo`'s own
password/passphrase prompt streams live because `runInherited` connects the
child to the parent's real stdin/stdout/stderr, the same as any other
interactive child process. `checkDeps` lists the real command (`cryptsetup`,
`mount`, ...), never `sudo` itself, matching the zsh originals — none of them
check for `sudo`'s presence either.

Three primitives, one per shape of subprocess use:

- `runner.runInherited(cmd, args)` — connects the child directly to the parent's
  real stdin/stdout/stderr. Use when the child's own output should stream to the
  user live (`zfs list`, `nix flake update`, `docker rmi`). Returns the child's
  exit code.
- `runner.capture(cmd, args, input = "")` — runs the child with both output
  streams captured and drained concurrently, optionally writing `input` to its
  stdin. Use when the function parses or transforms the output before it reaches
  the user (`Get-Help` piping a queried command's `--help` output through
  `bat`). Returns a `CommandResult` (`exitCode`, `output`, `error`).
- `runner.runQuiet(cmd, args)` — runs the child, discards both streams, returns
  only the exit code. Use when only success/failure matters and nothing is ever
  shown.

Draining is not optional. `osproc` gives each stream its own OS pipe with a
small fixed buffer; a child that writes past it blocks until something reads
that pipe. Reading one stream to completion before starting the other deadlocks
the parent as soon as a child writes enough to both — `capture`'s real
implementation drains stdout and stderr concurrently on separate threads
specifically to avoid this, and `runQuiet` is built on top of `capture` rather
than a simpler discard-both call for the same reason.

`capture` also has an early-exit contract worth knowing before relying on it: a
child that exits, or closes its stdin, before consuming all of `input` is not an
error. The write simply stops there; the drain threads are still joined, the
child is still reaped, and `capture` returns its real exit code along with
whatever it did emit before exiting. A program piping into a pager or a
`head`-shaped filter exiting early is the normal case, not a fault — a caller
that must know the payload arrived in full has to arrange its own
acknowledgement, because `capture` itself never raises for this.

One divergence from `osproc`'s `execProcess` is invisible to the argv-pinning
tests and worth knowing if `capture`/`runQuiet` grow a new consumer:
`execProcess` used to append a trailing newline to output that lacked one, while
`capture`'s `output`/`error` are the child's bytes verbatim. Today this is
correctly absorbed at all four consumers — `UpdateDockerImage.nim`'s
`filterImages` and `RemoveDockerDanglingImages.nim`/
`RemoveDockerDanglingVolumes.nim`'s `parseDockerList` all drop empty lines, and
`GetDefaultBrowser.nim` strips its result — but a future consumer must not
assume a trailing newline is there.

## Error handling and the exit-code contract

| Exit code     | Meaning                                                                                                                                                                                                                                                                                            |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `0`           | Success                                                                                                                                                                                                                                                                                            |
| `1`           | Usage error (bad or missing argument, unknown flag) or a validation failure (`requireArg`, `requirePathTarget`, etc. returning `false`)                                                                                                                                                            |
| `2`           | A required external command is missing (`checkDeps` returning `false`)                                                                                                                                                                                                                             |
| anything else | Command-specific. A passthrough function should normally return the subprocess's own exit code (for example, `Get-ZfsSnapshots` returns whatever `zfs list` exited with); an orchestration function may deliberately normalize or combine failures, but that policy must be documented and tested. |

`files/nim/lib/cli.nim`'s `cliMain` template is the top-level safety net: every
function's `when isMainModule` block reads `cliMain(run(commandLineParams()))`,
which catches any `CatchableError` escaping `run()`, prints it as an `Error:`
line on stderr (via the same unqualified `error(...)` from `output`), and exits
`1` — this preserves the stdout=data/stderr=status contract instead of letting a
raw Nim traceback reach the user. Treat it as a backstop, not the primary
error-reporting mechanism: a local `try/except` inside `run()` is still
preferred wherever a specific message ("Not a git repository") beats the generic
exception text `cliMain` would otherwise print. `InitializeClaudeProject.nim`
has several such local checks.

## Resource ownership

Process handles are owned entirely inside `process.nim`. `startProcess`'s result
is a local variable in `realRunInherited`/`realCapture`, closed via
`defer: p.close()` (or an explicit `finally`, for `capture`, once its drain
threads have joined) before the proc returns. A function's `run()` never sees a
`Process` value and never closes one — it only ever sees the `Runner` it was
given and the `int`/`CommandResult` a call through it returns.

## Test doubles

Two mechanisms exist; which one applies depends on what's under test.

**`newRecordingRunner`** (`lib/testing.nim`) is the default for a function's own
tests. It spawns nothing: pass `rec.runner` as `run()`'s `runner` argument, call
`run()`, then assert on `rec.calls` — each entry records the `kind`
(`"inherited"`/`"capture"`), `cmd`, `args`, and any `input` that call carried.
Its canned `exitCode`/`output`/`error` (set at construction) become what every
`capture`/`runQuiet` call through it sees, so a test can also drive a function's
post-processing of subprocess output without touching a real process. This is
what argv-pinning "contract" tests in `functions/tests/` use, e.g.
`test_enter_nix_shell.nim`'s "contract: nix shell is called with
nixpkgs#-prefixed installables".

**`withPath` + `writeFakeExe`** (also `lib/testing.nim`) cover two cases
`newRecordingRunner` can't: `lib/process.nim`'s own tests, which must exercise a
real `fork`/`exec` round trip against `realRunInherited`/ `realCapture` rather
than the interception seam, and a function's dependency-missing branch, which
depends on `findExe` genuinely failing to find something on `$PATH`.
`withPath(dir): body` replaces `$PATH` with `dir` for the block's duration;
`writeFakeExe(dir, name, script)` writes an executable `/bin/sh` script at
`dir/name` standing in for a real command (the pristine `$PATH`, captured once
at module load, is baked into the stub so its own body can still shell out to
real utilities like `cat`/`wc` even while the test process's `$PATH` is the
fixture directory).

One wrinkle worth knowing: a `newRecordingRunner` contract test can still need a
`withPath`/`writeFakeExe` stub, purely to get a `checkDeps` call to pass before
the recording runner's interception ever matters. The test sandbox has no
`docker` or `zfs` in `nativeBuildInputs`, so e.g.
`test_update_docker_image.nim`'s contract tests write an empty-bodied `docker`
stub under `withPath` before calling `run()` — `checkDeps` finds it on `$PATH`
and passes, but the stub is never actually executed, because `rec.runner`
intercepts the spawn that `checkDeps`'s pass unlocks.

## Testing

`std/unittest` (stdlib, no nimble dependency) covers the `ax` module and each
function's `run()`. `checks.${system}.nim-functions-tests` in `flake.nix` runs
every `lib/tests/*.nim` and `functions/tests/*.nim` file under
`nix flake check`, so a broken function fails the same gate as a broken Nix
expression.

Dependency checks are testable in both directions, not just the happy path.
`checkDeps` calls `findExe`, which reads `$PATH` at **runtime** — `nim c -r`
compiles the test binary and only then runs it, so there's no sense in which a
dependency is present or absent "at compile time." Point `withPath` (see Test
doubles above) at an empty directory to construct the "command missing" branch:
`checkDeps` fails and the function returns exit code `2` with a
`Missing commands: ...` message on stderr —
`functions/tests/test_get_zfs_snapshots.nim` and
`test_convert_to_video_horizontal.nim` cover this branch for real. It is not
untestable; six test files that once carried a comment claiming otherwise have
since been rewritten to prove it.

Some test cases still need a genuinely-present tool for a value beyond "present
or absent" — e.g. `Get-Attribute`'s tests exercise `getfattr`, from the `attr`
package, for real past the `checkDeps` call. Add that package to the `checks`
derivation's `nativeBuildInputs`, and to the devShell's `packages` for local
runs — and consider a comment in the test file noting the dependency, since a
missing one produces confusing failures that look like validation bugs.

The non-TTY and `NO_COLOR` branches of `output.error` are covered without any
special terminal setup. The color-enabled branch needs a pseudo-terminal on this
Linux-only project; that coverage is feasible, but deferred because its value is
currently lower than the subprocess and CLI-contract tests. Do not describe it
as an untestable or permanent gap.

## Local development

`devShells.${system}.default` in `flake.nix` provides `nim` (plus whatever
runtime deps the ported functions need, e.g. `attr`) for editor/`nim-lsp`
support. `.envrc` (`use flake`) activates it via direnv on `cd`. Neither is
required for the actual build — `nix build`/`nix flake check` are self-contained
via `nativeBuildInputs` — this is purely local ergonomics.

## Compile flags

`files/nim/nim.cfg` sets `--styleCheck:error`. Both
`packages.${system}.nim-functions` and `checks.${system}.nim-functions-tests`
pick it up automatically — both derivations set `src = ./files/nim` and run
`nim c` from that directory, and Nim reads `nim.cfg` relative to the directory a
compile is invoked from. The two builds are otherwise deliberately asymmetric:
the package build passes `-d:release`, the test build does not, trading compile
speed and optimization for live `assert`/`doAssert` checks and readable stack
traces in a test binary. Don't "fix" this to match — see the comment beside
`nim-functions-tests` in `flake.nix`.

Resist adding `--warningAsError` or similar for a stricter test gate. Compiling
a function file as a test's `import` dependency (rather than as its own
main-module program) triggers a benign `UnusedImport` warning for `../lib/cli`:
every function does `import "../lib/cli"` for `cliMain`, but `cliMain` is only
ever referenced inside that file's own `when isMainModule` block, which a test
build never compiles. Turning warnings into errors would fail every function's
test on this false positive.

## Integration gaps found while porting the Attribute family

The two gaps flagged after the `Get-Attribute` pilot drove these changes:

- `packages.${system}.nim-functions` builds from an explicit
  `nimFunctionBinaries` attrset (binary name → source file) and fails the build
  if any `functions/*.nim` file has no entry — no more silently-missing
  binaries.
- `files/zsh/functions/Get-UserFunctions` reads `$NIXOTIC_NIM_FUNCTIONS_BIN`
  (set in `home/zsh.nix`'s `programs.zsh.sessionVariables`) and merges
  Nim-installed binaries into its existing tables, tagged `(compiled)`.
  Description extraction is not fully closed: it takes the first non-empty line
  after `Usage:`, so functions whose help starts with a `Description:` heading
  are currently listed with that literal heading instead of the following
  descriptive text. Fix the parser or standardize the help shape before treating
  this integration as complete.
