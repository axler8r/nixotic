#!/usr/bin/env zsh
#
# Input validation and dependency checking helpers
# Source this file in functions/scripts that need validation
#
# Usage:
#   source "${0:h}/../lib/validation.zsh"
#
# Note: Requires lib/output.zsh for error messages
#

# Check if commands exist
# Usage: __ax_check_deps curl jq ffmpeg || return 2
__ax_check_deps() {
    local missing=()
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        __ax_error "Missing commands: ${missing[*]}"
        return 2
    fi
    return 0
}

# Require file to exist
# Usage: __ax_require_file "$input" || return 1
__ax_require_file() {
    [[ -f "$1" ]] || { __ax_error "File not found: $1"; return 1 }
}

# Require directory to exist
# Usage: __ax_require_dir "$path" || return 1
__ax_require_dir() {
    [[ -d "$1" ]] || { __ax_error "Directory not found: $1"; return 1 }
}

# Require argument not empty
# Usage: __ax_require_arg "$_input" "input file" || return 1
__ax_require_arg() {
    [[ -n "$1" ]] || { __ax_error "Missing required argument: $2"; return 1 }
}

# Require running as root
# Usage: __ax_require_root || return 2
__ax_require_root() {
    (( EUID == 0 )) || { __ax_error "This command must be run as root (use sudo)"; return 2 }
}

# Validate file has expected extension
# Usage: __ax_require_extension "$file" "md" || return 1
__ax_require_extension() {
    local file="$1" ext="$2"
    [[ "${file:e}" == "$ext" ]] || { __ax_error "File must have .$ext extension: $file"; return 1 }
}

# Require path to exist and be a file or directory
# Usage: __ax_require_path_target "$path" || return 1
__ax_require_path_target() {
    local path="$1"
    [[ -e "$path" ]] || { __ax_error "Path does not exist."; return 1 }
    [[ -d "$path" || -f "$path" ]] || { __ax_error "Path is not a file or directory."; return 1 }
}

# Require path to exist, be a file or directory, and be writable
# Usage: __ax_require_writable_path_target "$path" || return 1
__ax_require_writable_path_target() {
    local path="$1"
    __ax_require_path_target "$path" || return 1
    [[ -w "$path" ]] || { __ax_error "Path is not writable."; return 1 }
}

# Require extended attribute name to be well-formed
# Usage: __ax_require_xattr_name "$attr" || return 1
__ax_require_xattr_name() {
    local attribute="$1"
    [[ "$attribute" =~ ^[a-zA-Z0-9._-]+$ ]] || { __ax_error "Invalid attribute name."; return 1 }
}
