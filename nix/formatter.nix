# Repository formatter for `nix fmt`: nixfmt for Nix, prettier then
# markdownlint-cli2 --fix for Markdown. Unfixable Markdown findings do not
# fail formatting; the markdown-lint check reports them.
{ pkgs }:
pkgs.treefmt.withConfig {
  name = "nixotic-fmt";

  runtimeInputs = [
    pkgs.nixfmt
    pkgs.prettier
    pkgs.markdownlint-cli2
  ];

  settings = {
    on-unmatched = "debug";

    formatter = {
      nixfmt = {
        command = "nixfmt";
        includes = [ "*.nix" ];
      };

      prettier = {
        command = "prettier";
        options = [ "--write" ];
        includes = [ "*.md" ];
        priority = 1;
      };

      markdownlint = {
        command = pkgs.writeShellScript "markdownlint-fix" ''
          markdownlint-cli2 --fix "$@" || true
        '';
        includes = [ "*.md" ];
        priority = 2;
      };
    };
  };
}
