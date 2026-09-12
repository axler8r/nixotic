# ZSH Functions Conventions

Governs the PascalCase zsh scripts in `files/zsh/functions/` — the surviving zsh
population, which is frozen: new commands are Nim, live under
`files/nim/commands/`, and are governed by `docs/ax-cli-design.md` and
`docs/nim-functions-conventions.md`, not by this doc. `New-Function`, the zsh
scaffolder, is retired accordingly (`ax self new-command` scaffolds Nim
commands).

## Function Names

Functions use **PascalCase Verb-Noun** naming (PowerShell-style). Verbs in use
by the surviving population:

| Verb         | Purpose                                         | Example                       |
| ------------ | ----------------------------------------------- | ----------------------------- |
| `Get-`       | Retrieve/display information                    | `Get-SystemInformation`       |
| `Set-`       | Configure/modify state                          | `Set-TrailingNewline`         |
| `New-`       | Create a new resource                           | `New-ZfsLayout`               |
| `Remove-`    | Delete a resource                               | `Remove-ZfsSnapshot`          |
| `Start-`     | Begin a process/container                       | `Start-DockerJupyterNotebook` |
| `Update-`    | Refresh/upgrade                                 | `Update-GitWIPBranchHistory`  |
| `Read-`      | Stream/follow content                           | `Read-Log`, `Read-DockerLog`  |
| `Write-`     | Output/save content                             | `Write-Image`                 |
| `Test-`      | Check/validate                                  | `Test-SslHandshake`           |
| `Mount-`     | Attach/activate                                 | `Mount-Nfs`                   |
| `ConvertTo-` | Transform format                                | `ConvertTo-H264Video`         |
| `Show-`      | Display interactively                           | `Show-GitHubLicense`          |
| `Open-`      | Launch a resource in its associated application | `Open-File`                   |
| `Reset-`     | Restore defaults                                | `Reset-GnomeSettings`         |
| `Clear-`     | Remove cached data                              | `Clear-DnsCache`              |
| `Prepare-`   | Provisioning helper                             | `Prepare-NewHost`             |

## Output Contract

**stdout carries data. stderr carries status.**

- `__ax_error`, `__ax_warn`, `__ax_info`, `__ax_success` all write to stderr
- Functions that produce no data (action takers: `New-`, `Remove-`, `Update-`,
  etc.) write nothing to stdout — only status to stderr
- Color is suppressed automatically when the output stream is not a TTY, or when
  `NO_COLOR` is set (any value)

## Aliases

```zsh
# PascalCase is the autoloaded function filename
# lowercase is the shortcut alias in zshalias

alias follow=' Read-Log '
alias rmzsnap=' Remove-ZfsSnapshot '
```

## `--raw` Flag

Functions that produce structured or formatted output must accept `--raw`.

`--raw` output:

- Plain text only — no color, no borders, no gum
- One record per line for lists
- Tab-separated fields for structured data
- Suitable for `grep`, `awk`, `sort`, `xargs`

Functions using `__ax_table` pass `$_raw_flag` through directly. `__ax_table`
also auto-detects non-TTY stdout, so pipelines get plain output without needing
`--raw`.

## Help Pattern

**Pattern 1 is the only pattern.** Place the help check before argument parsing.

```zsh
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat << EOF
Usage: ${0:t} [opts] [args]

One-line description of what this function does.

Options:
    -h, --help    Show this help message
    --raw         Plain text output    ← data-producing functions only

Arguments:
    <arg>         Description          ← omit section if no positional args

Examples:
    ${0:t} foo
    ${0:t} --raw | grep something
EOF
    return 0
fi
```

Pattern 2 (the `local _help=...` / `_help_flag` / inner `_help()` / `unfunction`
approach) is retired.

## Shared Libraries

Reusable configuration and helpers live in `lib/`:

```
files/zsh/
├── lib/
│   ├── docker.zsh      # Docker argument arrays
│   ├── git.zsh         # Git helpers (also ported to lib/git.nim; this copy
│   │                   #   stays for Update-GitWIPBranchHistory)
│   ├── output.zsh      # Colored output helpers (__ax_error, __ax_warn, ...)
│   └── validation.zsh  # Input validation (__ax_check_deps, ...)
└── functions/
    └── Start-Docker*   # Source lib/docker.zsh
```

Functions source libraries with:

```zsh
source "${0:h}/../lib/output.zsh"
source "${0:h}/../lib/validation.zsh"
```

### Output Helpers (lib/output.zsh)

| Helper         | Purpose                                     |
| -------------- | ------------------------------------------- |
| `__ax_error`   | Red error message to stderr                 |
| `__ax_warn`    | Yellow warning message to stderr            |
| `__ax_info`    | Green info message to stderr                |
| `__ax_success` | Green success message to stderr             |
| `__ax_verbose` | Blue debug message (if `_verbose_flag` set) |
| `__ax_confirm` | Interactive y/N prompt                      |

### Validation Helpers (lib/validation.zsh)

| Helper                   | Purpose                    |
| ------------------------ | -------------------------- |
| `__ax_check_deps`        | Check if commands exist    |
| `__ax_require_file`      | Require file exists        |
| `__ax_require_dir`       | Require directory exists   |
| `__ax_require_arg`       | Require argument not empty |
| `__ax_require_root`      | Require running as root    |
| `__ax_require_extension` | Require file has extension |
