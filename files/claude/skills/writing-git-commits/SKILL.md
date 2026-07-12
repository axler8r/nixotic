---
name: writing-git-commits
description: Use when writing a git commit message body, choosing subheadings, or deciding how much to nest a list item.
---

# Writing Git Commits

## Overview

A commit body is a nested bullet list, not a flat list of one-liners.
Subheadings group changes by kind; under each subheading, one bullet per
subject; a subject's facts and rationale nest underneath it. This replaces
packing a fact and an em-dash rationale onto one line, which stops scaling
once a subject has more than one fact to report.

For subject-line format and type selection (`<type>[(<context>)]: <message>`,
the MAJOR/MINOR/PATCH/NONE/IGNORE table), see `files/git/gitcommit` — this
skill covers the body only.

## Subheadings

One or more subheadings per commit, blank line between subheadings.

| Subheading | Use for |
|---|---|
| `add:` | new behaviour, capabilities, or files introduced |
| `modify:` | changes to existing behaviour |
| `retire:` | behaviour or files removed |
| `deprecate:` | marked for future removal |
| `defect:` | bug fixes |
| `style:` | formatting, naming, cosmetic changes |
| `refactor:` | restructuring without behaviour change |

## Nesting Rule

- **One fact per bullet.** A subject with only one fact stays on one line:
  `- foo removed`.
- **A subject with more than one fact gets its own bullet**, with each fact
  nested underneath it — never one line per fact crammed onto the subject.
- **Rationale is a nested `why:` bullet**, never an em-dash suffix sharing a
  line with the fact it explains.
- **Depth flexes with content.** Don't add a nesting level with nothing under
  it, and don't collapse a multi-fact subject back onto one line to avoid
  nesting.
- Indent 2 spaces per level. Lowercase, no trailing period, except
  identifiers and proper nouns.

## Example

Before — fact and rationale packed onto one line, unreadable once a subject
has more than one fact:
```
modify:
  - mkHost imports disko.nixosModules.disko
  — nixos-anywhere reads config.disko.devices from the flake
  - networking.hostId reframed as a permanent random value
  — ZFS needs stability, not machine-id derivation
```

After — subject and fact separated, rationale nested under its fact:
```
modify:
  - mkHost
    - imports disko.nixosModules.disko
    - why: nixos-anywhere reads config.disko.devices from the flake
  - networking.hostId reframed as a permanent random value
    - why: ZFS needs stability, not machine-id derivation
```

A single-fact item with no rationale needed stays flat — don't nest it for
consistency:
```
retire:
  - New-Vault --filesystem option
```

A bug fix's "what was broken" is usually restating the fact, not a separate
reason — don't manufacture a `why:` out of it. State the fix as the fact and
stop:
```
defect:
  - Mount-Vault errors cleanly instead of looping when --size is passed without a value
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Fact and rationale on one line with an em dash | Move the rationale to a nested `why:` bullet |
| One line per fact when the facts share a subject | Make the subject its own bullet, nest the facts under it |
| Nesting a single-fact item for visual consistency | Leave it flat — nesting exists for facts, not decoration |
| A `why:` bullet that restates the fact instead of the reason | State the fact once, then the reason it was needed |
| A `defect:` bullet gets a `why:` describing the old broken behaviour | The old behaviour is what the fact already fixes, not a separate reason — leave the bullet flat |
