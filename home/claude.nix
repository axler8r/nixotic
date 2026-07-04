{ config, pkgs, ... }:

{
  home.file = {
    ".claude/CLAUDE.md".source = ../files/claude/CLAUDE.md;
    ".claude/commands/using-dev-container.md".source = ../files/claude/commands/using-dev-container.md;
    ".claude/commands/using-dotnet-dev-container.md".source = ../files/claude/commands/using-dotnet-dev-container.md;
    ".claude/commands/using-python-dev-container.md".source = ../files/claude/commands/using-python-dev-container.md;
    ".claude/templates/project/axler8r.md".source = ../files/claude/project/axler8r.md;
  };

  home.sessionVariables = {
    CLAUDE_COMMANDS_GIST = "9b268e8f233fe5b9c8b0d982f5aee29c";  # axler8r/claude-project-commands gist
  };
}
