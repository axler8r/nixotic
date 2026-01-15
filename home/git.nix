{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    lfs.enable = true;

    includes = [
      { path = "~/.config/git/config_extra"; }
    ];

    settings = {
      user = {
        name = "AxlER8R";
        email = "axl@axler8r.io";
        signingKey = "1B5C4A4F10A770E3";
      };

      commit.gpgSign = false;  # Set to true if you want to sign all commits
    };
  };

  home.file.".gitignore".source = ../files/git/gitignore;
  home.file.".gitcommit".source = ../files/git/gitcommit;
  home.file.".tigrc".source = ../files/git/tigrc;
  xdg.configFile."git/config_extra".source = ../files/git/config;
}
