---
description: Begin work on a GitHub issue — search or create, brainstorm, then post the design.
argument-hint: [description of the work]
---

Begin a new piece of work using the GitHub-MCP workflow.

1. Use "$ARGUMENTS" as the description of the work. If it is empty, ask: "What do you want to work on?" — wait for a one-sentence description.
2. Search existing issues with `mcp__github__search_issues` using keywords from the description.
3. Present any matches and ask the user to confirm a match or create a new issue.
4. If creating: use `mcp__github__issue_write` to create a stub issue with the problem statement and links to related issues/PRs. Do not invent acceptance criteria yet — they are settled during brainstorming. Record the issue number `n`.
5. If using existing: use `mcp__github__issue_read` to fetch the full issue — body, all comments, linked issues/PRs. Record the issue number `n`.
6. Invoke `superpowers:brainstorming` with the full issue content as context.
7. Post the resulting design as an issue comment via `mcp__github__add_issue_comment`, and update the issue body with the agreed acceptance criteria via `mcp__github__issue_write`. Do not leave a local design document.
8. Derive a slug from the issue title: lowercase, replace spaces and punctuation with hyphens, truncate to 40 characters.
9. Create a worktree named `issue-<n>-<slug>` using `superpowers:using-git-worktrees`.
