{ config, pkgs, ... }:

{
  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;

    extraConfig = ''
      COLOR                 tty

      # One TERM entry for each colorizable termtype
      TERM                  alacritty
      TERM                  ansi
      TERM                  gnome
      TERM                  gnome-256color
      TERM                  putty
      TERM                  putty-256color
      TERM                  rxvt
      TERM                  rxvt-256color
      TERM                  screen
      TERM                  screen-256color
      TERM                  screen-256color-italic
      TERM                  tmux
      TERM                  tmux-256color
      TERM                  xterm
      TERM                  xterm-256color
      TERM                  xterm-256color-italic
      TERM                  xterm-kitty

      EIGHTBIT              1

      NORMAL                00
      FILE                  00
      DIR                   01;34
      LINK                  01;36
      FIFO                  00;48;5;125;38;5;230
      SOCK                  00;48;5;37;38;5;230
      ORPHAN                01;48;5;160;38;5;230
      MISSING               01;48;5;136;38;5;230
      EXEC                  01;38;5;160
      .app                  01;38;5;160

      # Text
      .asciidoc             00;38;5;245
      .md                   01;38;5;245
      .tex                  00;38;5;245
      .txt                  00;38;5;245

      # Source
      *Dockerfile           01;38;5;64
      .cs                   01;38;5;64
      .csproj               00;38;5;64
      .erl                  00;38;5;64
      .ex                   01;38;5;64
      .exs                  00;38;5;64
      .java                 01;38;5;64
      .jl                   01;38;5;64
      .js                   01;38;5;64
      .kt                   00;38;5;64
      .lua                  00;38;5;64
      .nim                  00;38;5;64
      .py                   01;38;5;64
      .rs                   01;38;5;64
      .scala                00;38;5;64
      .sql                  00;38;5;64
      .swift                00;38;5;64

      # Shell
      .bash                 00;38;5;166
      .csh                  00;38;5;166
      .fish                 00;38;5;166
      .nu                   00;38;5;166
      .ps1                  00;38;5;166
      .sh                   01;38;5;166
      .zsh                  01;38;5;166

      # Configuration
      .cfg                  01;38;5;37
      .conf                 00;38;5;37
      .config               01;38;5;37
      .env                  01;38;5;37
      .env.example          00;38;5;37
      .ini                  00;38;5;37
      .json                 01;38;5;37
      .jsonc                00;38;5;37
      .toml                 01;38;5;37
      .xml                  00;38;5;37
      .yaml                 01;38;5;37
      .yml                  00;38;5;37

      # Notebook & Livebook
      .ipynb                01;38;5;136
      .jlnb                 00;38;5;136
      .livemd               01;38;5;136

      # Media
      .av1                  00;38;5;33
      .h264                 00;38;5;33
      .jpeg                 01;38;5;33
      .jpg                  00;38;5;33
      .mp3                  00;38;5;33
      .mp4                  01;38;5;33
      .png                  01;38;5;33
      .svg                  01;38;5;33
      .tiff                 00;38;5;33
      .vid                  00;38;5;33

      # Document
      .doc                  01;38;5;125
      .docx                 00;38;5;125
      .pdf                  01;38;5;125
      .ppt                  01;38;5;125
      .pptx                 00;38;5;125
      .ps                   00;38;5;125
      .xls                  01;38;5;125
      .xlsx                 00;38;5;125

      # Archive
      .7z                   01;38;5;61
      .Z                    00;38;5;61
      .ZST                  01;38;5;61
      .bz                   00;38;5;61
      .bz2                  01;38;5;61
      .dmg                  00;38;5;61
      .gz                   01;38;5;61
      .iso                  00;38;5;61
      .pkg                  00;38;5;61
      .rar                  00;38;5;61
      .tar                  00;38;5;61
      .tbz                  00;38;5;61
      .tbz2                 00;38;5;61
      .tgz                  00;38;5;61
      .xz                   00;38;5;61
      .z                    00;38;5;61
      .zip                  01;38;5;61
      .zstd                 00;38;5;61

      # Miscellanea
      *~                    00;38;5;245
      .log                  00;38;5;245

      # Meta
      .BAK                  00;38;5;245
      .DIST                 00;38;5;245
      .OLD                  00;38;5;245
      .ORIG                 00;38;5;245
      .bak                  00;38;5;245
      .dist                 00;38;5;245
      .old                  00;38;5;245
      .orig                 00;38;5;245
      .swo                  00;38;5;245
      .swp                  00;38;5;245
    '';
  };
}
