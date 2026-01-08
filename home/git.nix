{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    lfs.enable = true;

    # Include main config file
    includes = [
      { path = "~/.config/git/config_extra"; }
    ];

    # Git settings (new format)
    settings = {
      # User information (kept inline as these are personal and may need to be overridden)
      user = {
        name = "AxlER8R";
        email = "axl@axler8r.io";
        signingKey = "1B5C4A4F10A770E3";
      };

      commit.gpgSign = false;  # Set to true if you want to sign all commits

      # Credential helpers (kept inline as they need Nix package references)
      credential = {
        "https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
        "https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      };
    };
  };

  # Use original config files to preserve formatting
  xdg.configFile."git/config_extra".source = ../files/git/config;
  home.file.".gitignore".source = ../files/git/gitignore;
  home.file.".gitcommit".source = ../files/git/gitcommit;
  home.file.".tigrc".source = ../files/git/tigrc;
}
