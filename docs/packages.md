# Package Declaration Guide

Where to declare packages in a NixOS + Home Manager configuration.

## Decision Flowchart

```mermaid
flowchart TD
    Start([Need a package?]) --> Q1{All users?<br/>Root access?}
    Q1 -->|Yes| Sys[environment.systemPackages<br/>`hosts/*/configuration.nix`]
    Q1 -->|No| Q2{GNOME, D-Bus<br/>integration?}
    Q2 -->|Yes| User[users.users.axl.packages<br/>`hosts/*/configuration.nix`]
    Q2 -->|No| Q3{Home Manager<br/>module exists?}
    Q3 -->|Yes| Prog[programs.&lt;name&gt;.enable<br/>`home/*.nix`]
    Q3 -->|No| Home[home.packages<br/>`home/default.nix`]
    
    Sys --> End([Package installed])
    User --> End
    Prog --> End
    Home --> End
    
    style Sys fill:#e1f5ff
    style User fill:#fff3e0
    style Prog fill:#f3e5f5
    style Home fill:#e8f5e9
```

## Quick Reference

### 1. `environment.systemPackages`

**Location:** `hosts/*/configuration.nix`  
**Use for:** System-wide tools, root access, all users

Examples:
- System utilities: `htop`, `wget`, `file`, `lsof`
- System administration: `clamav`, `plocate`
- Core editors: `neovim` (if needed for root)

### 2. `users.users.<name>.packages`

**Location:** `hosts/*/configuration.nix`  
**Use for:** User-specific packages needing system integration

Examples:
- GUI applications with D-Bus/GNOME integration
- Browsers: `brave`, `ungoogled-chromium`
- Apps requiring system services

### 3. `home.packages`

**Location:** `home/default.nix`  
**Use for:** Most user CLI tools and development packages

Examples:
- Version control: `gh`, `tig`
- Development: `helix`, `tokei`
- CLI utilities: `fd`, `ripgrep`, `fdupes`, `bfs`
- Media: `mpv`

### 4. `programs.<name>.enable`

**Location:** `home/*.nix` (dedicated module file)  
**Use for:** Tools with Home Manager configuration modules

Examples:
- Shell: `programs.zsh` → `home/zsh.nix`
- Terminal: `programs.kitty` → `home/kitty.nix`
- Version control: `programs.git` → `home/git.nix`
- File browser: `programs.ranger` → `home/ranger.nix`
- Prompt: `programs.starship` → `home/starship.nix`

## Checking for Home Manager Modules

```bash
# Search for available programs
man home-configuration.nix | grep -A2 "programs\."

# Or check online
# https://home-manager-options.extranix.com/
```
