{ config, pkgs, ... }:

{
  # System dotfiles
  home.file = {
    # Custom compose key sequences
    ".XCompose".source = ../files/system/.XCompose;

    # Universal Ctags configuration
    ".ctags".source = ../files/system/.ctags;

    # Hidden files in home directory (for Nautilus)
    ".hidden".source = ../files/system/.hidden;
  };

  # XDG config files
  xdg.configFile = {
    # Julia startup configuration
    "julia/startup.jl".source = ../files/julia/startup.jl;
    "julia/Solarized.jl".source = ../files/julia/Solarized.jl;
  };
}
