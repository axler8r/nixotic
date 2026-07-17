# Global Development Preferences

# Preferences

Prefer Development Container development over local development.

## Development Container Environment

- Dev Container-installed extensions over local-installed extensions.
- `Dockerfile`-based dev container.
- `Dockerfile` contains: runtime(s), ZSH, `make`, project tools, and user/group with uid/gid 1000 named `vscode`.
- Organise `Dockerfile` to minimise build time.
- Do not manage dependencies in `Dockerfile`.
- `git flow` for feature-based development.
- `git` + WIP branch for trunk-based development.
- Follow conventional commit specification for commit messages.

## Local Environment

In the absence of a Development Container project environment consider:

This host is NixOS — a lean, declarative system where tools are not necessarily installed globally.

- When `which`, `command -v` fails:
  - Use `nix run nixpkgs#<tool> -- <args>` to run a tool ephemerally (just-in-time, no install), or,
  - use `nix shell nixpkgs#<tool>` to enter a shell with a tool available for a session.
- Never use `pip`, `apt`, `brew`, `npm -g`, or any other package manager to install tools on the host.
- Project-specific tools (dotnet, make, etc.) are declared in the project's `flake.nix` devShell and activated via `direnv`.

## Workflow

- Repo-local `.scratchpad/` is shared, gitignored scratch space for AI tools
  working in a repo (Claude Code, Codex, GitHub Copilot). Each tool uses its
  own subtree: `.scratchpad/<provider>/{plans,specs,<task-tracker>}`.
- Claude's subtree is `.scratchpad/claude/`:
  - `plans/` — implementation plans
  - `specs/` — design specs
  - `sdd/` — spec-driven-development reports: task briefs, review diffs, progress notes
- Name new plans `<yyyymmddHHMM>-<slug>-plan.md` and new specs
  `<yyyymmddHHMM>-<slug>-spec.md` (4-digit year, lowercase hyphenated slug).
  Leave existing files under their current names.
- Create plan. Use `superpowers:writing-plans`.
- Generate/update code.
  - Use `superpowers:executing-plans` or `superpowers:subagent-driven-development` for implementation.
  - Use `superpowers:dispatching-parallel-agents` for parallel generation.
  - Keep diffs minimal, coherent, and easy to review.
  - Prefer editing existing files over introducing new files unless a new file materially improves structure.
- Stop and surface concrete blockers rather than guessing when requirements or constraints conflict.
- Implement/update tests. Only use mock tests if there is no alternative.
- Create/update documentation.
- Review changes. Use `superpowers:requesting-code-review`.
- Commit.
  - See `${HOME}/.gitcommit` for commit message format.
  - Never sync.
  - Never merge.

## Verification

Before concluding work:

- Ensure acceptance criteria are satisfied.
- Ensure validation commands pass, or explain precisely why they do not.
- Call out residual risk, deferred work, and follow-up recommendations explicitly.

## Git Commit Messages

- Use `files/git/gitcommit` as the source for commit types and context format.
- Subject: `<type>[(<context>)]: <verb> <message>` — max 100 characters; lowercase throughout except identifiers and proper nouns.
- Body: always present, separated from subject by one blank line.
- For subheadings and nested-bullet body format, use the `writing-git-commits` skill.
