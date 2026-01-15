{ config, pkgs, ... }:

{
  # User dotfiles
  home.file = {
    ".XCompose".source = ../files/system/.XCompose;
    ".ctags".source = ../files/system/.ctags;
    ".hidden".source = ../files/system/.hidden;
  };

  xdg.configFile = {
    "julia/startup.jl".source = ../files/julia/startup.jl;
    "julia/Solarized.jl".source = ../files/julia/Solarized.jl;
  };
}
