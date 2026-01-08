{ config, pkgs, ... }:

{
  programs.nushell = {
    enable = true;

    # Configuration file
    configFile.source = ../files/nushell/config.nu;

    # Environment file
    envFile.source = ../files/nushell/env.nu;

    # Shell aliases
    shellAliases = {
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      
      # Improved commands
      "df" = "df -h";
      "ll" = "ls -l";
      "la" = "ls -a";
      "lla" = "ls -la";
      
      # Git shortcuts
      "g" = "git";
      "gs" = "git status";
      "ga" = "git add";
      "gc" = "git commit";
      "gp" = "git push";
      "gl" = "git pull";
      
      # Common tools
      "vim" = "nvim";
      "vi" = "nvim";
    };
  };

  # Copy additional Nushell files
  xdg.configFile = {
    "nushell/aliases.nu".source = ../files/nushell/aliases.nu;
    "nushell/scripts" = {
      source = ../files/nushell/scripts;
      recursive = true;
    };
  };
}
