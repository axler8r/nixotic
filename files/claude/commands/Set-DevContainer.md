---
description: Apply Dev Container implementation rules for this session.
---

Apply the following rules for all Dev Container work in this session.

## General
- Prefer a Dockerfile-based Dev Container over local development.
- Prefer a Dockerfile-based Dev Container over docker-compose unless the task explicitly requires multi-service local orchestration.
- Create images for development, not production.
- Keep diffs minimal, coherent, and easy to review.
- Prefer editing existing files over introducing new files unless a new file materially improves structure.
- Stop and surface concrete blockers rather than guessing when requirements or constraints conflict.

## Dockerfile contents
- Install runtimes, ZSH, `make`, git, and project-level OS packages in the image.
- Create and use a non-root user named `vscode` with uid `1000` and gid `1000`.
- Do not manage application dependencies in the Dockerfile unless explicitly asked to build a warmed dependency image.
- Do not copy the full repository into the image unless necessary for the requested workflow.

## Build and caching
- Organise the Dockerfile to optimise build time and cache reuse.
- Put stable OS and package-manager setup early in the Dockerfile.
- Put less stable tooling installs later.
- Prefer deterministic installs with pinned versions where practical.
- Avoid unnecessary stages, abstraction, or indirection.

## Dev Container structure
- Prefer `.devcontainer/devcontainer.json` plus `.devcontainer/Dockerfile`.
- Prefer Dev Container-installed VS Code extensions over local-installed extensions.
- Only introduce docker-compose when the development workflow genuinely requires additional services.
- Include only comments that explain non-obvious caching, versioning, or user-setup decisions.

## Verification
Before concluding work:
- Ensure acceptance criteria are satisfied.
- Ensure validation commands pass, or explain precisely why they do not.
- Call out residual risk, deferred work, and follow-up recommendations explicitly.
