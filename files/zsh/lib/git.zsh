#!/usr/bin/env zsh
#
# Git repository validation helpers
# Source this file after lib/output.zsh and lib/validation.zsh
#

__ax_require_git_repo() {
    __ax_check_deps git || return 2

    git rev-parse --is-inside-work-tree > /dev/null 2>&1 \
        || { __ax_error "Not inside a Git repository."; return 1 }
}

__ax_git_current_branch() {
    typeset _branch

    _branch="$(git symbolic-ref --quiet --short HEAD 2> /dev/null)" \
        || { __ax_error "Git HEAD is detached. Switch to a branch first."; return 1 }

    print -- "${_branch}"
}

__ax_require_clean_git_worktree() {
    __ax_require_git_repo || return $?

    typeset _status
    _status="$(git status --porcelain)"

    [[ -z "${_status}" ]] \
        || { __ax_error "Git worktree must be clean."; print -- "${_status}" >&2; return 1 }
}

__ax_require_branch_exists() {
    typeset _branch="$1"

    __ax_require_arg "${_branch}" "branch name" || return 1

    git show-ref --verify --quiet "refs/heads/${_branch}" \
        || { __ax_error "Branch does not exist: ${_branch}"; return 1 }
}

__ax_require_not_branch() {
    typeset _branch="$1"
    typeset _current_branch

    __ax_require_arg "${_branch}" "branch name" || return 1

    _current_branch="$(__ax_git_current_branch)" || return 1

    [[ "${_current_branch}" != "${_branch}" ]] \
        || { __ax_error "Refusing to operate on the current branch: ${_branch}"; return 1 }
}

__ax_require_branch_pattern() {
    typeset _branch="$1"
    typeset _pattern="$2"
    typeset _label="${3:-$2}"

    __ax_require_arg "${_branch}" "branch name" || return 1
    __ax_require_arg "${_pattern}" "branch pattern" || return 1

    [[ "${_branch}" == ${~_pattern} ]] \
        || { __ax_error "Branch must match ${_label}: ${_branch}"; return 1 }
}

__ax_require_wip_branch() {
    typeset _branch="$1"

    if [[ -z "${_branch}" ]]; then
        _branch="$(__ax_git_current_branch)" || return 1
    fi

    __ax_require_branch_pattern "${_branch}" "wip/*" "wip/*"
}
