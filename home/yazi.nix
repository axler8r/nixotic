{ config, pkgs, ... }:

let
  solarized = {
    lightBackground         = "#fdf6e3";
    lightBackgroundContrast = "#eee8d5";
    lightestAccent          = "#93a1a1";
    lightAccent             = "#839496";
    darkAccent              = "#657b83";
    darkestAccent           = "#586e75";
    darkBackgroundContrast  = "#073642";
    darkBackground          = "#002b36";

    red     = "#dc322f";
    orange  = "#cb4b16";
    yellow  = "#b58900";
    green   = "#859900";
    cyan    = "#2aa198";
    blue    = "#268bd2";
    violet  = "#6c71c4";
    magenta = "#d33682";
  };
in
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";

    theme = {
      manager = {
        cwd             = { fg = solarized.blue; };
        hovered         = { fg = solarized.darkBackground; bg = solarized.lightBackgroundContrast; bold = true; };
        preview_hovered = { underline = true; };

        find_keyword  = { fg = solarized.yellow; italic = true; };
        find_position = { fg = solarized.magenta; bold = true; italic = true; };

        marker_copied   = { fg = solarized.green;   bg = solarized.green;   };
        marker_cut      = { fg = solarized.red;     bg = solarized.red;     };
        marker_marked   = { fg = solarized.violet;  bg = solarized.violet;  };
        marker_selected = { fg = solarized.yellow;  bg = solarized.yellow;  };

        tab_active   = { fg = solarized.darkBackground; bg = solarized.lightBackgroundContrast; bold = true; };
        tab_inactive = { fg = solarized.lightAccent; };

        count_copied   = { fg = solarized.lightBackground; bg = solarized.green;  };
        count_cut      = { fg = solarized.lightBackground; bg = solarized.red;    };
        count_selected = { fg = solarized.lightBackground; bg = solarized.darkAccent; };

        border_symbol = "│";
        border_style  = { fg = solarized.lightestAccent; };
      };

      status = {
        overall           = { fg = solarized.darkAccent; bg = solarized.lightBackgroundContrast; };
        filename_modified = { fg = solarized.yellow; bold = true; };
        filename_exists   = { fg = solarized.red; bold = true; };
        permissions_t     = { fg = solarized.lightAccent; };
        permissions_r     = { fg = solarized.yellow; };
        permissions_w     = { fg = solarized.red; };
        permissions_x     = { fg = solarized.green; };
        permissions_s     = { fg = solarized.lightAccent; };
        ownership         = { fg = solarized.lightAccent; };
        filesize          = { fg = solarized.cyan; };
      };

      input = {
        border   = { fg = solarized.blue; };
        title    = { fg = solarized.blue; bold = true; };
        value    = { fg = solarized.darkBackground; };
        selected = { reversed = true; };
      };

      completion = {
        border   = { fg = solarized.blue; };
        active   = { fg = solarized.darkBackground; bg = solarized.lightBackgroundContrast; bold = true; };
        inactive = { fg = solarized.darkAccent; };
      };

      tasks = {
        border  = { fg = solarized.blue; };
        title   = { fg = solarized.blue; bold = true; };
        hovered = { underline = true; };
      };

      which = {
        mask            = { bg = solarized.lightBackgroundContrast; };
        cand            = { fg = solarized.blue; };
        rest            = { fg = solarized.lightAccent; };
        desc            = { fg = solarized.darkAccent; };
        separator_style = { fg = solarized.lightestAccent; };
      };

      notify = {
        title_info  = { fg = solarized.cyan;   bold = true; };
        title_warn  = { fg = solarized.orange; bold = true; };
        title_error = { fg = solarized.red;    bold = true; };
      };

      help = {
        on      = { fg = solarized.blue; };
        run     = { fg = solarized.orange; };
        desc    = { fg = solarized.darkAccent; };
        hovered = { bg = solarized.lightBackgroundContrast; bold = true; };
        footer  = { fg = solarized.lightAccent; bg = solarized.lightBackgroundContrast; };
      };

      filetype = {
        rules = [
          { mime = "image/*";                        fg = solarized.yellow;  }
          { mime = "video/*";                        fg = solarized.magenta; }
          { mime = "audio/*";                        fg = solarized.magenta; }
          { mime = "application/zip";                fg = solarized.orange;  }
          { mime = "application/gzip";               fg = solarized.orange;  }
          { mime = "application/x-tar";              fg = solarized.orange;  }
          { mime = "application/x-bzip2";            fg = solarized.orange;  }
          { mime = "application/x-7z-compressed";    fg = solarized.orange;  }
          { mime = "application/x-rar";              fg = solarized.orange;  }
          { mime = "application/x-xz";               fg = solarized.orange;  }
          { mime = "application/zstd";               fg = solarized.orange;  }
          { mime = "inode/x-empty";                  fg = solarized.lightestAccent; }
        ];
      };
    };
  };

  xdg.configFile."yazi/yazi.toml".text = ''
    [mgr]
    ratio          = [5, 6, 10]
    show_hidden    = true
    show_symlink   = true
    sort_by        = "natural"
    sort_sensitive = false
    sort_reverse   = false
    sort_dir_first = true
    linemode       = "size"
  '';
}
