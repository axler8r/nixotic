{ config, pkgs, ... }:

{
  home.file = {
    ".claude/CLAUDE.md".source = ../files/claude/CLAUDE.md;
    ".claude/skills/writing-git-commits/SKILL.md".source = ../files/claude/skills/writing-git-commits/SKILL.md;
    ".claude/commands/using-dev-container.md".source = ../files/claude/commands/using-dev-container.md;
    ".claude/commands/using-dotnet-dev-container.md".source = ../files/claude/commands/using-dotnet-dev-container.md;
    ".claude/commands/using-python-dev-container.md".source = ../files/claude/commands/using-python-dev-container.md;
    ".claude/commands/axler8r/start.md".source = ../files/claude/commands/axler8r/start.md;
    ".claude/commands/axler8r/resume.md".source = ../files/claude/commands/axler8r/resume.md;
    ".claude/commands/axler8r/complete.md".source = ../files/claude/commands/axler8r/complete.md;
    ".claude/templates/project/axler8r.md".source = ../files/claude/project/axler8r.md;
  };
}
