# Nixotic Configuration Guidelines


## The Golden Rule
**Don't be a sycophant!**


## Context
This project manages desired state configuration for my computers using:
- **NixOS flake** with Home Manager as a module.
- **Hosts**: two roles — workstation (GNOME) and server (CLI only). `ambul8r` (workstation: laptop, NVIDIA), `illumin8r` (server: WSL dev container host), `cre8r` (server: provisioning helper VM).
- **Desktop**: GNOME and only GNOME.
- **Shell**: ZSH with custom functions in `files/zsh/functions/`.
- **Theming**: Stylix manages desktop chrome only. CLI and editor theming use manual Solarized Light themes defined in `docs/colour-token-taxonomy.md`.


## On Startup
Familiarize yourself with the project structure and files.


## About Theming
If you are touching theming, read `docs/colour-token-taxonomy.md` first and treat it as the source of truth.


## How we Work Together
1. I ask you to do something.
2. You tell me what you will do and how you will do it, and ask for clarification if needed.
3. I give you feedback or tell you to proceed.


## Code Standards
- ZSH functions use PowerShell approved verbs.
- ZSH functions use PascalCase Verb-Noun naming (see `files/zsh/functions/CONVENTIONS.md`).
- Use `command -v` not `which` for command detection.
- No conditional guards for Home Manager tools (they're always present).
- Let Stylix manage GNOME and desktop chrome only.
- Do not rely on Stylix/Base16 for terminal and editor syntax theming.
- Keep syntax roles consistent across tools per `docs/colour-token-taxonomy.md`.


## Git Workflow
You can:
- Add, rename, move and delete files as needed.
- You may not stage or commit changes, I will do that after review.
- Make sure you use the git commands to rename, move and delete files when files are under version control.


## Git Commit Messages
- Commit messages follow conventional commits.
- Use `files/git/gitcommit` as the source for type, scope/context, and subject format.
- Create messages with the following subheadings if needed:
  - `add:`, `deprecate:`, `retire:`, `modify:`, `defect:`, `style:`, `refactor:`
- Use lists
- List each change
- Description of changes should not exceed 100 characters


 ## Build Commands
 - `nh os build`, to test build without switching
 - `nix flake check`, to validate flake
 - Do not run `nh os switch`; only the user applies changes in a separate terminal.


## Style
- No emoticons
- Be direct and concise
- When you have questions, ask one at a time and wait for an answer before asking the next question.
