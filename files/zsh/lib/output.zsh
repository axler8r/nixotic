#!/usr/bin/env zsh
#
# Colored terminal output helpers
# Source this file in functions/scripts that need formatted output
#
# Usage:
#   source "${0:h}/../lib/output.zsh"
#

# Standard output helpers — all write to stderr
__ax_error() {
    if [[ -t 2 && -z "${NO_COLOR+x}" ]]; then
        print -P "%F{red}Error:%f $1" >&2
    else
        print "Error: $1" >&2
    fi
}

__ax_warn() {
    if [[ -t 2 && -z "${NO_COLOR+x}" ]]; then
        print -P "%F{yellow}Warning:%f $1" >&2
    else
        print "Warning: $1" >&2
    fi
}

__ax_info() {
    if [[ -t 2 && -z "${NO_COLOR+x}" ]]; then
        print -P "%F{green}Info:%f $1" >&2
    else
        print "Info: $1" >&2
    fi
}

__ax_success() {
    if [[ -t 2 && -z "${NO_COLOR+x}" ]]; then
        print -P "%F{green}Success:%f $1" >&2
    else
        print "Success: $1" >&2
    fi
}

# Verbose output (only prints if _verbose_flag is set)
__ax_verbose() {
    [[ -n $_verbose_flag ]] || return 0
    if [[ -t 2 && -z "${NO_COLOR+x}" ]]; then
        print -P "%F{blue}Debug:%f $1" >&2
    else
        print "Debug: $1" >&2
    fi
}

# Confirmation prompt (returns 0 if yes, 1 if no)
# Usage: __ax_confirm "Delete this file?" || return 0
__ax_confirm() {
    local message="${1:-Continue?}"
    echo -n "${message} (y/N): "
    read -r response
    [[ "${response}" =~ ^[yY]([eE][sS])?$ ]]
}

# Table output helper
# Reads pipe-delimited rows from stdin (first row = header).
# Formatted mode: gum table when stdout is a TTY and NO_COLOR is unset.
# Plain mode: column-aligned output (--raw, non-TTY stdout, NO_COLOR set, or no gum).
#
# Usage:
#   echo -e "Name|Size\nfoo.txt|1.2 KB" | __ax_table
#   echo -e "Name|Size\nfoo.txt|1.2 KB" | __ax_table --raw
__ax_table() {
    local raw=false
    [[ "$1" == "--raw" ]] && raw=true

    if [[ "$raw" == true ]] || [[ ! -t 1 ]] || [[ -n "${NO_COLOR+x}" ]] || ! command -v gum &>/dev/null; then
        column -t -s"|"
    else
        gum table --separator "|" --border rounded --print
    fi
}
