---
description: Resume work on a GitHub issue — reconstruct context and enter the worktree.
argument-hint: [issue number]
---

Resume work on issue #$ARGUMENTS.

1. If no issue number was given, list open issues with `mcp__github__list_issues` and ask which one to resume.
2. Fetch the full issue via `mcp__github__issue_read` — body, all comments, linked PRs.
3. Summarise: goal, what has been completed, what remains.
4. Derive the slug from the issue title (lowercase, hyphens, truncated to 40 characters).
5. Enter or create the worktree `issue-<n>-<slug>` using `superpowers:using-git-worktrees`.
6. Show current git status in the worktree and any uncommitted changes.
