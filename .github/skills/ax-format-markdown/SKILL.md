---
name: ax-format-markdown
description: >
  Format staged or specified markdown files before a git commit using prettier
  and markdownlint-cli2. Use when the user asks to format markdown, clean up
  markdown, or before committing changes that touch .md files.
---

# ax-format-markdown

Formats markdown files with `prettier` then `markdownlint-cli2 --fix`, matching
the same tool chain the repository's native `pre-commit` Git hook runs (see
[files/git/hooks/pre-commit](../../../files/git/hooks/pre-commit)).

## When to Use

- Before committing changes that touch `.md` files.
- When asked to format or clean up markdown content.
- As a manual re-run if the native `pre-commit` hook is not yet deployed
  (`~/.githooks` only exists after `nh os switch`).

## Procedure

1. Determine target files:
   - If files are staged, use `git diff --cached --name-only --diff-filter=ACM -- '*.md'`.
   - Otherwise use the specific file paths the user named.
2. Run the shared hook script directly against those files, or invoke each
   tool per [Host Tooling](../../copilot-instructions.md):
   - `nix run nixpkgs#prettier -- --write --parser=markdown --prose-wrap=preserve --print-width=80 <files>`
   - `nix run nixpkgs#markdownlint-cli2 -- --fix <files>`
3. If the files were staged, re-run `git add -- <files>` so the commit
   includes the formatted content.
4. Report which files were reformatted; if none needed changes, say so.

## Notes

- Do not duplicate formatting logic here — this skill is a thin wrapper
  around [files/git/hooks/pre-commit](../../../files/git/hooks/pre-commit) so
  there is one source of truth for the tool chain and flags.
- Follow [docs/colour-token-taxonomy.md](../../../docs/colour-token-taxonomy.md)
  guidance if formatting touches any theming-related markdown.
