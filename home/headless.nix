{ lib, ... }:

{
  imports = [
    ./base.nix
    ./eza.nix
    ./fd.nix
    ./gh.nix
    ./jq.nix
    ./ripgrep.nix
  ];

  home.sessionVariables = {
    EDITOR = "hx";
  };

  programs.git.settings = {
    core.editor = lib.mkForce "hx";
    merge.tool = lib.mkForce "hx";
  };
}
