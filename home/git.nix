{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    lfs.enable = true;

    settings = {
      user = {
        name = "AxlER8R";
        email = "axler8r@pm.me";
        signingKey = "62125521358F40CD";
      };

      branch.autosetuprebase = "never";

      commit = {
        gpgSign = false;  # Set to true if you want to sign all commits
        template = "${config.home.homeDirectory}/.gitcommit";
      };

      tag.gpgSign = true;  # Sign tags with GPG key

      core = {
        editor = "nvim";
        eol = "lf";
        excludesfile = "${config.home.homeDirectory}/.gitignore";
        hooksPath = "${config.home.homeDirectory}/.githooks";
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

  home.file.".githooks/pre-commit" = {
    source = ../files/git/hooks/pre-commit;
    executable = true;
  };
}
