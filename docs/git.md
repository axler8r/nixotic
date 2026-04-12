# Git Workflow
This repository uses a simple **WIP-first trunk workflow** for a single-user
NixOS configuration. The `stable` branch is the source of truth, and all active
work happens on `wip/*` branches created from `stable`.


## The Cycle

### 1. Update Stable
```bash
Update-GitStableBranch
```

This command refuses dirty worktrees and fast-forwards `stable` from
`origin/stable`.

### 2. Create a WIP Branch
```bash
New-GitWIPBranch
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

> [!TIP] Tip
>  If the build fails or breaks the system, rollback to the previous
> generation at boot time.

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
after checking repo state.

### 5. Complete the WIP Branch
```bash
Complete-GitWIPBranch
```

This switches to `stable` and runs `git merge --ff-only <current-wip-branch>`.
If `stable` cannot be fast-forwarded, it refuses to merge.

### 6. Cleanup
```bash
Remove-GitWIPBranch <wip-branch>
```

Cleanup stays explicit. The branch name is required, and only merged `wip/*`
branches can be deleted.

## Guidelines
| Practice | Reason |
|----------|--------|
| Keep all active work on `wip/*` branches | Enforces the intended `stable -> wip/* -> stable` flow |
| Let `New-GitWIPBranch` create branch names | Keeps branch creation consistent |
| Keep history curation explicit | Avoids hidden rebases during completion |
| Keep cleanup explicit | Avoids hidden deletion of the wrong branch |
| Separate `flake.lock` updates | Makes regressions easier to identify |
| Use NixOS generations for rollback | Runtime safety net |
| Use Git for configuration history | Track what changed and why |
