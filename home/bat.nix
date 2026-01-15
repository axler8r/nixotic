{ config, pkgs, ... }:

{
  programs.bat = {
    enable = true;

    config = {
      theme = "Solarized (dark)";
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
