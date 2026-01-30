#!/usr/bin/env zsh
#
# Colored terminal output helpers
# Source this file in functions/scripts that need formatted output
#
# Usage:
#   source "${0:h}/../lib/output.zsh"
#

# Standard output helpers
__ax_error()   { print -P "%F{red}Error:%f $1" >&2 }
__ax_warn()    { print -P "%F{yellow}Warning:%f $1" >&2 }
__ax_info()    { print -P "%F{green}Info:%f $1" }
__ax_success() { print -P "%F{green}Success:%f $1" }

# Verbose output (only prints if _verbose_flag is set)
__ax_verbose() { [[ -n $_verbose_flag ]] && print -P "%F{blue}Debug:%f $1" >&2 }

# Confirmation prompt (returns 0 if yes, 1 if no)
# Usage: __ax_confirm "Delete this file?" || return 0
__ax_confirm() {
    local message="${1:-Continue?}"
    echo -n "${message} (y/N): "
    read -r response
    [[ "${response}" =~ ^[yY]([eE][sS])?$ ]]
}
