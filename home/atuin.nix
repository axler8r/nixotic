{ config, pkgs, ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = false;  # Set to true if you want cloud sync
      search_mode = "fuzzy";
      style = "compact";
      show_preview = true;
      inline_height = 20;
    };
  };
}
