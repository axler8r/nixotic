{ config, pkgs, ... }:

{
  programs.bat = {
    enable = true;

    config = {
      # Theme managed by Stylix (base16-stylix)
      map-syntax = [
        ".ignore:Git Ignore"
        "*.code-workspace:JSON"
        ".XCompose:Bourne Again Shell (bash)"
        ".livebook:Markdown"
        ".taskrc:Bourne Again Shell (bash)"
        ".tigrc:Bourne Again Shell (bash)"
        ".tmux.conf:Bourne Again Shell (bash)"
        ".xonshrc:Python"
        ".zsh*:Bourne Again Shell (bash)"
      ];
    };
  };
}
