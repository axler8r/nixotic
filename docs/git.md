# Git Workflow

This repository uses a **WIP-first trunk workflow**: all active work happens on
short-lived `wip/*` branches that fast-forward into `stable`.

A feature-branch or git-flow model would add overhead with no benefit here —
there is no team review gate, and keeping history linear on `stable` makes it
easy to bisect regressions. WIP branches are ephemeral; `stable` is the only
durable ref.

The `stable` branch is the source of truth.

## The Cycle

### 1. Update Stable

```bash
ax git stable sync
```

This command refuses dirty worktrees and fast-forwards `stable` from
`origin/stable`.

### 2. Create a WIP Branch

```bash
ax git wip start
```

This creates and switches to `wip/YYYYMMDD-<random7>` from a clean `stable`
branch.

### 3. Develop & Validate

Make changes, then validate them with the existing Nix workflow:

```bash
nix flake check --no-build
nh os build --dry
nh os switch
```

> [!TIP] Recovery
>
> If the build fails or breaks the system, rollback to the previous generation
> at boot time.

See [validation.md](validation.md) for the full validation workflow.

### 4. Curate History

Before landing work on `stable`, clean up the WIP history:

```bash
Update-GitWIPBranchHistory
```

- Squash "wip" commits
- Reword messages for clarity
- Follow [Conventional Commits](https://www.conventionalcommits.org/)

This runs `git rebase --interactive stable` from the current `wip/*` branch
after checking repo state. Curation is a separate explicit step — mixing it into
the completion command would make rebases invisible and harder to review.

### 5. Complete the WIP Branch

```bash
ax git wip finish
```

This switches to `stable` and runs `git merge --ff-only <current-wip-branch>`.
Fast-forward only is intentional: it requires the WIP branch to be rebased on
top of `stable` before merging, which keeps `stable`'s history linear and
bisectable. If `stable` cannot be fast-forwarded, the command refuses.

### 6. Cleanup

```bash
ax git wip drop <wip-branch>
```

Cleanup stays explicit. The branch name is required, and only merged `wip/*`
branches can be deleted.

## Hooks

`core.hooksPath` points at `~/.githooks`, populated by Home Manager from
`files/git/hooks/`. The `pre-commit` hook formats staged `.md` files with
`prettier` then `markdownlint-cli2 --fix` and re-stages them; tools not on
`$PATH` are run via `nix run nixpkgs#<tool>`. Hooks take effect after
`nh os switch`; until then the `ax-format-markdown` skill runs the same chain by
hand.

## Guidelines

| Practice                                   | Reason                                                 |
| ------------------------------------------ | ------------------------------------------------------ |
| Keep all active work on `wip/*` branches   | Enforces the intended `stable -> wip/* -> stable` flow |
| Let `ax git wip start` create branch names | Keeps branch creation consistent                       |
| Keep history curation explicit             | Avoids hidden rebases during completion                |
| Keep cleanup explicit                      | Avoids hidden deletion of the wrong branch             |
| Separate `flake.lock` updates              | Makes regressions easier to identify                   |
| Use NixOS generations for rollback         | Runtime safety net                                     |
| Use Git for configuration history          | Track what changed and why                             |
