{ pkgs, lib, ... }:

{
  imports = [
    ./base.nix
    ./claude.nix
    ./eza.nix
    ./fd.nix
    ./gh.nix
    ./jq.nix
    ./ripgrep.nix
  ];

  home.packages = with pkgs; [
    claude-code
    curl
    docker-sbx # `sbx`: Docker sandboxes for agents
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
