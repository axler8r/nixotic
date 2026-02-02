# Git Workflow

This repository follows **Trunk-Based Development** designed for a single-user
NixOS configuration. The `stable` branch is the single source of truth.

## The Cycle

### 1. Start from Stable

```bash
git checkout stable
git pull origin stable
```

### 2. Create a Feature Branch

Use descriptive names for parallel experiments:

```bash
git checkout -b feat/nvim-config
git checkout -b fix/audio-crackling
git checkout -b refactor/zsh-aliases
```

### 3. Develop & Test

Make changes, then apply:

```bash
nh os switch
```

> **Tip:** If the build fails or breaks the system, rollback to the previous
> generation at boot time.

See [validation.md](validation.md) for the full validation workflow.

### 4. Curate History

Before merging, clean up commits:

```bash
git rebase --interactive stable
```

- Squash "wip" commits
- Reword messages for clarity
- Follow [Conventional Commits](https://www.conventionalcommits.org/)

### 5. Merge

Fast-forward merge to stable:

```bash
git checkout stable
git merge feat/my-change --ff-only
```

### 6. Cleanup

```bash
git branch -d feat/my-change
```

## Guidelines

| Practice | Reason |
|----------|--------|
| Separate `flake.lock` updates | Makes regressions easier to identify |
| Use NixOS generations for rollback | Runtime safety net |
| Use Git for configuration history | Track what changed and why |
| Prefix branches with type | `feat/`, `fix/`, `refactor/`, `docs/` |
