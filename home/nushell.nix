{ config, pkgs, ... }:

{
  programs.nushell = {
    enable = true;

    # Load home.sessionVariables when nu starts without them (e.g. not from
    # zsh); a no-op otherwise. Sourced before env.nu, which still wins.
    loadSessionVariables = true;

    configFile.source = ../files/nushell/config.nu;

    envFile.source = ../files/nushell/env.nu;

    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";

      "df" = "df -h";
      "ll" = "ls -l";
      "la" = "ls -a";
      "lla" = "ls -la";

      "g" = "git";
      "gs" = "git status";
      "ga" = "git add";
      "gc" = "git commit";
      "gp" = "git push";
      "gl" = "git pull";

      "vim" = "nvim";
      "vi" = "nvim";
    };
  };

  xdg.configFile."nushell/aliases.nu".source = ../files/nushell/aliases.nu;
}
