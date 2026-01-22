#!/usr/bin/env zsh
# Git context plugin for zsh-copilot
#
# Adds git repository information to the context.

_zsh_copilot_context_git() {
    local context="$1"

    local git_info=""
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch=$(git branch --show-current 2>/dev/null)
        local repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
        local dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

        git_info="You are in git repository '$repo' on branch '$branch'."
        if [[ "$dirty" -gt 0 ]]; then
            git_info+=" There are $dirty uncommitted changes."
        fi
    fi

    if [[ -n "$context" ]]; then
        echo "$context $git_info"
    else
        echo "$git_info"
    fi
}
