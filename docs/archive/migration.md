# Migration Plan: .dotfiles (Ansible/Stow) → .nixotic (NixOS Flakes + Home Manager)
> Created: 7 January 2026


## Overview
Migrate from GNU Stow-managed dotfiles with Ansible provisioning to a
declarative NixOS Flakes + Home Manager configuration.

**Source:** `~/.dotfiles/` (Ansible roles, Stow packages)  
**Target:** `~/.nixotic/` (NixOS Flake + Home Manager)


## Decisions & Agreements
Tracking key decisions made during migration:
| Decision                      | Rationale                                              |
| ----------------------------- | ------------------------------------------------------ |
| **No btop/nvtop in base**     | Nice-to-have, add via project `shell.nix` if needed    |
| **No Powerline**              | Replaced by Starship (prompt) + custom tmux status bar |
| **No rsync in base**          | Project-specific, add via `shell.nix`                  |
| **No webp in base**           | Project-specific for image work                        |
| **No build-essential/gcc**    | Project `shell.nix` handles compilers                  |
| **No ncdu/strace in base**    | Add when needed for debugging                          |
| **No ipython config in base** | Project-specific, use `shell.nix`                      |
| **No powershell config**      | Not used on NixOS                                      |
| **Minimal base philosophy**   | System tools + daily dev essentials only               |
| **Project-specific tools**    | Use `shell.nix` / `flake.nix` + direnv                 |
| **Neovim migration deferred** | Keep vim-plug for now; migrate later                   |


## Phase 0 — Scaffold Flake Structure
Set up `.nixotic/` as a flake that imports existing `/etc/nixos/` configs,
enabling incremental migration without breaking the working system.

### Deliverables
- [x] `flake.nix` with nixpkgs + home-manager inputs
- [x] `hosts/nix000/` importing current `configuration.nix` + `hardware-configuration.nix`
- [x] Symlink from `/etc/nixos/hardware-configuration.nix` → `.nixotic/hosts/nix000/`
- [x] Added `hardware-configuration.nix` to `.gitignore` (machine-specific)

### Target Structure
```
.nixotic/
├── flake.nix
├── flake.lock
├── hosts/
│   └── nix000/
│       ├── configuration.nix
│       └── hardware-configuration.nix
└── home/
    └── default.nix
```


## Phase 1 — Consolidate Packages
Review and finalize package placement. Packages are currently in:
- `users.users.axl.packages` (user CLI tools)
- `environment.systemPackages` (system-wide tools)

### Deliverables
- [x] Audit packages from `ansible/roles/packages/vars/main.yml`
- [x] Audit tools from `ansible/roles/asdf/vars/main.yml`
- [x] Confirm all needed packages are in NixOS config
- [x] Powerline not added (replaced by Starship in Phase 3)
- [x] Philosophy: minimal base + project-specific `shell.nix`


## Phase 2 — Add Home Manager (Minimal)
Integrate Home Manager as a NixOS module with minimal configuration.

### Deliverables
- [x] Add Home Manager flake input
- [x] Import `home-manager.nixosModules.home-manager`
- [x] Create `home/default.nix` with `home.stateVersion`
- [x] Verify `nixos-rebuild switch` works


## Phase 3 — Migrate Easy Dotfiles
Port quick-win configs with native Home Manager modules.

### Deliverables
| Module               | Source                                             | Target              |
| -------------------- | -------------------------------------------------- | ------------------- |
| `programs.starship`  | `dotfiles/terminal/.config/starship/starship.toml` | `home/starship.nix` |
| `programs.bat`       | `dotfiles/bat/.config/bat/config`                  | `home/bat.nix`      |
| `programs.btop`      | `dotfiles/monitor/.config/btop/btop.conf`          | `home/btop.nix`     |
| `programs.dircolors` | `dotfiles/system/.dircolors`                       | `home/default.nix`  |
| `programs.git`       | `dotfiles/git/.gitconfig`                          | `home/git.nix`      |

- [x] Create each module file
- [x] Import modules in `home/default.nix`
- [x] Test configuration
- [x] Remove corresponding stow package symlinks

### Notes
- Starship migrated to pure Nix in Phase 9 (`programs.starship.settings`)
- Bat migrated to pure Nix in Phase 9 (`programs.bat.config`)
- Git config migrated to pure Nix in Phase 9 (`programs.git.settings`)


## Phase 4 — Migrate Terminal (tmux + kitty)
Port terminal configs with Solarized theme, replacing Powerline with custom
status bar.

### Deliverables
| Module           | Source                             | Target           |
| ---------------- | ---------------------------------- | ---------------- |
| `programs.tmux`  | `dotfiles/tmux/.tmux.conf`         | `home/tmux.nix`  |
| `programs.kitty` | `dotfiles/terminal/.config/kitty/` | `home/kitty.nix` |

- [x] Configure tmux plugins via Nix (resurrect, continuum, logging)
- [x] Create Solarized status bar in `extraConfig`
- [x] Migrate kitty settings
- [x] Remove tmux from `environment.systemPackages`
- [x] Remove corresponding stow package symlinks

### Notes
- `jaclu/tmux-menus` not in nixpkgs — omitted for now
- Kitty uses `xdg.configFile.source` to preserve original configs
- Powerline replaced by custom Solarized status bar in tmux


## Phase 5 — Migrate Neovim *(DEFERRED)*
Port editor config. Decide on plugin management strategy.

**Status:** Deferred — will use Option A (keep vim-plug) later to maintain momentum.

### Options
- **Option A:** Keep vim-plug, use `extraConfig = builtins.readFile ./init.vim` ← *preferred*
- **Option B:** Migrate to `programs.neovim.plugins` with Nix packages

### Deliverables
- [ ] Create `home/neovim.nix`
- [ ] Decide on plugin strategy
- [ ] Move neovim from `environment.systemPackages` to Home Manager
- [ ] Remove corresponding stow package symlinks


## Phase 6 — Migrate Zsh (Most Complex)
Port shell config including 54 custom functions and extensive aliases.

### Deliverables
| Component           | Approach                                      |
| ------------------- | --------------------------------------------- |
| Aliases (357 lines) | `home.file.".zshalias"` (kept as source file) |
| Options & init      | `programs.zsh.initExtra`                      |
| History             | `programs.zsh.history`                        |
| Functions (54)      | `home.file.".zsh/functions"`                  |
| Syntax highlighting | `programs.zsh.syntaxHighlighting`             |
| fzf integration     | `programs.fzf.enableZshIntegration`           |
| zoxide integration  | `programs.zoxide.enableZshIntegration`        |

- [x] Create `home/zsh.nix`
- [x] Copy aliases to `files/zsh/zshalias`
- [x] Migrate options from `.zshrc`
- [x] Copy functions directory to `files/zsh/functions/`
- [x] Remove Powerline init, add Starship init
- [x] Configure fzf, zoxide integration
- [x] Remove corresponding stow package symlinks

### Notes
- Aliases kept as source file (complex with local variables)
- Functions copied to `files/zsh/functions/` and autoloaded via loop
- Used `initExtra` for shell options, keybindings, environment setup


## Phase 7 — System Files + Cleanup
Port remaining files and retire Ansible/Stow.

### Deliverables
| File              | Approach                     |
| ----------------- | ---------------------------- |
| `.XCompose`       | `home.file.".XCompose"`      |
| `.ctags`          | `home.file.".ctags"`         |
| `.hidden`         | `home.file.".hidden"`        |
| `.tigrc`          | `home.file.".tigrc"`         |
| `.gitcommit`      | `home.file.".gitcommit"`     |
| `julia/`          | `xdg.configFile."julia"`     |
| ~~`ipython/`~~    | Excluded — project-specific  |
| ~~`powershell/`~~ | Excluded — not used on NixOS |

- [x] Create `home/files.nix` for `home.file` entries
- [x] Wire up `.tigrc` (already in `files/tigrc`)
- [x] Copy remaining system files to `files/`
- [x] Keep `.dotfiles` as archive for reference


## Final .nixotic Structure
```
.nixotic/
├── flake.nix
├── flake.lock
├── docs/
│   ├── Migration.md
│   └── Workflow.md
├── files/
│   ├── git/
│   │   ├── gitcommit
│   │   ├── gitignore
│   │   └── tigrc
│   ├── julia/
│   │   ├── Solarized.jl
│   │   └── startup.jl
│   ├── kitty/
│   │   ├── kitty.conf
│   │   ├── Solarized_Dark.conf
│   │   └── Solarized_Light.conf
│   ├── nushell/
│   │   ├── aliases.nu
│   │   ├── config.nu
│   │   └── env.nu
│   ├── system/
│   │   ├── .ctags
│   │   ├── .hidden
│   │   └── .XCompose
│   └── zsh/
│       ├── completion.zsh
│       ├── zshrc
│       ├── zshalias
│       └── functions/      # 54 autoload functions
├── home/
│   ├── default.nix         # main home-manager entry
│   ├── atuin.nix
│   ├── bat.nix             # pure Nix (programs.bat.config)
│   ├── dircolors.nix       # pure Nix (extraConfig)
│   ├── direnv.nix
│   ├── eza.nix             # pure Nix
│   ├── fastfetch.nix
│   ├── fd.nix
│   ├── files.nix           # system dotfiles
│   ├── gh.nix
│   ├── git.nix             # pure Nix (programs.git.settings)
│   ├── helix.nix           # pure Nix
│   ├── htop.nix            # pure Nix
│   ├── jq.nix
│   ├── kitty.nix           # xdg.configFile for themes
│   ├── nh.nix
│   ├── nushell.nix
│   ├── ranger.nix          # pure Nix (settings + inline scope.sh)
│   ├── ripgrep.nix
│   ├── starship.nix        # pure Nix (programs.starship.settings)
│   ├── tmux.nix            # pure Nix (options + extraConfig)
│   ├── vscode.nix
│   └── zsh.nix             # builtins.readFile for complex configs
└── hosts/
    ├── demonstr8r/         # Development VM (active)
    │   ├── configuration.nix
    │   └── hardware-configuration.nix  # gitignored
    ├── ambul8r/             # Laptop (placeholder)
    │   └── configuration.nix
    └── infer8r/             # ML workstation (placeholder)
        └── configuration.nix
```


## Home Manager Module Reference
| Stow Package | Home Manager Module  | Notes                                    |
| ------------ | -------------------- | ---------------------------------------- |
| bat          | `programs.bat`       | Direct mapping                           |
| git          | `programs.git`       | + `home.file` for `.gitcommit`, `.tigrc` |
| starship     | `programs.starship`  | TOML → Nix attrset                       |
| kitty        | `programs.kitty`     | Large config, straightforward            |
| btop         | `programs.btop`      | Direct mapping                           |
| tmux         | `programs.tmux`      | TPM → Nix plugins                        |
| neovim       | `programs.neovim`    | vim-plug decision needed                 |
| zsh          | `programs.zsh`       | Most complex                             |
| dircolors    | `programs.dircolors` | Direct mapping                           |
| system files | `home.file.*`        | Raw file placement                       |

---

## Notes
- Keep `.dotfiles` and `.nixotic` parallel during migration
- Retire stow packages incrementally as Home Manager takes over
- Test each phase with `nixos-rebuild switch` before proceeding
- Powerline is fully replaced by Starship (prompt) + custom tmux status bar


## Phase 8 — Production Readiness
> Added: 10 January 2026

Prepare configuration for multi-host deployment.

### Deliverables
- [x] Rename host from `prototype`/`nix000` to `demonstr8r`
- [x] Create placeholder hosts (`ambul8r`, `infer8r`)
- [x] Refactor `flake.nix` with `mkHost` helper function
- [x] Remove tmux from `environment.systemPackages`
- [x] Remove duplicate VS Code from user packages
- [x] Update `.gitignore` (tags, *.code-workspace)
- [x] Delete empty `RELEASE.md`
- [x] Update README.md with host table
- [x] Update Migration.md

### Host Naming Convention
| Host         | Derivation  | Purpose        |
| ------------ | ----------- | -------------- |
| `demonstr8r` | demonstrate | Development VM |
| `ambul8r`    | ambulate    | Laptop         |
| `infer8r`    | infer       | ML workstation |

### Next Steps
- [x] Add CI/CD validation (`nix flake check`)
- [ ] Consider secrets management (sops-nix or agenix)
- [ ] Pin nixpkgs to stable for production hosts
- [ ] Complete Neovim migration (Phase 5)


## Phase 9 — Pure Nix Configuration
> Added: 16 January 2026

Migrate dotfiles from `files/` symlinks to pure Nix configuration using
Home Manager module options. This eliminates the hybrid approach and enables
conditional configuration, type checking, and better composition.

### Migration Tiers

**Tier 1: Easy Wins**
| Module        | Status | Notes                                |
| ------------- | ------ | ------------------------------------ |
| starship.nix  | ✅ Done | TOML → `programs.starship.settings`  |
| git.nix       | ✅ Done | Consolidated `files/git/config`      |
| bat.nix       | ✅ Done | Use `programs.bat.config`            |
| dircolors.nix | ✅ Done | Use `programs.dircolors.extraConfig` |
| eza.nix       | ✅ N/A  | Already pure Nix                     |

**Tier 2: Medium Effort**
| Module     | Status | Notes                                         |
| ---------- | ------ | --------------------------------------------- |
| tmux.nix   | ✅ Done | Moved `tmux.conf` into `extraConfig`          |
| ranger.nix | ✅ Done | `settings` + inline `scope.sh`                |
| atuin.nix  | ✅ N/A  | Already pure Nix                              |
| htop.nix   | ✅ N/A  | Already pure Nix                              |

**Tier 3: Complex (Selective)**
| Module     | Status | Notes                                         |
| ---------- | ------ | --------------------------------------------- |
| kitty.nix  | ⬜ Todo | Settings yes, theme files maybe keep          |
| zsh.nix    | ⬜ Skip | Keep `initContent` + `builtins.readFile`      |
| zshalias   | ⬜ Todo | Move to `programs.zsh.shellAliases`           |
| nushell.nix| ⬜ Skip | Complex config, keep as dotfiles              |

**Tier 4: Keep As Dotfiles**
| File                | Reason                                         |
| ------------------- | ---------------------------------------------- |
| 54 zsh functions    | Shell scripts with complex quoting/regex       |
| Julia configs       | Niche, no HM module, rarely changes            |
| tigrc               | No HM module, stable config                    |
| kitty themes        | Theme files work well as source files          |
| .XCompose, .ctags   | System files, no benefit to Nix-ifying         |

### Deleted Dotfiles
Files removed after successful migration:
- [x] `files/starship/starship.toml` — replaced by `programs.starship.settings`
- [x] `files/git/config` — replaced by `programs.git.settings`
- [x] `files/bat/config` — replaced by `programs.bat.config`
- [x] `files/dircolors/dir_colors` — replaced by `programs.dircolors.extraConfig`
- [x] `files/tmux/tmux.conf` — replaced by `programs.tmux` options + `extraConfig`
- [x] `files/ranger/rc.conf` — replaced by `programs.ranger.settings`
- [x] `files/ranger/scope.sh` — inlined into `xdg.configFile` with `text`

### Validation Workflow
See [Configuration Validation Workflow](Workflow.md#configuration-validation-workflow)
for the staged approach used during migrations.


## Future Considerations

### Secrets Management
When API keys, tokens, or other secrets are needed in the configuration:
- **sops-nix** — Encrypts secrets with age/GPG, decrypts at build time
- **agenix** — Similar approach, slightly simpler setup
- Evaluate when first secret is needed (e.g., Tailscale auth key, API tokens)

### nixos-anywhere + disko
For deploying to new machines (ambul8r, infer8r):
- **nixos-anywhere** — Deploy NixOS over SSH to any Linux machine
- **disko** — Declarative disk partitioning in Nix
- Add `disko` flake input when ready to provision new hardware

```nix
# Example flake.nix addition
inputs.disko = {
  url = "github:nix-community/disko";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

> ⚠️ **IMPORTANT:** Placeholder `hardware-configuration.nix` files exist for `ambul8r` and `infer8r`.
> These **MUST be replaced** when deploying to actual hardware:
> ```bash
> # On the target machine, generate real hardware config:
> nixos-generate-config --show-hardware-config > ~/.nixotic/hosts/<hostname>/hardware-configuration.nix
> ```
> The placeholders use generic disk labels (`/dev/disk/by-label/nixos`) that won't match real hardware.

### Regenerating Hardware Configuration
If you add hardware (disks, GPUs, etc.), regenerate the config **directly into your flake**:

```bash
# Generate directly into your flake (preferred)
sudo nixos-generate-config --dir ~/.nixotic/hosts/demonstr8r/

# Or generate to /etc/nixos and copy
sudo nixos-generate-config
cp /etc/nixos/hardware-configuration.nix ~/.nixotic/hosts/demonstr8r/
```

**Note:** `nixos-generate-config` defaults to `/etc/nixos/`, which is no longer used.
Always specify `--dir` or copy the file manually to keep your flake up to date.

After regenerating, review changes before committing:
```bash
git diff ~/.nixotic/hosts/demonstr8r/hardware-configuration.nix
```

### lib/ Directory
When configuration grows beyond 3 hosts or shared logic emerges:
- Extract `mkHost` helper to `lib/mkHost.nix`
- Add shared color definitions (`lib/colors.nix`) for Solarized theme
- Centralise custom options in `lib/options.nix`

### Host-Specific Modules
Future modules to consider per-host:
| Host         | Potential Modules                                       |
| ------------ | ------------------------------------------------------- |
| `demonstr8r` | VirtualBox guest additions, development tools           |
| `ambul8r`    | Power management, WiFi, Bluetooth, laptop lid           |
| `infer8r`    | NVIDIA drivers, CUDA, container runtime (podman/docker) |

### Cachix (Optional)
For faster CI builds and sharing binary caches:
- Create a Cachix cache for nixotic
- Push builds from CI to cache
- Pull cached builds on all hosts
