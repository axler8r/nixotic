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

Reusable configuration lives in `lib/`:

```
files/zsh/
├── lib/
│   └── docker.zsh    # Docker arg arrays
└── functions/
    └── Start-Docker* # Source lib/docker.zsh
```

Functions source libraries with:
```zsh
source "${0:h}/../lib/docker.zsh"
```
