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
    EZA_COLORS = "ur=38;5;64:uw=38;5;160:ux=38;5;64:ue=38;5;160:gr=38;5;64:gw=38;5;160:gx=38;5;64:tr=38;5;64:tw=38;5;160:tx=38;5;64:sn=38;5;37:sb=38;5;136:xx=38;5;33";
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
