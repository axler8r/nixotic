# Repository formatter for `nix fmt`: nixfmt for Nix, nph for Nim, prettier
# then markdownlint-cli2 --fix for Markdown. Unfixable Markdown findings do not
# fail formatting; the markdown-lint check reports them.
{ pkgs }:
pkgs.treefmt.withConfig {
  name = "nixotic-fmt";

  runtimeInputs = [
    pkgs.nixfmt
    pkgs.nph
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

      nph = {
        command = "nph";
        includes = [
          "*.nim"
          "*.nims"
          "*.nimble"
        ];
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
