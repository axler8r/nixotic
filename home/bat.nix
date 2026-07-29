{ config, pkgs, ... }:

{
  programs.bat = {
    enable = true;

    themes = {
      NixoticSolarizedLight.src = ../files/bat/NixoticSolarizedLight.tmTheme;
    };

    config = {
      theme = "NixoticSolarizedLight";
      map-syntax = [
        ".ignore:Git Ignore"
        "**/*.code-workspace:JSON"
        ".XCompose:Bourne Again Shell (bash)"
        "**/*.livemd:Markdown"
        ".taskrc:Bourne Again Shell (bash)"
        ".tigrc:Bourne Again Shell (bash)"
        ".tmux.conf:Bourne Again Shell (bash)"
        "**/.zsh*:Bourne Again Shell (bash)"
      ];
    };
  };
}
