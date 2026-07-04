# Project Development Workflow

## Issue-Driven Planning

Specs and plans live in GitHub issues, not local files.

- Before starting work, search existing issues (`mcp__github__search_issues` / `gh issue list`). Do not create a duplicate.
- No matching issue → create one via `mcp__github__issue_write` before running `superpowers:brainstorming`. Capture: problem statement, acceptance criteria, links to related issues/PRs.
- Matching issue → fetch it in full (`mcp__github__issue_read`: body, comments, linked issues/PRs) and use as the seed for `superpowers:brainstorming`.
- `superpowers:writing-plans` output is posted as an issue comment (`mcp__github__add_issue_comment`), not a local file.
- Branch and worktree naming: `issue-<n>-<slug>` (via `superpowers:using-git-worktrees`).
- During execution: post a progress comment on the issue after each task completes.
- PR description includes `Closes #<n>`.
- Code review findings posted as PR review comments via `mcp__github__pull_request_review_write`.

## Workflow

1. `/start` — search or create a GitHub issue; invoke `superpowers:brainstorming` with the issue as context.
2. `/resume <n>` — return to an in-progress issue; reconstructs context and enters the worktree.
3. `superpowers:writing-plans` — post plan as an issue comment.
4. `superpowers:executing-plans` or `superpowers:subagent-driven-development` — post progress comments on the issue after each task.
5. `superpowers:requesting-code-review` — post findings as PR review comments.
6. `/finish` — invoke `superpowers:finishing-a-development-branch`; create PR with `Closes #<n>`.

## Git Workflow

- One worktree per issue, named `issue-<n>-<slug>`.
- WIP branch squash-merged to stable at completion.
- Do not push — the user always pushes by hand.

## Git Commit Messages

- Subject: `<type>(#<n>): <verb> <message>` — issue number in context where applicable; max 100 characters.
- Body: always present, separated from subject by one blank line.
- Subheadings: `add:` `modify:` `retire:` `deprecate:` `defect:` `style:` `refactor:` — blank line between subheadings.
- List items: `  - lowercase description` — no trailing period; use `—` (em dash U+2014) for context.
