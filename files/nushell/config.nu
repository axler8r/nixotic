# Nushell Configuration File
# See: https://www.nushell.sh/book/configuration.html

let solarized = {
  light_background: "#fdf6e3"
  light_background_contrast: "#eee8d5"
  lightest_accent: "#93a1a1"
  light_accent: "#839496"
  dark_accent: "#657b83"
  darkest_accent: "#586e75"
  dark_background_contrast: "#073642"
  dark_background: "#002b36"

  red: "#dc322f"
  orange: "#cb4b16"
  yellow: "#b58900"
  green: "#859900"
  cyan: "#2aa198"
  blue: "#268bd2"
  violet: "#6c71c4"
  magenta: "#d33682"
}

let solarized_theme_base = {
  leading_trailing_space_bg: { attr: n }
  header: { fg: $solarized.green attr: b }
  empty: $solarized.blue
  row_index: { fg: $solarized.green attr: b }
  search_result: { bg: $solarized.red fg: $solarized.light_background }
  shape_bool: $solarized.blue
  shape_garbage: { fg: $solarized.red attr: b }
}

let solarized_dark_values = {
  separator: $solarized.lightest_accent
  bool: $solarized.blue
  int: $solarized.blue
  filesize: $solarized.blue
  duration: $solarized.blue
  date: $solarized.blue
  range: $solarized.blue
  float: $solarized.blue
  string: $solarized.blue
  nothing: $solarized.blue
  binary: $solarized.blue
  cellpath: $solarized.blue
  record: $solarized.blue
  list: $solarized.blue
  block: $solarized.blue
  hints: $solarized.lightest_accent
  shape_literal: $solarized.blue
  shape_nothing: $solarized.blue
  shape_string: $solarized.blue
  shape_table: { fg: $solarized.blue attr: b }
  shape_variable: $solarized.blue
  shape_vardecl: $solarized.blue
}

let solarized_dark_shapes = {
  shape_and: $solarized.lightest_accent
  shape_binary: $solarized.lightest_accent
  shape_block: { fg: $solarized.blue attr: b }
  shape_closure: { fg: $solarized.green attr: b }
  shape_custom: $solarized.green
  shape_datetime: $solarized.blue
  shape_directory: $solarized.blue
  shape_external: $solarized.green
  shape_externalarg: $solarized.blue
  shape_filepath: $solarized.blue
  shape_flag: { fg: $solarized.blue attr: b }
  shape_float: $solarized.blue
  shape_globpattern: $solarized.blue
  shape_int: $solarized.blue
  shape_internalcall: $solarized.green
  shape_list: { fg: $solarized.blue attr: b }
  shape_match_pattern: $solarized.blue
  shape_matching_brackets: { fg: $solarized.lightest_accent attr: u }
  shape_operator: $solarized.lightest_accent
  shape_or: $solarized.lightest_accent
  shape_pipe: $solarized.lightest_accent
  shape_range: $solarized.lightest_accent
  shape_record: { fg: $solarized.blue attr: b }
  shape_redirection: $solarized.lightest_accent
  shape_signature: { fg: $solarized.green attr: b }
  shape_string_interpolation: $solarized.blue
}

let solarized_light_values = {
  separator: $solarized.light_accent
  bool: $solarized.blue
  int: $solarized.blue
  filesize: $solarized.blue
  duration: $solarized.blue
  date: $solarized.blue
  range: $solarized.blue
  float: $solarized.blue
  string: $solarized.blue
  nothing: $solarized.blue
  binary: $solarized.blue
  cellpath: $solarized.blue
  record: $solarized.blue
  list: $solarized.blue
  block: $solarized.blue
  hints: $solarized.lightest_accent
  shape_literal: $solarized.blue
  shape_nothing: $solarized.blue
  shape_string: $solarized.blue
  shape_table: { fg: $solarized.blue attr: b }
  shape_variable: $solarized.blue
  shape_vardecl: $solarized.blue
}

let solarized_light_shapes = {
  shape_and: $solarized.light_accent
  shape_binary: $solarized.light_accent
  shape_block: { fg: $solarized.blue attr: b }
  shape_closure: { fg: $solarized.green attr: b }
  shape_custom: $solarized.green
  shape_datetime: $solarized.blue
  shape_directory: $solarized.blue
  shape_external: $solarized.green
  shape_externalarg: $solarized.blue
  shape_filepath: $solarized.blue
  shape_flag: { fg: $solarized.blue attr: b }
  shape_float: $solarized.blue
  shape_globpattern: $solarized.blue
  shape_int: $solarized.blue
  shape_internalcall: $solarized.green
  shape_list: { fg: $solarized.blue attr: b }
  shape_match_pattern: $solarized.blue
  shape_matching_brackets: { fg: $solarized.light_accent attr: u }
  shape_operator: $solarized.light_accent
  shape_or: $solarized.light_accent
  shape_pipe: $solarized.light_accent
  shape_range: $solarized.light_accent
  shape_record: { fg: $solarized.blue attr: b }
  shape_redirection: $solarized.light_accent
  shape_signature: { fg: $solarized.green attr: b }
  shape_string_interpolation: $solarized.blue
}

let menu_style = {
  text: green
  selected_text: green_reverse
  description_text: yellow
}

# Solarized Dark theme
let solarized_dark = (
  $solarized_theme_base
  | merge $solarized_dark_values
  | merge $solarized_dark_shapes
)

# Solarized Light theme
let solarized_light = (
  $solarized_theme_base
  | merge $solarized_light_values
  | merge $solarized_light_shapes
)

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
  color_config: $solarized_light
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
    command_bar_text: $solarized.dark_accent
    status_bar_background: {fg: $solarized.darkest_accent bg: $solarized.light_background_contrast}
    highlight: {fg: $solarized.light_background bg: $solarized.yellow}

    table: {
      split_line: $solarized.lightest_accent
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
      style: $menu_style
    }
    {
      name: history_menu
      only_buffer_difference: true
      marker: "? "
      type: {
        layout: list
        page_size: 10
      }
      style: $menu_style
    }
  ]
}

# Source custom aliases
source ~/.config/nushell/aliases.nu

# Starship prompt
use ~/.cache/starship/init.nu
