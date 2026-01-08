# Nushell Configuration File
# See: https://www.nushell.sh/book/configuration.html

# Solarized Dark theme
let solarized_dark = {
  separator: "#93a1a1"
  leading_trailing_space_bg: { attr: n }
  header: { fg: "#859900" attr: b }
  empty: "#268bd2"
  bool: "#93a1a1"
  int: "#93a1a1"
  filesize: "#2aa198"
  duration: "#93a1a1"
  date: "#d33682"
  range: "#93a1a1"
  float: "#93a1a1"
  string: "#93a1a1"
  nothing: "#93a1a1"
  binary: "#93a1a1"
  cellpath: "#93a1a1"
  row_index: { fg: "#859900" attr: b }
  record: "#93a1a1"
  list: "#93a1a1"
  block: "#93a1a1"
  hints: "#586e75"
  search_result: { bg: "#dc322f" fg: "#fdf6e3" }
  shape_and: { fg: "#6c71c4" attr: b }
  shape_binary: { fg: "#6c71c4" attr: b }
  shape_block: { fg: "#268bd2" attr: b }
  shape_bool: "#2aa198"
  shape_closure: { fg: "#859900" attr: b }
  shape_custom: "#859900"
  shape_datetime: { fg: "#2aa198" attr: b }
  shape_directory: "#2aa198"
  shape_external: "#2aa198"
  shape_externalarg: { fg: "#859900" attr: b }
  shape_filepath: "#2aa198"
  shape_flag: { fg: "#268bd2" attr: b }
  shape_float: { fg: "#6c71c4" attr: b }
  shape_garbage: { fg: "#fdf6e3" bg: "#dc322f" attr: b }
  shape_globpattern: { fg: "#2aa198" attr: b }
  shape_int: { fg: "#6c71c4" attr: b }
  shape_internalcall: { fg: "#2aa198" attr: b }
  shape_list: { fg: "#2aa198" attr: b }
  shape_literal: "#268bd2"
  shape_match_pattern: "#859900"
  shape_matching_brackets: { attr: u }
  shape_nothing: "#2aa198"
  shape_operator: "#b58900"
  shape_or: { fg: "#6c71c4" attr: b }
  shape_pipe: { fg: "#6c71c4" attr: b }
  shape_range: { fg: "#b58900" attr: b }
  shape_record: { fg: "#2aa198" attr: b }
  shape_redirection: { fg: "#6c71c4" attr: b }
  shape_signature: { fg: "#859900" attr: b }
  shape_string: "#859900"
  shape_string_interpolation: { fg: "#2aa198" attr: b }
  shape_table: { fg: "#268bd2" attr: b }
  shape_variable: "#6c71c4"
  shape_vardecl: "#6c71c4"
}

# Solarized Light theme
let solarized_light = {
  separator: "#657b83"
  leading_trailing_space_bg: { attr: n }
  header: { fg: "#859900" attr: b }
  empty: "#268bd2"
  bool: "#657b83"
  int: "#657b83"
  filesize: "#2aa198"
  duration: "#657b83"
  date: "#d33682"
  range: "#657b83"
  float: "#657b83"
  string: "#657b83"
  nothing: "#657b83"
  binary: "#657b83"
  cellpath: "#657b83"
  row_index: { fg: "#859900" attr: b }
  record: "#657b83"
  list: "#657b83"
  block: "#657b83"
  hints: "#93a1a1"
  search_result: { bg: "#dc322f" fg: "#fdf6e3" }
  shape_and: { fg: "#6c71c4" attr: b }
  shape_binary: { fg: "#6c71c4" attr: b }
  shape_block: { fg: "#268bd2" attr: b }
  shape_bool: "#2aa198"
  shape_closure: { fg: "#859900" attr: b }
  shape_custom: "#859900"
  shape_datetime: { fg: "#2aa198" attr: b }
  shape_directory: "#2aa198"
  shape_external: "#2aa198"
  shape_externalarg: { fg: "#859900" attr: b }
  shape_filepath: "#2aa198"
  shape_flag: { fg: "#268bd2" attr: b }
  shape_float: { fg: "#6c71c4" attr: b }
  shape_garbage: { fg: "#fdf6e3" bg: "#dc322f" attr: b }
  shape_globpattern: { fg: "#2aa198" attr: b }
  shape_int: { fg: "#6c71c4" attr: b }
  shape_internalcall: { fg: "#2aa198" attr: b }
  shape_list: { fg: "#2aa198" attr: b }
  shape_literal: "#268bd2"
  shape_match_pattern: "#859900"
  shape_matching_brackets: { attr: u }
  shape_nothing: "#2aa198"
  shape_operator: "#b58900"
  shape_or: { fg: "#6c71c4" attr: b }
  shape_pipe: { fg: "#6c71c4" attr: b }
  shape_range: { fg: "#b58900" attr: b }
  shape_record: { fg: "#2aa198" attr: b }
  shape_redirection: { fg: "#6c71c4" attr: b }
  shape_signature: { fg: "#859900" attr: b }
  shape_string: "#859900"
  shape_string_interpolation: { fg: "#2aa198" attr: b }
  shape_table: { fg: "#268bd2" attr: b }
  shape_variable: "#6c71c4"
  shape_vardecl: "#6c71c4"
}

# The default config record
$env.config = {
  show_banner: false
  use_kitty_protocol: true
  
  # Line editor settings
  edit_mode: vi
  
  # History settings
  history: {
    max_size: 5000
    sync_on_enter: true
    file_format: "sqlite"
    isolation: false
  }
  
  # Completion settings
  completions: {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
  }
  
  # Cursor shape for different vi modes
  cursor_shape: {
    vi_insert: line
    vi_normal: block
  }
  
  # Color settings
  color_config: $solarized_dark  # Change to $solarized_light for light theme
  use_ansi_coloring: true
  
  # Table display settings
  table: {
    mode: rounded
    index_mode: always
    show_empty: true
    trim: {
      methodology: wrapping
      wrapping_try_keep_words: true
    }
  }
  
  # Explore command settings (for interactive table viewing)
  explore: {
    exit_esc: true
    command_bar_text: "#C4C9C6"
    status_bar_background: {fg: "#1D1F21" bg: "#C4C9C6"}
    highlight: {fg: "black" bg: "yellow"}
    
    table: {
      split_line: "#404040"
      cursor: true
      line_index: true
      line_shift: true
      line_head_top: true
      line_head_bottom: true
    }
  }
  
  # Keybindings
  keybindings: [
    {
      name: completion_menu
      modifier: none
      keycode: tab
      mode: [emacs vi_normal vi_insert]
      event: {
        until: [
          { send: menu name: completion_menu }
          { send: menunext }
          { edit: complete }
        ]
      }
    }
    {
      name: history_menu
      modifier: control
      keycode: char_r
      mode: [emacs, vi_insert, vi_normal]
      event: { send: menu name: history_menu }
    }
    {
      name: unix_line_discard
      modifier: control
      keycode: char_u
      mode: [emacs, vi_insert, vi_normal]
      event: { edit: cutfromlinestart }
    }
  ]
  
  # Shell integration hooks
  hooks: {
    pre_prompt: [{ null }]
    pre_execution: [{ null }]
    env_change: {
      PWD: [{|before, after| null }]
    }
    display_output: "if (term size).columns >= 100 { table -e } else { table }"
  }
  
  # Menus
  menus: [
    {
      name: completion_menu
      only_buffer_difference: false
      marker: "| "
      type: {
        layout: columnar
        columns: 4
        col_width: 20
        col_padding: 2
      }
      style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
      }
    }
    {
      name: history_menu
      only_buffer_difference: true
      marker: "? "
      type: {
        layout: list
        page_size: 10
      }
      style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
      }
    }
  ]
}

# Source custom aliases
source ~/.config/nushell/aliases.nu

# Starship prompt
use ~/.cache/starship/init.nu
