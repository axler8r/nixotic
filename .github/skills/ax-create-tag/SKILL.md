---
name: ax-create-tag
description: >
  Create an annotated, signed git tag on a chosen commit. Lists the 10 most
  recent commits to pick from, suggests a semantic version tag from the most
  recent tag, and supports a pre-release form. Use when asked to tag a commit,
  create a release tag, or create a pre-release tag.
---

# ax-create-tag

Interactively tags a commit, following this repository's Conventional
Commits and tagging conventions (see [docs/git.md](../../../docs/git.md) and
[files/git/gitcommit](../../../files/git/gitcommit)).

## When to Use

- The user asks to tag a commit, cut a release, or create a pre-release tag.

## Procedure

1. **List recent commits.** Run:

   ```bash
   git log -10 --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%ad  %h  %s'
   ```

   Show the output as a numbered list (timestamp, short hash, commit message
   heading) and ask the user which commit to tag. Accept either the list
   number or the commit hash.

2. **Determine the tag name.**
   - If the user supplies a tag name explicitly, use it as-is.
   - If the user says the tag should be a **semantic version tag** and does
     not supply a name:
     1. Find the most recent tag with `git tag --sort=-v:refname | head -1`.
     2. Ask the user which segment to bump — major, minor, or patch —
        unless they already said which in the same request.
     3. Propose `v<MAJOR>.<MINOR>.<PATCH>` bumped accordingly and confirm
        with the user before creating it.
   - If the user says the tag is a **pre-release tag**, append `+` and the
     tagged commit's timestamp as `yyyymmddHHMMSS` to the semantic version
     computed above, e.g. `v2.4.0+20260910153045`. Use the commit's own
     timestamp, not the current time, so re-running this later reproduces
     the same tag:

     ```bash
     date -d @$(git show -s --format=%at <commit-hash>) '+%Y%m%d%H%M%S'
     ```

3. **Confirm before tagging.** Show the resolved commit and final tag name
   and get explicit confirmation before creating anything.

4. **Create the tag.** Use a signed, annotated tag so the commit message
   heading is preserved as the tag message, matching the flags
   `ax git tag create` uses:

   ```bash
   git tag -s -a <tag-name> <commit-hash> -m "<commit message heading>"
   ```

5. **Report the result.** Show the created tag name, the commit it points
   to, and remind the user that pushing tags is a manual step (this repo
   never pushes automatically; see [Git Workflow](../../copilot-instructions.md)).

## Notes

- Do not push the tag. Tag creation only; the user pushes by hand.
- Do not confuse this skill with `ax git tag create`
  ([files/nim/commands/git/tag/create.nim](../../../files/nim/commands/git/tag/create.nim)),
  which auto-derives a tag from HEAD's Conventional Commit type. This skill
  is for interactive, user-directed tagging of an arbitrary recent commit.
