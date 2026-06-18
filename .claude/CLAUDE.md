# Nixotic Configuration Guidelines


## Context
This project manages desired state configuration for my computers using:
- **NixOS flake** with Home Manager as a module.
- **Hosts**: `ambul8r` (laptop, NVIDIA), `illumin8r` (WSL dev container host), `infer8r` (ML workstation, planned).
- **Desktop**: GNOME and only GNOME.
- **Shell**: ZSH with custom functions in `files/zsh/functions/`.
- **Theming**: Stylix manages desktop chrome only. CLI and editor theming use manual Solarized Light themes defined in `docs/colour-token-taxonomy.md`.


## On Startup
Familiarize yourself with the project structure and files.


## About Theming
If touching theming, read `docs/colour-token-taxonomy.md` first and treat it as the source of truth.


## How We Work Together
1. User asks for something.
2. Explain what you will do and how, and ask for clarification if needed.
3. User gives feedback or says to proceed.


## File Naming
- All files in `files/` must be visible in the repository (no leading dot), even if they are mapped to hidden paths in the build.
- The dotfile mapping is handled in `home/files.nix` or equivalent Nix configuration, not in the filename.


## Code Standards
- ZSH functions use PowerShell approved verbs.
- ZSH functions use PascalCase Verb-Noun naming (see `files/zsh/functions/CONVENTIONS.md`).
- Use `command -v` not `which` for command detection.
- No conditional guards for Home Manager tools (they're always present).
- ZSH completions use `home.packages` with a `pkgs.runCommand` derivation (see `home/zsh.nix`) — not `xdg.dataFile`, which is not on `$fpath`.
- Let Stylix manage GNOME and desktop chrome only.
- Do not rely on Stylix/Base16 for terminal and editor syntax theming.
- Keep syntax roles consistent across tools per `docs/colour-token-taxonomy.md`.


## Git Workflow
- Add, rename, move and delete files as needed.
- Do not stage or commit changes — the user does that after review.
- Do not run `git push` — the user always pushes by hand.
- Use git commands to rename, move and delete files under version control.


## Git Commit Messages
- Follow conventional commits.
- Use `files/git/gitcommit` as the source for type, scope/context, and subject format.
- Use subheadings if needed: `add:`, `deprecate:`, `retire:`, `modify:`, `defect:`, `style:`, `refactor:`
- Use lists; list each change.
- Descriptions must not exceed 100 characters.


## Build Commands
- `nh os build` — test build without switching.
- `nix flake check` — validate flake.
- Do not run build commands automatically — offer them and let the user decide. Builds can take a long time.
- Do not run `nh os switch`; only the user applies changes in a separate terminal.
- If Python is needed for a task, use `nix run nixpkgs#python3 -- <args>`.


## Style
- No emoticons.
- Be direct and concise.
- Ask one question at a time and wait for an answer before asking the next.
