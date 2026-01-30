# ZSH Functions Naming Conventions

## Function Names

Functions use **PascalCase Verb-Noun** naming (PowerShell-style):

| Verb         | Purpose                      | Example                           |
| ------------ | ---------------------------- | --------------------------------- |
| `Get-`       | Retrieve/display information | `Get-Help`, `Get-IpAddress`       |
| `Set-`       | Configure/modify state       | `Set-Attribute`                   |
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
| `Confirm-`   | Verify/validate              | `Confirm-GitUntrackedCache`       |
| `Reset-`     | Restore defaults             | `Reset-GnomeSettings`             |
| `Resolve-`   | Determine/lookup             | `Resolve-GitRepositoryPath`       |
| `Clear-`     | Remove cached data           | `Clear-DnsCache`                  |
| `Measure-`   | Benchmark/profile            | `Measure-Performance`             |

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
| `__ax_info`      | Green info message                         |
| `__ax_success`   | Green success message                      |
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

