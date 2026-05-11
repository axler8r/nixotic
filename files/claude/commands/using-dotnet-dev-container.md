---
description: Apply .NET Dev Container rules for this session.
---

Apply the following rules for all .NET Dev Container work in this session.

## Tooling
- Install the .NET SDK in the Docker image.
- Use NuGet for project dependency management.
- If `global.json` exists, match the requested SDK version.
- Prefer official Microsoft package sources or base images for .NET installation.

## Dependency management
- Do not restore project packages in the Dockerfile unless explicitly asked to build a warmed dependency image.
- Do not copy the full repository into the image solely to perform package restore.
- Keep project restore and build steps in normal developer or CI workflows unless the task explicitly requires otherwise.

## Dockerfile guidance
- Keep SDK installation high in the Dockerfile to maximise cache reuse.
- Prefer clear, minimal SDK images.
- Avoid mixing unrelated runtimes unless the repository explicitly requires them.
- Keep the image focused on developer environment concerns rather than application publish concerns.

## Commands and examples
- Prefer `dotnet restore`, `dotnet build`, `dotnet test`, and standard NuGet-based workflows in documentation and validation guidance.
- Do not introduce alternative dependency managers unless the repository already requires them or the task explicitly asks for them.
