# Nushell Aliases and Custom Commands
# Follows similar naming convention to zshalias:
# - PascalCase for canonical commands
# - lowercase for shortcuts

# System Information Commands
export def Get-IpAddress [] {
  http get https://api.ipify.org
}
export alias get-ipaddress = Get-IpAddress

export def Get-TerminalDimensions [] {
  let size = (term size)
  $"($size.rows) × ($size.columns)"
}
export alias get-terminaldimensions = Get-TerminalDimensions

# File Operations
export def Get-FileSize [path: string] {
  ls $path | get size
}
export alias get-filesize = Get-FileSize

# Directory Stack Operations
export alias stack = dirs

# Date/Time
export def now [] {
  date now | format date '%Y-%m-%d %H:%M:%S'
}

# Enhanced ls variants
export def ll [] { ls -l }
export def la [] { ls -a }
export def lla [] { ls -la }

# Git helpers
export def git-status [] { git status }
export def git-log-pretty [] {
  git log --oneline --graph --all --decorate
}

# Docker helpers (if needed)
export def Get-DanglingDockerImages [] {
  docker images -f "dangling=true"
}
export alias get-danglingdockerimages = Get-DanglingDockerImages

export def Get-DockerImages [] {
  docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
}
export alias get-dockerimages = Get-DockerImages

# System monitoring
export def Get-SwapUsage [] {
  free -h | from ssv | where total != "0B" | select total used free
}
export alias get-swapusage = Get-SwapUsage

# Package management helpers for NixOS
export def nix-search [query: string] {
  nix search nixpkgs $query
}

export def nix-shell-run [...packages: string] {
  nix-shell -p ...$packages
}

# Clean up helpers
export def Clear-FileSystemCache [] {
  sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
  print "File system cache cleared"
}
export alias clear-filesystemcache = Clear-FileSystemCache

# Path utilities
export def Add-Path [path: string] {
  $env.PATH = ($env.PATH | prepend $path)
}

# Quick directory navigation
export def mkcd [dir: string] {
  mkdir $dir
  cd $dir
}

# Find files by name
export def Find-File [pattern: string] {
  fd $pattern
}
export alias find-file = Find-File

# Find in files (grep alternative)
export def Find-InFiles [pattern: string, ...paths: string] {
  if ($paths | is-empty) {
    rg $pattern
  } else {
    rg $pattern ...$paths
  }
}
export alias find-infiles = Find-InFiles

# Process management
export def Get-ProcessByName [name: string] {
  ps | where name =~ $name
}
export alias get-processbyname = Get-ProcessByName

# Network utilities
export def Get-ListeningPorts [] {
  ss -tulpn | from ssv
}
export alias get-listeningports = Get-ListeningPorts

# Home Manager rebuild shortcut
export def hm-switch [] {
  home-manager switch --flake ~/.nixotic
}

# NixOS rebuild shortcut
export def nixos-rebuild-switch [] {
  sudo nixos-rebuild switch --flake ~/.nixotic#prototype --impure
}
