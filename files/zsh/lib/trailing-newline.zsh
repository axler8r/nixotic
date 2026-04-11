#!/usr/bin/env zsh
#
# Trailing newline helpers for Test-TrailingNewline and Set-TrailingNewline
#
# Usage:
#   source "${0:h}/../lib/trailing-newline.zsh"
#

__ax_trailing_newline_process() {
    local mode="$1"
    local dir="$2"
    local all_flag="$3"
    shift 3
    local -a extensions=("$@")

    local -a fd_args=(--type f)
    local ext
    local -a files
    local file_path
    local mime
    local needs_work
    local last_byte
    local last_two
    local content
    local needs_fix=0
    local fixed=0
    local skipped=0
    local already_ok=0

    [[ "$mode" == "check" || "$mode" == "fix" ]] || {
        __ax_error "Invalid trailing newline mode: $mode"
        return 1
    }

    [[ -n "$all_flag" ]] && fd_args+=(--hidden --no-ignore)

    if [[ ${#extensions[@]} -gt 0 ]]; then
        for ext in "${extensions[@]}"; do
            fd_args+=(--extension "$ext")
        done
    fi

    files=("${(@f)$(fd "${fd_args[@]}" . "$dir" 2>/dev/null)}")

    if [[ ${#files[@]} -eq 0 || -z "${files[1]}" ]]; then
        __ax_info "No files found in '$dir'"
        return 0
    fi

    for file_path in "${files[@]}"; do
        [[ -z "$file_path" ]] && continue

        mime=$(file --brief --mime-type "$file_path" 2>/dev/null)
        [[ "$mime" != text/* && "$mime" != application/json && "$mime" != application/xml ]] && {
            skipped=$(( skipped + 1 ))
            continue
        }

        [[ ! -s "$file_path" ]] && {
            skipped=$(( skipped + 1 ))
            continue
        }

        needs_work=false
        last_byte=$(tail -c 1 "$file_path" | od -An -tx1 | tr -d ' \n')

        if [[ "$last_byte" != "0a" ]]; then
            needs_work=true
        else
            last_two=$(tail -c 2 "$file_path" | od -An -tx1 | tr -d ' \n')
            [[ "$last_two" == "0a0a" ]] && needs_work=true
        fi

        if [[ "$needs_work" == true ]]; then
            needs_fix=$(( needs_fix + 1 ))

            if [[ "$mode" == "check" ]]; then
                __ax_verbose "Needs fix: $file_path"
            else
                content=$(cat "$file_path") || {
                    __ax_error "Failed to read: $file_path"
                    return 1
                }
                printf '%s\n' "$content" > "$file_path" || {
                    __ax_error "Failed to write: $file_path"
                    return 1
                }
                fixed=$(( fixed + 1 ))
                __ax_verbose "Fixed: $file_path"
            fi
        else
            already_ok=$(( already_ok + 1 ))
            __ax_verbose "OK: $file_path"
        fi
    done

    if [[ "$mode" == "check" ]]; then
        if [[ $needs_fix -gt 0 ]]; then
            __ax_warn "$needs_fix file(s) need fixing ($already_ok OK, $skipped skipped)"
            return 1
        fi

        __ax_success "All $already_ok file(s) have correct trailing newlines ($skipped skipped)"
        return 0
    fi

    if [[ $fixed -gt 0 ]]; then
        __ax_success "Fixed $fixed file(s) ($already_ok already OK, $skipped skipped)"
    else
        __ax_success "All $already_ok file(s) already have correct trailing newlines ($skipped skipped)"
    fi
}
