#!/usr/bin/env bash
# Ranger scope.sh for syntax highlighting with Solarized

set -o noclobber -o noglob -o nounset -o pipefail
IFS=$'\n'

FILE_PATH="${1}"
FILE_EXTENSION="${FILE_PATH##*.}"
FILE_EXTENSION_LOWER="$(printf "%s" "${FILE_EXTENSION}" | tr '[:upper:]' '[:lower:]')"

# Syntax highlight with pygments using solarized-dark style
highlight_file() {
    pygmentize -f terminal256 -O style=solarized-dark -g "${FILE_PATH}" 2>/dev/null && exit 0
}

# Try syntax highlighting
highlight_file

# Fallback to plain text
cat "${FILE_PATH}"
exit 0
