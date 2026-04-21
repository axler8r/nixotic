{ config, pkgs, ... }:

{
  home.file = {
    ".claude/CLAUDE.md".source = ../files/claude/CLAUDE.md;
    ".claude/commands/New-Plan.md".source = ../files/claude/commands/New-Plan.md;
    ".claude/commands/Invoke-Implementation.md".source = ../files/claude/commands/Invoke-Implementation.md;
    ".claude/commands/Invoke-Review.md".source = ../files/claude/commands/Invoke-Review.md;
    ".claude/commands/Invoke-Parallel.md".source = ../files/claude/commands/Invoke-Parallel.md;
    ".claude/commands/Set-DevContainer.md".source = ../files/claude/commands/Set-DevContainer.md;
    ".claude/commands/Set-DotnetDevContainer.md".source = ../files/claude/commands/Set-DotnetDevContainer.md;
    ".claude/commands/Set-PythonDevContainer.md".source = ../files/claude/commands/Set-PythonDevContainer.md;
  };
}
