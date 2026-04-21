---
description: Apply Python Dev Container rules for this session.
---

Apply the following rules for all Python Dev Container work in this session.

## Tooling
- Use `uv` for virtual environments and dependency management.
- Use `ruff` for linting and formatting where appropriate.
- Install the Python runtime and globally required developer tooling in the image.

## Dependency management
- Do not install project dependencies into the Dockerfile.
- Do not run `uv sync` in the Dockerfile unless explicitly asked to create a prebuilt dependency image.
- Assume `pyproject.toml` and `uv.lock` are the source of truth for project dependencies.
- Assume the project virtual environment is created during normal development workflow, not during image build.

## Dockerfile guidance
- Structure layers to maximise cache reuse for Python runtime and global tool installation.
- Prefer official or well-supported installation approaches for Python and `uv`.
- Keep the image focused on developer environment concerns, not application packaging.

## Commands and examples
- Prefer `uv sync`, `uv run`, `uv tool install`, `ruff check`, and `ruff format` in generated documentation, scripts, and validation guidance.
- Do not introduce `pip`, `pip-tools`, `poetry`, or `pipenv` unless the repository already requires them or the task explicitly asks for them.
