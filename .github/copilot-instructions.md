# Nixotic Configuration Guidelines

## Project Structure
- **NixOS flake** with Home Manager as a module (not standalone)
- **Hosts**: `ambul8r` (laptop, NVIDIA), `infer8r` (ML workstation), `demonstr8r`
- **Theming**: Stylix with Solarized Light - avoid hardcoding colors/themes
- **Shell**: ZSH with custom functions in `files/zsh/functions/`

## Before Making Changes
1. Ask which host if system-specific changes are needed
2. Confirm the approach before editing
3. Check current file contents - don't assume

## Code Standards
- ZSH functions use PascalCase Verb-Noun naming (see `files/zsh/functions/CONVENTIONS.md`)
- Use `command -v` not `which` for command detection
- No conditional guards for Home Manager tools (they're always present)
- Let Stylix manage themes - don't hardcode colorschemes

## Git Workflow
- Work on WIP branches, never commit directly to `stable`
- Stage changes with `git add` but **never** run `git commit` or `git push`
- Tags are GPG-signed (Ed25519 key)

## Build Commands
- `nh os switch` - apply NixOS + Home Manager changes
- `nh os build` - test build without switching
- `nix flake check` - validate flake

## Style
- No emoticons
- Be direct and concise
- One question at a time when clarification needed
