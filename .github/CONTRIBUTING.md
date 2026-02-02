# Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test: `nh os build` or `nix flake check`
5. Commit with conventional commits: `feat:`, `fix:`, `docs:`, etc.
6. Push and open a pull request

## Guidelines

- Keep the base system minimal
- Use `shell.nix` for project-specific tools
- Follow existing code style
- Update documentation if needed
