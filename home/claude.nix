{ config, pkgs, ... }:

{
  home.file = {
    ".claude/CLAUDE.md".source = ../files/claude/CLAUDE.md;
    ".claude/commands/using-dev-container.md".source = ../files/claude/commands/using-dev-container.md;
    ".claude/commands/using-dotnet-dev-container.md".source = ../files/claude/commands/using-dotnet-dev-container.md;
    ".claude/commands/using-python-dev-container.md".source = ../files/claude/commands/using-python-dev-container.md;
    ".claude/templates/project/CLAUDE.md".source = ../files/claude/project/CLAUDE.md;
  };

  home.sessionVariables = {
    CLAUDE_COMMANDS_GIST = "";  # Set to your gist ID after publishing slash commands
  };
}
