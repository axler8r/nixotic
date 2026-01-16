# nixotic
NixOS Flakes + Home Manager configuration for my personal systems.

## Hosts

| Host | Description | Status |
|------|-------------|--------|
| `demonstr8r` | VM for developing NixOS configuration | ✅ Active |
| `ambul8r` | Laptop | 📋 Placeholder |
| `infer8r` | ML workstation | 📋 Placeholder |

## Quick Start
```bash
# Clone
git clone https://github.com/axler8r/nixotic.git ~/.nixotic

# Rebuild (requires --impure for hardware-configuration.nix)
sudo nixos-rebuild switch --flake ~/.nixotic#demonstr8r --impure
```

## Structure
```
.nixotic/
├── flake.nix              # Flake inputs and outputs
├── hosts/                 # Host-specific configurations
│   ├── demonstr8r/        # Development VM
│   ├── ambul8r/           # Laptop (placeholder)
│   └── infer8r/           # ML workstation (placeholder)
├── home/                  # Home Manager modules
│   ├── default.nix        # Main entry point
│   ├── zsh.nix            # Shell + fzf + zoxide
│   ├── tmux.nix           # Tmux with Solarized status bar
│   ├── kitty.nix          # Terminal emulator
│   ├── git.nix            # Git + tig
│   ├── starship.nix       # Prompt
│   ├── bat.nix            # Cat replacement
│   ├── dircolors.nix      # LS_COLORS
│   └── files.nix          # System dotfiles
└── files/                 # Source files for home.file/xdg.configFile
    ├── git/               # tigrc
    ├── julia/             # startup.jl, Solarized.jl
    ├── kitty/             # kitty.conf, themes
    ├── starship/          # starship.toml
    ├── system/            # .XCompose, .ctags, .hidden
    └── zsh/               # 54 functions + zshalias
```

## Adding a New Host
1. Create `hosts/<hostname>/configuration.nix`
2. Copy hardware config: `cp /etc/nixos/hardware-configuration.nix hosts/<hostname>/`
3. Add to `flake.nix` outputs (uncomment or add new entry)
4. Rebuild: `sudo nixos-rebuild switch --flake ~/.nixotic#<hostname> --impure`

## Project-Specific Tools
Use `shell.nix` or `flake.nix` + direnv for project-specific dependencies:

```nix
# shell.nix
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  packages = with pkgs; [ python3 nodejs ];
}
```

## License
[MIT](LICENSE)
