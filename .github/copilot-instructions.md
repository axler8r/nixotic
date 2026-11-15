# Nixotic Configuration Guidelines

## Context

This project manages desired state configuration for my computers using:

- **NixOS flake** with Home Manager as a module.
- **Host Roles**: workstation (GNOME) and server (CLI only). Role is declared
  once, in `flake.nix` via `mkHost { role }`. `hosts/<name>/` is flat (one
  directory per machine); shared modules live in `profiles/` split by concern:
  `roles/`, `hardware/`, `platform/`, `storage/`.
- **Desktop**: GNOME and only GNOME.
- **CLI**: primary command surface is Nim via `ax` (`ax/`); ZSH
  functions in `files/zsh/functions/` are legacy/compatibility only
  (repo-relative — edited here; `~/.zsh/functions/` is the generated copy).
- **Theming**: Stylix manages desktop chrome only. CLI and editor theming use
  manual Solarized Light themes defined in `docs/colour-token-taxonomy.md`.

## On Startup

Familiarize yourself with the project structure and read only the docs relevant
to the task before editing:

- `docs/nim-functions-conventions.md` for Nim command naming and verb rules.
- `docs/ax-cli-design.md` for `ax` CLI design and command structure.
- `docs/colour-token-taxonomy.md` for theming and syntax-role boundaries.
- `docs/git.md` for workflow and commit expectations.
- `docs/validation.md` for verification expectations.
- `docs/packages.md` for package and tooling conventions.

## About Theming

If you are touching theming, read `docs/colour-token-taxonomy.md` first and
treat it as the source of truth.

## File Naming

- All files in `files/` must be visible in the repository (no leading dot), even
  if they are mapped to hidden paths in the build.
- The dotfile mapping is handled in `home/files.nix` or equivalent Nix
  configuration, not in the filename.

## Workflow

1. For non-trivial tasks, state a brief plan before starting.
2. Proceed autonomously through implementation, validation, and documentation
   updates per the policies above.
3. Ask a clarifying question only when a genuine ambiguity or blocker prevents
   safe progress — one question at a time, per Style.
4. Report back concisely: what changed, where, and any residual risk or
   follow-up.

## Scratchpad

Repo-local `.scratchpad/copilot` is shared, gitignored scratch space:

- `.scratchpad/copilot/plans/<yyyymmddHHMM>-<slug>-plan.md` for implementation
  plans.
- `.scratchpad/copilot/specs/<yyyymmddHHMM>-<slug>-spec.md` for design specs.
- `.scratchpad/copilot/tasks/` for task checklists and review notes.

## Code Standards

- New CLI commands and features are implemented in Nim under `ax/`
  (`commands/`, `lib/`) first; see `docs/nim-functions-conventions.md` and
  `docs/ax-cli-design.md` as the source of truth for naming and structure.
- `files/zsh/functions/` is in maintenance mode: limit changes to wrappers,
  migration shims, or explicit requests. Do not add new business logic there.
- ZSH functions (where still used) use PowerShell approved verbs and
  PascalCase Verb-Noun naming (see `docs/zsh-functions-conventions.md`).
- Use `command -v` not `which` for command detection.
- No conditional guards for Home Manager tools (they're always present).
- ZSH completions use `home.packages` with a `pkgs.runCommand` derivation (see
  `home/zsh.nix`) - not `xdg.dataFile`, which is not on `$fpath`.
- Let Stylix manage GNOME and desktop chrome only.
- Do not rely on Stylix/Base16 for terminal and editor syntax theming.
- Keep syntax roles consistent across tools per `docs/colour-token-taxonomy.md`.

## Host Tooling

In the absence of a Development Container project environment: the host is
NixOS, and tools are not necessarily installed globally. Tools sit in one of
three tiers:

1. **Installed** - the daily workflow spine (kitty, zsh, tmux, git, make, Helix,
   NeoVim, Claude Code, Codex, GitHub Copilot CLI, VS Code, Docker, Brave,
   Proton Mail, GNOME) plus a rescue kit (`htop`, `lsof`, `curl`, `file`).
   Servers: zsh, tmux, git, make, Helix, rescue kit.
2. **Project-owned** - formatters, linters, language servers, toolchains: the
   project's flake (`formatter`, `checks`, devShell via `direnv`) or its Dev
   Container. The devShell carries what the shell and editor need; `make`-run
   tools belong in flake outputs.
3. **Just in time** - everything else, when `command -v` fails (a missing
   project tool goes through the project's `make` target or devShell first):
   - `nix run nixpkgs#<tool> -- <args>` for one command, or
     `nix shell nixpkgs#<tool>` for a session;
   - inside a flake repo, add `--inputs-from .` to either command to follow its
     lock.

- Never use `pip`, `apt`, `brew`, `npm -g`, `nix profile install`, or any other
  package manager to install tools on the host.
- Never add a tool to `home.packages` or `environment.systemPackages` unless
  asked; propose it with the tier reasoning instead. The user decides every
  promotion, demotion, and removal.
- If you fetch the same tool just in time 3 or more times in one session, say
  so once at the end of the task as a promotion candidate. Make no other
  unprompted tooling or workflow-habit suggestions; task follow-ups and residual
  risk are still reported.
- Source of truth: `docs/tooling-tiers.md`.

## Autonomy and Safety

- Default to autonomy-first execution: carry tasks through implementation and
  verification when possible.
- When autonomy is explicitly agreed, proactively run validation/build/test
  commands as needed to complete the task.
- Preserve safety boundaries: do not run destructive git operations unless
  explicitly requested.
- Do not use privilege-escalation workarounds or silent destructive actions.

## Git Workflow

You can:

- Add, rename, move and delete files as needed.
- Stage and commit changes in coherent units of work.
- Commit history must clearly demarcate the journey of the codebase.
- Make sure you use the git commands to rename, move and delete files when files
  are under version control.

## Git Commit Messages

- Commit messages follow conventional commits.
- Use `${HOME}/.gitcommit` as the source for type, scope/context, and subject
  format.
- Create messages with the following subheadings if needed:
  - `add:`, `deprecate:`, `retire:`, `modify:`, `defect:`, `style:`, `refactor:`
- Use lists
- List each change
- Description of changes should not exceed 100 characters

## Build Commands

- `nix flake check`, to validate flake
- `nh os build`, to test build without switching
- When autonomy is explicitly agreed, these validation/build commands may be run
  proactively.
- Do not run `nh os switch`; only the user applies changes in a separate
  terminal.

## Nim Migration Policy

- Prefer extending `ax` in Nim over adding new ZSH functions.
- When touching existing ZSH behavior, consider moving the logic into Nim and
  leaving a thin ZSH wrapper if shell integration is still required.
- New command groups/verbs should map through `ax/commands/groups.json`
  and the existing command tree conventions.
- Maintain ZSH backward compatibility only when explicitly required.

## Documentation Maintenance

- After edits, update affected documentation in the same change whenever
  behavior, conventions, commands, or workflows are modified.
- Update `docs/ax-cli-design.md` and `docs/nim-functions-conventions.md` when
  Nim command semantics, naming, or UX changes.
- Keep documentation aligned with implementation so future agents inherit
  accurate context.

## Style

- No emoticons
- Be direct and concise
- When you have questions, ask one at a time and wait for an answer before
  asking the next question.
