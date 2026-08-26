# ZSH Functions Naming Conventions

## Function Names

Functions use **PascalCase Verb-Noun** naming (PowerShell-style):

| Verb         | Purpose                      | Example                           |
| ------------ | ---------------------------- | --------------------------------- |
| `Get-`       | Retrieve/display information | `Get-Help`, `Get-IpAddress`       |
| `Set-`       | Configure/modify state       | `Set-TrailingNewline`             |
| `New-`       | Create a new resource        | `New-Function`, `New-Vault`       |
| `Remove-`    | Delete a resource            | `Remove-Vault`                    |
| `Start-`     | Begin a process/container    | `Start-DockerJupyterNotebook`     |
| `Stop-`      | End a process/container      | `Stop-DockerZshUbuntu`            |
| `Connect-`   | Attach to a resource         | `Connect-DockerZshUbuntu`         |
| `Invoke-`    | Run a command/tool           | `Invoke-DockerTesseract`          |
| `Update-`    | Refresh/upgrade              | `Update-DockerImages`             |
| `Read-`      | Stream/follow content        | `Read-Log`, `Read-DockerLog`      |
| `Write-`     | Output/save content          | `Write-Image`, `Write-Executable` |
| `Test-`      | Check/validate               | `Test-SslHandshake`               |
| `Mount-`     | Attach/activate              | `Mount-Vault`                     |
| `Dismount-`  | Detach/deactivate            | `Dismount-Vault`                  |
| `ConvertTo-` | Transform format             | `ConvertTo-PdfDocument`           |
| `Show-`      | Display interactively        | `Show-GitHubLicense`              |
| `Find-`      | Search for resources         | `Find-DockerImages`               |
| `Open-`      | Launch a resource in its associated application | `Open-File`     |
| `Confirm-`   | Verify/validate              | `Confirm-GitUntrackedCache`       |
| `Reset-`     | Restore defaults             | `Reset-GnomeSettings`             |
| `Resolve-`   | Determine/lookup             | `Resolve-GitRepositoryPath`       |
| `Clear-`     | Remove cached data           | `Clear-DnsCache`                  |
| `Measure-`   | Benchmark/profile            | `Measure-Performance`             |

## Output Contract

**stdout carries data. stderr carries status.**

- `__ax_error`, `__ax_warn`, `__ax_info`, `__ax_success` all write to stderr
- Functions that produce no data (action takers: `New-`, `Remove-`, `Update-`, etc.)
  write nothing to stdout — only status to stderr
- Color is suppressed automatically when the output stream is not a TTY, or when
  `NO_COLOR` is set (any value)

## Creating New Functions

Use `New-Function` to generate templates:

```zsh
# Simple wrapper (1-15 lines)
New-Function wrapper Get-Weather

# Structured function with options (16-80 lines)
New-Function function -d "Process log files" Process-Logs

# Full automation script (81+ lines)
New-Function script -a "axler8r" Deploy-App

# Preview without creating file
New-Function --dry-run function Test-Something
```

Accepts both `Get-Data` and `get-data` - outputs PascalCase filename.

## Aliases

```zsh
# PascalCase is the autoloaded function filename
# lowercase is the shortcut alias in zshalias

alias get-help=' Get-Help '
alias start-dockerjupyternotebook=' Start-DockerJupyterNotebook '
```

## Template Tiers

| Type       | Lines | Use Case                            |
| ---------- | ----- | ----------------------------------- |
| `wrapper`  | 1-15  | Simple command wrappers             |
| `function` | 16-80 | Structured with options/help        |
| `script`   | 81+   | Full automation with logging, traps |

## `--raw` Flag

All `Get-`, `Find-`, `Resolve-`, and `Measure-` functions that produce structured or
formatted output must accept `--raw`.

`--raw` output:
- Plain text only — no color, no borders, no gum
- One record per line for lists
- Tab-separated fields for structured data
- Suitable for `grep`, `awk`, `sort`, `xargs`

Functions using `__ax_table` pass `$_raw_flag` through directly. `__ax_table` also
auto-detects non-TTY stdout, so pipelines get plain output without needing `--raw`.

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

Pattern 2 (the `local _help=...` / `_help_flag` / inner `_help()` / `unfunction` approach)
is retired.

## Shared Libraries

Reusable configuration and helpers live in `lib/`:

```
files/zsh/
├── lib/
│   ├── docker.zsh      # Docker argument arrays
│   ├── output.zsh      # Colored output helpers (__ax_error, __ax_warn, __ax_info, etc.)
│   └── validation.zsh  # Input validation (__ax_check_deps, __ax_require_file, etc.)
└── functions/
    └── Start-Docker*   # Source lib/docker.zsh
```

Functions source libraries with:
```zsh
source "${0:h}/../lib/output.zsh"
source "${0:h}/../lib/validation.zsh"
```

### Output Helpers (lib/output.zsh)

| Helper           | Purpose                                    |
| ---------------- | ------------------------------------------ |
| `__ax_error`     | Red error message to stderr                |
| `__ax_warn`      | Yellow warning message to stderr           |
| `__ax_info`      | Green info message to stderr               |
| `__ax_success`   | Green success message to stderr            |
| `__ax_verbose`   | Blue debug message (if `_verbose_flag` set)|
| `__ax_confirm`   | Interactive y/N prompt                     |

### Validation Helpers (lib/validation.zsh)

| Helper                 | Purpose                              |
| ---------------------- | ------------------------------------ |
| `__ax_check_deps`      | Check if commands exist              |
| `__ax_require_file`    | Require file exists                  |
| `__ax_require_dir`     | Require directory exists             |
| `__ax_require_arg`     | Require argument not empty           |
| `__ax_require_root`    | Require running as root              |
| `__ax_require_extension` | Require file has extension         |

