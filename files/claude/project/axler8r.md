# Project Development Workflow

## Issue-Driven Planning

Specs and plans live in GitHub issues, not local files.

- Before starting work, search existing issues (`mcp__github__search_issues` / `gh issue list`). Do not create a duplicate.
- No matching issue → create a stub issue via `mcp__github__issue_write` capturing the problem statement and links to related issues/PRs. Acceptance criteria are settled during `superpowers:brainstorming`, then written back to the issue body.
- Matching issue → fetch it in full (`mcp__github__issue_read`: body, comments, linked issues/PRs) and use as the seed for `superpowers:brainstorming`.
- `superpowers:brainstorming` output is posted as an issue comment (`mcp__github__add_issue_comment`), not a local file.
- `superpowers:writing-plans` output is posted as an issue comment (`mcp__github__add_issue_comment`), not a local file.
- If posting to the issue fails, stop and surface the error to the user — do not save the design or plan to a local file as a fallback.
- Branch and worktree naming: `issue-<n>-<slug>` (via `superpowers:using-git-worktrees`).
- During execution: post a progress comment on the issue after each task completes.
- PR description includes `Closes #<n>`.
- Code review findings posted as PR review comments via `mcp__github__pull_request_review_write`.

## Workflow

1. `/axler8r:start` — search or create a GitHub issue; invoke `superpowers:brainstorming` with the issue as context; post the design as an issue comment.
2. `/axler8r:resume <n>` — return to an in-progress issue; reconstructs context and enters the worktree.
3. `superpowers:writing-plans` — post plan as an issue comment.
4. `superpowers:executing-plans` or `superpowers:subagent-driven-development` — post progress comments on the issue after each task.
5. `superpowers:requesting-code-review` — post findings as PR review comments.
6. `/axler8r:complete` — invoke `superpowers:finishing-a-development-branch`; user pushes by hand; create PR with `Closes #<n>`.

## Git Workflow

- One worktree per issue, named `issue-<n>-<slug>`.
- Completion is PR-based: never merge locally; the PR closes the issue via `Closes #<n>` and is merged by hand on GitHub.
- Do not push — the user always pushes by hand.

## Git Commit Messages

- Subject: `<type>(#<n>): <verb> <message>` — issue number in context where applicable; max 100 characters. This overrides the global `<type>[(<context>)]` format.
- Body: always present, separated from subject by one blank line.
- Use the `writing-git-commits` skill for subheadings and body format.
