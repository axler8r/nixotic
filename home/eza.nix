{ config, pkgs, ... }:

{
  programs.eza = {
    enable = true;
    enableZshIntegration = false;  # We define our own aliases
    git = true;
    icons = "auto";
    colors = "always";
    extraOptions = [
      "--classify"
      "--color-scale"
      "--color-scale-mode=fixed"
      "--group"
      "--group-directories-first"
      "--header"
      "--ignore-glob=tags*"
      "--sort=extension"
      "--time-style=long-iso"
    ];
  };

  home.sessionVariables = {
    EZA_COLORS = "ur=32:uw=33:ux=31:ue=31:gr=32:gw=33:gx=31:tr=32:tw=33:tx=31:sn=32:sb=33:xx=34";
  };

  programs.zsh.shellAliases = {
    ls = "eza";
    l = "eza --git-ignore --oneline";
    ll = "eza --all --long";
    llm = "eza --all --long --sort=modified";
    la = "eza --all --long --accessed --binary --blocksize --created --inode --links --modified";
    lt = "eza --tree";
    lx = "eza --all --long --accessed --binary --blocksize --created --inode --links --modified --extended";
  };
}
