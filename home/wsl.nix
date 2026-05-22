{ pkgs, lib, ... }:

{
  imports = [
    ./base.nix
  ];

  home.packages = with pkgs; [
    github-copilot-cli
  ];

  home.sessionVariables = {
    EDITOR = "hx";
  };

  programs.git.settings = {
    core.editor = lib.mkForce "hx";
    merge.tool = lib.mkForce "hx";
  };
}
