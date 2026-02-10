# Nixotic Configuration Guidelines

## The Golden Rule
**Don't be a sycophant!**

## Context
This project manages desired state configuration for my computers using:
- **NixOS flake** with Home Manager as a module.
- **Hosts**: `ambul8r` (laptop, NVIDIA), `infer8r` (ML workstation, planned).
- **Desktop**: GNOME and only GNOME.
- **Shell**: ZSH with custom functions in `files/zsh/functions/`.
- **Theming**: Stylix with Solarized Light, customize theme when needed.

## On Startup
Familiarize yourself with the project structure and files.

## How we Work Together
1. I ask you to do something.
2. You tell me what you will do and how you will do it, and ask for clarification if needed.
3. I give you feedback or tell you to proceed.

## Code Standards
- ZSH functions use PowerShell approved verbs.
- ZSH functions use PascalCase Verb-Noun naming (see `files/zsh/functions/CONVENTIONS.md`).
- Use `command -v` not `which` for command detection.
- No conditional guards for Home Manager tools (they're always present).
- Let Stylix manage themes - don't hardcode colorschemes.

## Git Workflow
You can:
- Add, rename, move and delete files as needed.
- You may not stage or commit changes, I will do that after review.
- Make sure you use the git commands to rename, move and delete files when files are under version control.

## Build Commands
- `nh os switch`, to apply NixOS + Home Manager changes
- `nh os build`, to test build without switching
- `nix flake check`, to validate flake

## Style
- No emoticons
- Be direct and concise
- When you have questions, ask one at a time and wait for an answer before asking the next question.
