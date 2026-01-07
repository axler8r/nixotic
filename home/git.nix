{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    userName = "AxlER8R";
    userEmail = "axl@axler8r.io";

    signing = {
      key = "1B5C4A4F10A770E3";
      signByDefault = false; # Set to true if you want to sign all commits
    };

    lfs.enable = true;

    extraConfig = {
      branch.autosetuprebase = "never";
      commit.template = "~/.gitcommit";
      core = {
        editor = "nvim";
        eol = "lf";
        pager = "bat";
      };
      gc.autoDetach = false;
      init.defaultBranch = "stable";
      merge = {
        tool = "nvim";
        guitool = "meld";
      };
      mergetool.nvim.cmd = "nvim -d $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";
      pull.rebase = false;
      push.default = "simple";
      credential = {
        "https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
        "https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      };
    };

    ignores = [
      # Archives
      "*.7z"
      "*.bz2"
      "*.gz"
      "*.tar"
      "*.zip"
      # Editors
      ".idea/"
      ".vscode/"
      "*.swp"
      "*.swo"
      # OS
      ".DS_Store"
      "Thumbs.db"
      # Build
      "*.o"
      "*.pyc"
      "__pycache__/"
      "node_modules/"
    ];
  };

  # Git commit template
  home.file.".gitcommit".text = ''
    <type>['('(<id>|<context>)')']: <message>

    # [body]

    # [footer]

    # ----------- INSTRUCTIONS -------------------------------------- >8 -
    #             See https://www.conventionalcommits.org for details.
    #             Choose <type> from options below.
    #             Add an <id> or <context> for reference where relevant.
    #             Supply a <message> in <verb> <detail> format.
    #             When in doubt, use 'wip'.
    # ----------- MAJOR --------------------------------------------------
    # feat!       refactor, retire…
    # ----------- MINOR --------------------------------------------------
    # feat        add, deprecate, update…
    # ----------- PATCH --------------------------------------------------
    # build       add, update, remove…
    # cicd        add, update, remove…
    # defect      fix, revert…
    # dep         add, update, remove…
    # perf        increase, optimise, remove…
    # sec         mitigate, prevent, block, patch…
    # ----------- NONE ---------------------------------------------------
    # doc         add, update, refactor, remove…
    # meta        add, update, remove…
    # refactor    move, rename, combine, separate…
    # style       apply, format, edit…
    # test        add, update, remove…
    # ----------- IGNORE -------------------------------------------------
    # chore       …
    # merge       …
    # wip         …
    # ----------- END INSTRUCTIONS ---------------------------------- >8 -

  '';

  # Tig configuration
  home.file.".tigrc".source = ../files/git/tigrc;
}
