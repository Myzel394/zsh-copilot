#!/usr/bin/env zsh

# Default key binding
(( ! ${+ZSH_COPILOT_KEY} )) &&
    typeset -g ZSH_COPILOT_KEY='^z'

# Configuration options
(( ! ${+ZSH_COPILOT_SEND_CONTEXT} )) &&
    typeset -g ZSH_COPILOT_SEND_CONTEXT=true

(( ! ${+ZSH_COPILOT_DEBUG} )) &&
    typeset -g ZSH_COPILOT_DEBUG=false

# AI provider selection (auto-detect if not set)
if [[ -z "$ZSH_COPILOT_AI_PROVIDER" ]]; then
    if [[ -n "$OPENAI_API_KEY" ]]; then
        typeset -g ZSH_COPILOT_AI_PROVIDER="openai"
    elif [[ -n "$ANTHROPIC_API_KEY" ]]; then
        typeset -g ZSH_COPILOT_AI_PROVIDER="anthropic"
    fi
fi

# System prompt
if [[ -z "$ZSH_COPILOT_SYSTEM_PROMPT" ]]; then
read -r -d '' ZSH_COPILOT_SYSTEM_PROMPT <<- EOM
  You will be given the raw input of a shell command. 
  Your task is to provide a command the user is trying to execute.
  Return the whole command that you think the user wants to run.

  Your response MAY NOT contain any newlines!
  Do NOT add any additional text, comments, or explanations to your response.
  Do not ask for more information, you won't receive it. 

  Your response will be run in the user's shell. 
  Make sure input is escaped correctly if needed so. 
  Your input should be able to run without any modifications to it.
  DO NOT INTERACT WITH THE USER IN NATURAL LANGUAGE!
  Note that the double quote sign is escaped. Keep this in mind when you create quotes. 
  Here are two examples: 
    * User input: 'list files in current directory'; Your response: 'ls' (ls is the builtin command for listing files)
    * User input: 'cd /tm'; Your response: 'cd /tmp' (/tmp is the standard temp folder on linux and mac).
EOM
fi

if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
    touch /tmp/zsh-copilot.log
fi

function _fetch_suggestions() {
    local input="$1"
    local full_prompt="$2"
    local provider_func="_zsh_copilot_provider_${ZSH_COPILOT_AI_PROVIDER}"

    if (( ! $+functions[$provider_func] )); then
        echo "Unknown provider: $ZSH_COPILOT_AI_PROVIDER" > /tmp/.zsh_copilot_error
        return 1
    fi

    $provider_func "$input" "$full_prompt"
}


function _show_loading_animation() {
    local pid=$1
    local interval=0.1
    local animation_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=1

    cleanup() {
      kill $pid
      echo -ne "\e[?25h"
    }
    trap cleanup SIGINT
    
    while kill -0 $pid 2>/dev/null; do
        # Display current animation frame
        zle -R "${animation_chars[i]}"

        # Update index, make sure it starts at 1
        i=$(( (i + 1) % ${#animation_chars[@]} ))

        if [[ $i -eq 0 ]]; then
            i=1
        fi
        
        sleep $interval
    done

    echo -ne "\e[?25h"
    trap - SIGINT
}

function _suggest_ai() {
    local context_info=""
    if [[ "$ZSH_COPILOT_SEND_CONTEXT" == 'true' ]]; then
        local system

        if [[ "$OSTYPE" == "darwin"* ]]; then
            system="Your system is ${$(sw_vers | xargs | sed 's/ /./g')}."
        else 
            system="Your system is ${$(cat /etc/*-release | xargs | sed 's/ /,/g')}."
        fi

        context_info="Context: You are user $(whoami) with id $(id) in directory $(pwd). 
            Your shell is $(echo $SHELL) and your terminal is $(echo $TERM) running on $(uname -a).
            $system"
    fi

    ##### Get input
    rm -f /tmp/zsh_copilot_suggestion
    local input=$(echo "${BUFFER:0:$CURSOR}" | tr '\n' ';')
    input=$(echo "$input" | sed 's/"/\\"/g')

    _zsh_autosuggest_clear

    local full_prompt=$(echo "$ZSH_COPILOT_SYSTEM_PROMPT $context_info" | tr -d '\n')

    ##### Fetch message
    read < <(_fetch_suggestions $input $full_prompt & echo $!)
    local pid=$REPLY

    _show_loading_animation $pid
    local response_code=$?

    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Fetched message\",\"input\":\"$input\",\"response_code\":\"$response_code\",\"message\":\"$message\"}" >> /tmp/zsh-copilot.log
    fi

    if [[ ! -f /tmp/zsh_copilot_suggestion ]]; then
        _zsh_autosuggest_clear
        echo $(cat /tmp/.zsh_copilot_error 2>/dev/null || echo "No suggestion available at this time. Please try again later.")
        return 1
    fi

    local message=$(cat /tmp/zsh_copilot_suggestion)

    ##### Process response

    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Suggestion extracted.\",\"input\":\"$input\",\"response\":\"$response\",\"message\":\"$message\",\"data\":\"$data\"}" >> /tmp/zsh-copilot.log
    fi

    ##### And now, let's actually show the suggestion to the user!

    # Set the new suggestion (setting BUFFER directly allows undoing the whole text at once)
    BUFFER="$message"
    CURSOR=${#message}
}

function zsh-copilot() {
    local provider_func="_zsh_copilot_provider_${ZSH_COPILOT_AI_PROVIDER}"

    echo "ZSH Copilot is now active. Press $ZSH_COPILOT_KEY to get suggestions."
    echo ""
    echo "Current provider: $ZSH_COPILOT_AI_PROVIDER"
    if (( $+functions[$provider_func] )); then
        echo "  Status: Provider loaded"
    else
        echo "  Status: ERROR - Provider not found!"
    fi

    echo ""
    echo "Configurations:"
    echo "  - ZSH_COPILOT_KEY: Key to press to get suggestions (default: ^z, value: $ZSH_COPILOT_KEY)"
    echo "  - ZSH_COPILOT_SEND_CONTEXT: Send context info to AI (default: true, value: $ZSH_COPILOT_SEND_CONTEXT)"
    echo "  - ZSH_COPILOT_AI_PROVIDER: AI provider to use (value: $ZSH_COPILOT_AI_PROVIDER)"
    echo "  - ZSH_COPILOT_PLUGINS_DIR: Custom plugins directory (default: ~/.zsh-copilot/plugins)"
    echo "  - ZSH_COPILOT_SYSTEM_PROMPT: Custom system prompt (uses built-in by default)"
}

zle -N _suggest_ai
bindkey "$ZSH_COPILOT_KEY" _suggest_ai

