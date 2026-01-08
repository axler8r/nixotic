# Nushell Environment Configuration
# See: https://www.nushell.sh/book/configuration.html#environment

# Environment variables
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.GPG_TTY = (tty)

# PATH configuration
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.local/bin")

# Python site packages
if (which python3 | is-not-empty) {
  try {
    $env.SITE_PACKAGE_HOME = (python3 -m site --user-site)
  }
}

# Erlang history
if (which erl | is-not-empty) {
  $env.ERL_AFLAGS = "-kernel shell_history enabled"
}

# XDG Base Directory Specification
$env.XDG_CONFIG_HOME = $"($env.HOME)/.config"
$env.XDG_DATA_HOME = $"($env.HOME)/.local/share"
$env.XDG_STATE_HOME = $"($env.HOME)/.local/state"
$env.XDG_CACHE_HOME = $"($env.HOME)/.cache"

# LS_COLORS for better file coloring (if dircolors available)
if (which dircolors | is-not-empty) {
  try {
    $env.LS_COLORS = (dircolors -b | lines | first | str replace 'LS_COLORS=' '' | str replace --all "'" '')
  }
}

# Starship prompt initialization
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
