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
├── lib/
│   ├── output.nim       # replaces lib/output.zsh
│   ├── validation.nim   # replaces lib/validation.zsh
│   └── tests/
└── functions/
    ├── GetAttribute.nim
    ├── GetAttributes.nim
    ├── SetAttribute.nim
    ├── RemoveAttribute.nim
    └── tests/
```

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

That mapping is spelled out explicitly per function in `flake.nix`'s `let`
block as the `nimFunctionBinaries` attrset, not derived from the source
filename:

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

The `packages.${system}.nim-functions` derivation's build phase uses this attrset
to construct one `nim c` invocation per function, and fails loudly if any
`functions/*.nim` file has no matching entry — no more silently-missing binaries.

## Function structure

```nim
import std/[os, osproc]
import "../lib/output"
import "../lib/validation"

proc run*(args: seq[string], outp: File = stdout, errp: File = stderr): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ..."""
    return 0

  # manual option parsing over `args`, same shape as the zsh while/case loop
  ...

  if not requireArg(attribute, "attribute", errp): return 1
  ...
  return 0

when isMainModule:
  quit(run(commandLineParams()))
```

- Help-before-parsing (Pattern 1 from the zsh conventions doc) is unchanged.
- Logic lives in `run()`, separate from the `when isMainModule` entry point, so
  `std/unittest` can call `run()` directly with fake argv — no subprocess
  spawning needed for most test cases.
- `run()` takes optional `outp`/`errp` `File` params (default `stdout`/`stderr`)
  so tests can redirect a case to a temp file and assert on captured output
  (used for the `--help` case in `Get-Attribute`'s tests).
- `proc run*` and any helper `proc`s a test needs must be marked `*` (exported)
  — the test file `import`s the function's module directly by relative path
  (e.g. `import "../GetAttribute"`).

## The `ax` module

`files/nim/lib/output.nim` and `validation.nim` replace `lib/output.zsh` and
`lib/validation.zsh`. Grow this module **only with procs an actual function
needs** — don't port the full zsh helper surface speculatively.

Ported so far:

| zsh | Nim |
|---|---|
| `__ax_error` | `output.error*(msg: string, errp: File = stderr)` |
| `__ax_require_arg` | `validation.requireArg*(value, name, errp): bool` |
| `__ax_check_deps` | `validation.checkDeps*(cmds: openArray[string], errp): bool` |
| `__ax_require_path_target` | `validation.requirePathTarget*(path, errp): bool` |
| `__ax_require_xattr_name` | `validation.requireXattrName*(attribute, errp): bool` |
| `__ax_require_writable_path_target` | `validation.requireWritablePathTarget*(path, errp): bool` |

**Not yet ported** (add when the first function that needs one migrates):
`__ax_warn`, `__ax_info`, `__ax_success`, `__ax_verbose`, `__ax_confirm`,
`__ax_table`, `__ax_require_file`, `__ax_require_dir`, `__ax_require_root`,
`__ax_require_extension`.

Naming convention: procs drop the `__ax_` prefix and use camelCase (Nim style),
scoped by module import rather than a shared prefix — `output.error(...)`,
`validation.requireArg(...)`.

Output contract carries over exactly: stdout for data, stderr for status; color
suppressed when stderr isn't a TTY, or when `NO_COLOR` is set to **any** value
including empty string (`os.existsEnv("NO_COLOR")`, not a truthiness check on
its value — this matches zsh's `${NO_COLOR+x}` set-ness test, which a naive
`getEnv("NO_COLOR") == ""` check would get wrong).

## Testing

`std/unittest` (stdlib, no nimble dependency) covers the `ax` module and each
function's `run()`. `checks.${system}.nim-functions-tests` in `flake.nix` runs
every `lib/tests/*.nim` and `functions/tests/*.nim` file under
`nix flake check`, so a broken function fails the same gate as a broken Nix
expression.

Some test cases legitimately depend on an external tool being on `$PATH` at
test-compile-time (e.g. `Get-Attribute`'s tests need `getfattr`, from the `attr`
package, to reach validation steps that run after a `checkDeps` call). Add that
package to the `checks` derivation's `nativeBuildInputs`, and to the devShell's
`packages` for local runs — and consider a comment in the test file noting the
dependency, since a missing one produces confusing failures that look like
validation bugs.

Testing the color/`NO_COLOR` branches of `output.error` isn't practical without
a real TTY — that's an accepted, permanent coverage gap, not something to chase.

## Local development

`devShells.${system}.default` in `flake.nix` provides `nim` (plus whatever
runtime deps the ported functions need, e.g. `attr`) for editor/`nim-lsp`
support. `.envrc` (`use flake`) activates it via direnv on `cd`. Neither is
required for the actual build — `nix build`/`nix flake check` are self-contained
via `nativeBuildInputs` — this is purely local ergonomics.

## Gaps closed while porting the Attribute family

Both gaps flagged after the `Get-Attribute` pilot are now closed:

- `packages.${system}.nim-functions` builds from an explicit
  `nimFunctionBinaries` attrset (binary name → source file) and fails the
  build if any `functions/*.nim` file has no entry — no more
  silently-missing binaries.
- `files/zsh/functions/Get-UserFunctions` reads `$NIXOTIC_NIM_FUNCTIONS_BIN`
  (set in `home/zsh.nix`'s `programs.zsh.sessionVariables`) and merges
  Nim-installed binaries into its existing tables, tagged `(compiled)`,
  using each binary's own `--help` text for its description (there's no
  source comment to read on a compiled file).
