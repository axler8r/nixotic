{ config, pkgs, ... }:

{
  programs.helix = {
    enable = true;

    settings = {
      theme = "solarized_dark";

      editor = {
        line-number = "relative";
        cursorline = true;
        auto-save = true;
        rulers = [70 80 110];

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker.hidden = false;

        lsp.display-messages = true;
      };

      keys.normal = {
        space.w = ":write";
        space.q = ":quit";
      };
    };

    languages = {
      language = [
        { name = "nix"; auto-format = true; }
        { name = "python"; auto-format = true; }
        { name = "rust"; auto-format = true; }
      ];
    };
  };
}
