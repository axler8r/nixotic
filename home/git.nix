{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    lfs.enable = true;

    settings = {
      user = {
        name = "AxlER8R";
        email = "axl@axler8r.io";
        signingKey = "1B5C4A4F10A770E3";
      };

      branch.autosetuprebase = "never";

      commit = {
        gpgSign = false;  # Set to true if you want to sign all commits
        template = "~/.gitcommit";
      };

      core = {
        editor = "nvim";
        eol = "lf";
        excludesfile = "~/.gitignore";
        pager = "bat";
      };

      gc.autoDetach = false;

      "gitflow \"branch\"" = {
        master = "stable";
        develop = "development";
      };

      "gitflow \"prefix\"".versiontag = "v";

      init.defaultBranch = "stable";

      merge = {
        tool = "nvim";
        guitool = "meld";
      };

      "mergetool \"nvim\"".cmd = "nvim -d $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";

      pull.rebase = false;

      push.default = "simple";
    };
  };

  home.file.".gitignore".source = ../files/git/gitignore;
  home.file.".gitcommit".source = ../files/git/gitcommit;
  home.file.".tigrc".source = ../files/git/tigrc;
}
