# Tooling Tiers

Whether a tool is installed at all, and how it reaches the PATH when it is not.
[packages.md](packages.md) decides _where_ an installed package is declared;
this document decides _whether_ it is installed.

Years of Ubuntu LTS rebuilds never produced the same environment twice: tools
were forgotten, workflows drifted, and time went into fiddling. Nix makes the
machine reproducible, but that only pays off if what is declared is what is
actually used. The goal is a declared environment that is a deliberate, honest
picture of how the work gets done — not minimalism for its own sake, and not a
reproducible pile of things nobody opens.

This describes the target. Current declarations predate the tiers; the first
[workflow review](#workflow-review) drives the convergence.

## The Workflow Spine

The daily workflow decides what is installed:

1. Open kitty; `tmux` new or attach.
2. `git clone`; `git branch` or `git worktree`.
3. Work in Claude Code, Codex, GitHub Copilot CLI, or VS Code with a Dev
   Container.
4. `make format && make lint && make check && make build`.
5. Troubleshoot with the right tools when needed.
6. `git commit`; merge.

Email goes through Proton Mail and the web through Brave. Once a week the hosts
are updated: flake update, format, lint, check, build, fix, `nh os switch`.

## Tiers

### 1. Installed

Tools a daily workflow step touches. They are declared in `home/*.nix` or
`profiles/roles/*.nix`, as [packages.md](packages.md) describes.

- Terminal: kitty, zsh, tmux
- Version control and build: git, make
- Editors: Helix, NeoVim, VS Code
- Agents: Claude Code, Codex, GitHub Copilot CLI
- Containers: Docker
- Desktop: a trimmed GNOME, Brave, Proton Mail
- The [rescue kit](#rescue-kit)

Anything else installed has to justify itself against the spine.

### 2. Project-Owned

Formatters, linters, language servers, and toolchains that one repository's
`make` targets or editor need. They come from that repository, locked by its
lockfile, and leave when you leave it:

- the flake's `formatter` and `checks` outputs, reached through `make`;
- the flake's devShell, activated by direnv;
- or the repository's Dev Container.

Keep the devShell to what the shell and the editor need. Editor tooling such as
`nimlangserver` and `nph` belongs there, because Helix only finds it on the
PATH direnv provides. Formatters and linters that `make` runs belong in flake
outputs, not the devShell.

### 3. Just in Time

Troubleshooting and occasional tools — `strace`, `socat`, `ffmpeg`, `typst`,
`tokei`, `orpie`, and the like — are fetched when needed and cost nothing while
idle:

```bash
nix run nixpkgs#<tool> -- <args>   # one command
nix shell nixpkgs#<tool>           # a shell session with the tool
```

Inside a flake repository, follow its lock instead of the system's nixpkgs:

```bash
nix run --inputs-from . nixpkgs#<tool> -- <args>
```

## Rescue Kit

Troubleshooting sometimes happens when the network or Nix itself is broken, and
Tier 3 fails exactly then. A small kit stays installed for that case: `htop`,
`lsof`, `curl`, `file`.

Keep it small. An addition needs a "needed when offline or when Nix is broken"
reason.

## Servers

Servers follow the same tiers with a smaller spine and no GUI: zsh, tmux, git,
make, Helix, plus the rescue kit.

## Promotion and Demotion

Usage, not memory, moves tools between tiers. The thresholds are starting
points, to be tuned by experience:

| Signal                                              | Suggestion       |
| --------------------------------------------------- | ---------------- |
| Fetched just in time on 4+ distinct days in 90 days | Promote to 1     |
| Installed, not run in 90 days                       | Demote to 3      |
| GUI app not launched in 90 days                     | Remove           |
| The spine and the rescue kit                        | Exempt from both |

Axl decides every promotion, demotion, and removal. Agents only suggest.

## Agent Behaviour

Agents follow the tiers by default. The deployed summaries live in
`files/claude/CLAUDE.md` and `files/codex/AGENTS.md`; they are self-contained
because this repository is not present on every host. In short:

- A missing tool is fetched just in time. Agents never install tools with
  `pip`, `apt`, `brew`, `npm -g`, `nix profile install`, or any other package
  manager on the host. A missing project tool goes through the project's `make`
  target or devShell first.
- Project tools go in the project's flake or Dev Container, not on the host.
- Agents never add a tool to `home.packages` or `environment.systemPackages`
  unless asked; they propose it with the tier reasoning instead.
- An agent that fetches the same tool 3 or more times in one session says so
  once, at the end of the task, as a promotion candidate. Beyond that, tooling or
  workflow-habit suggestions come from the [workflow review](#workflow-review),
  not unprompted. Task follow-ups and residual risk are still reported.

## Workflow Review

Not yet implemented. This is the contract the review is built against.

- **Entry point:** `make review-workflow`, run as part of the weekly update.
- **Data:** atuin shell history over a 90-day window, compared with the declared
  packages.
- **Output:** promote, demote, and remove suggestions per
  [the thresholds](#promotion-and-demotion), showing only what changed since the
  last review; one line when nothing did.
- **Workflow candidates:** repeated manual multi-step sequences, such as
  committing the lock file and then amending its message every week.

The window and the cadence are separate on purpose: a week of history is too
thin to judge a monthly tool, but a weekly run surfaces a new signal within a
week instead of waiting for a monthly slot.

## Source of Truth

This document is the source of truth for tooling tiers. The agent summaries
follow it; when they disagree, update the summaries.
