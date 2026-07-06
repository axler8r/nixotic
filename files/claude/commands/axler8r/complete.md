---
description: Complete work on the current issue — verify, push by hand, then create the PR.
---

Complete and ship the current issue.

1. Identify the issue number `n` from the current branch name (`issue-<n>-<slug>`).
2. Invoke `superpowers:finishing-a-development-branch`. This workflow is PR-based: choose the pull-request path; never merge locally.
3. Ensure all work is committed, then ask the user to push the branch by hand (`git push -u origin issue-<n>-<slug>`). Wait for confirmation that the push succeeded before continuing — the PR cannot be created until the branch exists on the remote.
4. Create a PR via `mcp__github__create_pull_request` with `Closes #<n>` in the body.
5. Post a final progress comment via `mcp__github__add_issue_comment` noting the PR number and that it is ready for review.
6. Remind the user: merging is done by hand on GitHub.
