#!/usr/bin/env zsh
# System context plugin for zsh-copilot
#
# Adds user, shell, terminal, and OS information to the context.

_zsh_copilot_context_system() {
    local context="$1"

    local system_info
    if [[ "$OSTYPE" == "darwin"* ]]; then
        system_info="Your system is ${$(sw_vers | xargs | sed 's/ /./g')}."
    else
        system_info="Your system is ${$(cat /etc/*-release | xargs | sed 's/ /,/g')}."
    fi

    local info="You are user $(whoami) with id $(id) in directory $(pwd). "
    info+="Your shell is $SHELL and your terminal is $TERM running on $(uname -a). "
    info+="$system_info"

    if [[ -n "$context" ]]; then
        echo "$context $info"
    else
        echo "$info"
    fi
}
