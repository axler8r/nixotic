{ config, pkgs, ... }:

{
  programs.bat = {
    enable = true;

    config = {
      # Note: map-syntax uses different format in Home Manager
    };

    # Syntax mappings
    syntaxes = { };
  };

  # bat config file for map-syntax entries (Home Manager's syntaxes option is for custom .sublime-syntax files)
  xdg.configFile."bat/config".text = ''
    --theme="Solarized (dark)"
    --map-syntax ".ignore:Git Ignore"
    --map-syntax "*.code-workspace:JSON"
    --map-syntax ".XCompose:Bourne Again Shell (bash)"
    --map-syntax ".livebook:Markdown"
    --map-syntax ".taskrc:Bourne Again Shell (bash)"
    --map-syntax ".tigrc:Bourne Again Shell (bash)"
    --map-syntax ".tmux.conf:Bourne Again Shell (bash)"
    --map-syntax ".xonshrc:Python"
    --map-syntax ".zsh*:Bourne Again Shell (bash)"
  '';
}
