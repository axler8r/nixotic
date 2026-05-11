# Global Development Preferences


## Preferences
- Dev Container-based development over local development.
- Dev Container-installed extensions over local-installed extensions.
- `Dockerfile`-based dev container.
- `Dockerfile` contains: runtime(s), ZSH, `make`, project tools, and user/group with uid/gid 1000 named `vscode`.
- Organise `Dockerfile` to minimise build time.
- Do not manage dependencies in `Dockerfile`.
- `git flow` for feature-based development.
- `git` + WIP branch for trunk-based development.
- Follow conventional commit specification for commit messages.


## Workflow
- Branch.
- Create plan. Use `superpowers:writing-plans`.
- Generate/update code.
  - Use `superpowers:executing-plans` or `superpowers:subagent-driven-development` for implementation.
  - Use `superpowers:dispatching-parallel-agents` for parallel generation.
  - Keep diffs minimal, coherent, and easy to review.
  - Prefer editing existing files over introducing new files unless a new file materially improves structure.
- Stop and surface concrete blockers rather than guessing when requirements or constraints conflict.
- Implement/update tests. Only use mock tests if there is no alternative.
- Create/update documentation.
- Review changes. Use `superpowers:requesting-code-review`.
- Commit.
  - See `${HOME}/.gitcommit` for commit message format.
  - Never sync.
  - Never merge.


## Verification
Before concluding work:
- Ensure acceptance criteria are satisfied.
- Ensure validation commands pass, or explain precisely why they do not.
- Call out residual risk, deferred work, and follow-up recommendations explicitly.
