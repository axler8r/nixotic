# The `ax` CLI

`ax` is the single namespaced driver for the nixotic Nim toolbelt. It replaces
the flat PascalCase `Verb-Noun` binaries with a resource-first command tree, a
small lexicon of ordinary Linux verbs, and one registry **derived at build
time** from the binaries actually built. The registry is the sole source for
dispatch and shell completion. This guarantees command inventory agreement;
manual parsers and help text still need contract and integration tests.

Companion doc: `docs/nim-functions-conventions.md` covers the Nim
implementation patterns every command follows (process execution through
`Runner`, test doubles, error handling). The surviving PascalCase zsh
functions in `files/zsh/functions/` are governed by
`docs/zsh-functions-conventions.md`, not by this doc.

## Grammar

```
ax [global flags] <group> [<subgroup>] <command> [args]
```

- Command paths are 2 or 3 words (`vault mount`, `git wip start`); with `ax`
  itself the full invocation is at most 4 words before command args.
- Every path segment matches `[a-z][a-z0-9]*` — lowercase, no hyphens — so
  the path↔binary mapping is mechanically reversible.
- **The command word is normally a verb** from the lexicon below.
- **A documented minority of leaves are report-nouns** — read-only,
  `-o`-aware, no side effects: `ax sys swap`, `ax fs histogram`,
  `ax git repo root`, `ax fs words`, `ax sys browser`, `ax dev templates`.
  This is the `kubectl top nodes` / `systemctl status` precedent: a
  deliberate, enumerated exception, not drift.

## Verb lexicon

The runtime and eval-time source of truth is `files/nim/lexicon.json`; this
table documents it. Aliases are accepted by the driver in the command
position and resolved before dispatch; the registry stores canonical names
only.

| Verb | Meaning | Alias |
| --- | --- | --- |
| `list` | enumerate a collection to stdout | `ls` |
| `get` | print one scalar value, script-friendly | |
| `show` | render one item in detail | `info` |
| `search` | query a remote index | |
| `create` | make a new resource | `new` |
| `remove` | delete a named resource | `rm` |
| `set` | write a value | |
| `update` | refresh in place | |
| `sync` | reconcile with a source of truth | |
| `prune` | remove unreferenced/dangling resources | |
| `mount` / `unmount` | attach / detach | `umount` |
| `resize` | change a resource's size | |
| `start` / `finish` / `drop` | lifecycle (WIP branch) | |
| `optimize` | maintenance pass | |
| `check` / `fix` | validate (non-zero on failure) / its mutating twin | |
| `convert` | transform format | |
| `init` | bootstrap in the current directory | |
| `shell` | open an interactive session | |

Report-nouns (complete list): `browser`, `histogram`, `root`, `swap`,
`templates`, `words`.

A leaf outside verbs ∪ report-nouns fails the build twice over: at Nix eval
time against the source tree, and in `ax self build-registry` against the
emitted specs.

## Cross-cutting contract

Handled **once, in the driver**: these flags are recognised anywhere in argv
(before the group or after the command), consumed, and passed down as
environment variables. A literal `--` stops extraction. Command binaries read
the context **exclusively from the environment** (`lib/context.nim`), so a
binary behaves identically whether reached through `ax` or invoked directly
from `libexec/ax/` with `AX_*` set.

The driver preserves `--` for the command parser. Direct libexec callers may
also use the legacy `--raw` alias and supported dry-run switches. Specifications
may not redeclare global options: for example, word counts use `--top`, not
the reserved `-n`.

| Flag | Env | Values / notes |
| --- | --- | --- |
| `-o, --output <v>` | `AX_OUTPUT` | `table` (default) \| `plain` \| `json`. `--raw` is a deprecated alias for `-o plain`. |
| `-n, --dry-run` | `AX_DRY_RUN` | `1` when set. A command whose spec declares `dryRun: false` refuses to run under it (exit 64) — `-n` can never silently mutate. |
| `--color <v>` | `AX_COLOR` | `auto` (default) \| `always` \| `never`. `NO_COLOR` is honoured on `auto`; an explicit `always` wins over it. |
| `-q, --quiet` | `AX_QUIET` | `1` when set: suppresses `Info:`/`Success:` status lines. |
| `-v, --verbose` | `AX_VERBOSE` | `1` when set: commands may add diagnostics on stderr. |
| `-h, --help` / `-V, --version` | — | driver-handled. |

Builtin help is handled before effects or registry loading. Mutating builtins
must enforce dry-run policy too; `self new-command` refuses dry-run rather
than writing files. Help remains available when `AX_DRY_RUN=1` is inherited.

**stdout carries data, stderr carries status** — unchanged. Every list and
report command renders tabular data through `lib/output.nim`'s `render()`:
`table` is the gum/column view, `plain` the aligned script-friendly view, and
`json` an array of objects keyed by the lowercased header cells — every such
command is a first-class `jq` source:

```
ax docker image list -o json | jq '.[].repository'
```

Commands whose output is a scalar or progress text ignore `AX_OUTPUT`
(`ax zfs snapshot list` maps `-o plain` to `zfs list -H` and keeps zfs's own
formatting).

### Exit codes

| Code | Meaning |
| --- | --- |
| 0 | success |
| 1 | runtime error |
| 2 | missing dependency (`checkDeps` failure) |
| 64 | usage error (`EX_USAGE`, sysexits.h): missing required argument, unknown flag, invalid flag value, unresolvable command path |

## The driver

`bin/ax` locates everything relative to itself
(`getAppFilename()` → prefix → `libexec/ax/`, `share/ax/registry.json`,
`share/ax/groups.json`), resolves the command path by longest-prefix match
against the registry, exports `AX_*`, and **execs** the command binary — exit
codes and signals pass straight through.

Builtins (never in the registry, exempt from the lexicon):

| Invocation | Behaviour |
| --- | --- |
| `ax` | overview: usage, global flags, group list |
| `ax help [<path>]` | subtree listing, or one command's `--help` through `bat`; a topic outside the ax tree that names a `$PATH` executable gets the same bat rendering (`ax help git commit`) — the `help`/`h` aliases lean on this |
| `ax version` / `-V` | version |
| `ax self commands` | every registry command plus the surviving zsh functions, `-o` aware |
| `ax self doctor` | audits every command's declared dependencies against `$PATH` |
| `ax self completion zsh\|bash\|nu` | emits a completion script generated from the registry |
| `ax self new-command <group> [<subgroup>] <leaf>` | scaffolds a new command (below) |
| `ax self build-registry` | regenerates the registry from `libexec/ax/` (the package build calls this) |

A bare group (`ax vault`) prints the subtree help on stderr and exits 64;
`ax` alone is the only zero-exit bare form.

## Registry mechanics

Each command binary answers the hidden `--ax-spec` flag with its own spec as
JSON — path, kind (`verb`/`report`), summary, usage, args, flags, external
dependencies, dry-run support. The spec lives in the command's source as a
`CommandSpec` value (`lib/spec.nim`) and is emitted by the shared `axMain`
entry template.

At package-build time, `ax self build-registry` runs every built
`libexec/ax/ax-*` binary and concatenates the answers into
`share/ax/registry.json`, validating each against its binary name and the
lexicon. A registry generated from the binaries that were actually built
cannot disagree with them. The same build then generates `_ax` (zsh
completion) from that registry.

The final package is assembled by a `runCommand`, **not** a `symlinkJoin`,
and the driver binary is a real copy: `getAppFilename()` reads
`/proc/self/exe`, which fully resolves symlinks, so a symlinked driver would
look for `libexec/ax/` inside its own build derivation. Command binaries stay
symlinked — they locate nothing relative to themselves — so a one-command
edit rebuilds one small derivation plus the trivial final join.

## Source layout — the directory tree IS the command tree

```
files/nim/
  nim.cfg                      # --styleCheck:error
  lexicon.json                 # verb lexicon + report-noun exceptions
  ax.nim                       # driver (thin main)
  lib/                         # shared modules; driver logic in lib/driver.nim
  commands/
    groups.json                # one-line summary per group/subgroup
    vault/mount.nim            # -> ax vault mount     -> ax-vault-mount
    vault/tests/test_mount.nim
    git/wip/start.nim          # -> ax git wip start   -> ax-git-wip-start
    ...
```

`commands/<group>/[<subgroup>/]<leaf>.nim` maps mechanically to command path
and binary name. There is no name table: lowercase path segments made the
mapping reversible, which is why the old `nimFunctionBinaries` attrset and
its drift guard could be deleted.

Eval-time asserts in `flake.nix` fail before anything builds on: a path
outside the 2–3 word grammar, a segment the mapping cannot reverse, a leaf
outside the lexicon, or a group directory missing its `groups.json` entry.
Tests derive their subject from their own path
(`commands/<dir>/tests/test_<leaf>.nim` → `commands/<dir>/<leaf>.nim>`), also
asserted at eval time.

The `ax-smoke` check then asserts, in both directions: sources ↔
`libexec/ax/` ↔ registry agree; every registry leaf is lexicon-approved;
`ax <path> --help` exits 0 through the driver for every command; and the
generated `_ax` parses.

The independent `ax-integration` check compiles a harmless fixture command
and exercises actual exec dispatch, argv/context preservation, failures,
exception reporting, and builtin help/dry-run non-mutation. Command suites
normally have one subject; the vault safety matrix includes all five vault
commands explicitly to test lifecycle interactions.

## Adding a command

```
ax self new-command zfs snapshot remove
```

scaffolds `commands/zfs/snapshot/remove.nim` (spec + `run*` skeleton +
`axMain`), the matching `tests/test_remove.nim`, and seeds `groups.json` if
the group is new — after validating the leaf against the lexicon. Then:

1. Fill in the spec's summary/usage/args/flags/deps and the `run*` body,
   following `docs/nim-functions-conventions.md` (injectable streams and
   `Runner`, `checkDeps` guards, usage errors exit 64).
2. Write the tests — one test file per command, exercising `run()` directly.
3. Review and stage new files so they belong to the Git flake source.
4. With user approval, `nix flake check` — the new command and its test are discovered from the
   tree; there is no list to update.

If the command belongs to a new group, give the group a real one-line summary
in `commands/groups.json` — help and completion display it.
