(( ! ${+ZSH_COPILOT_KEY} )) &&
    typeset -g ZSH_COPILOT_KEY='^z'

(( ! ${+ZSH_COPILOT_SEND_CONTEXT} )) &&
    typeset -g ZSH_COPILOT_SEND_CONTEXT=true

(( ! ${+ZSH_COPILOT_SEND_GIT_DIFF} )) &&
    typeset -g ZSH_COPILOT_SEND_GIT_DIFF=true

SYSTEM_PROMPT="You will be given the raw input of a shell command. Your task is to either complete the command or provide a new command that you think the user is trying to type. If you return a completely new command for the user, prefix is with an equal sign (=). If you return a completion for the user's command, prefix it with a plus sign (+). Only respond with either a completion or a new command, not both. Do not explain the command. Do not ask for more information, you won't receive it. Your response will be run in the user's shell. Make sure input is escaped correctly if needed so. Your input should be able to run without any modifications to it. Don't you dare to return anything else other than a shell command!!! DO NOT INTERACT WITH THE USER IN NATURAL LANGUAGE! If you do, you will be banned from the system. Here are two examples: * User input: 'list files in current directory'; Your response: '=ls' * User input: 'cd /tm'; Your response: '+p'."

if [[ "$ZSH_COPILOT_SEND_CONTEXT" == 'true' ]]; then
    SYSTEM_PROMPT="$SYSTEM_PROMPT Context: You are user ${$(whoami)} with id ${$(id)} in directory ${$(pwd)}. Your shell is ${$(echo $SHELL)} and your terminal is ${$(echo $TERM)} running on ${$(uname -a)}. Your system is ${$(cat /etc/*-release | xargs | sed 's/ /,/g')}."
fi

function _suggest_ai() {
    # Get input
    local input="${BUFFER:0:$CURSOR}"

    _zsh_autosuggest_clear
    zle -R "Thinking..."

    local PROMPT="$SYSTEM_PROMPT"
    if [[ "$ZSH_COPILOT_SEND_GIT_DIFF" == 'true' ]]; then
        if [[ "git rev-parse --is-inside-work-tree" == 'true' ]]; then
            local git_diff=$(git diff --no-color | xargs | sed 's/ /\$/g' | xargs | sed 's/ /$/g')

            if [[ $? -eq 0 ]]; then
                PROMPT="$PROMPT; This is the git diff (newlines separated by dollar signs): $git_diff;; You may provide a git commit message if the user is trying to commit changes. Do not say something like 'Your commit message' or 'Your commit message here'. Just provide the commit message."
            fi
        fi
    fi

    local response=$(curl 'https://api.openai.com/v1/chat/completions' \
        --silent \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"gpt-4\",
            \"messages\": [
                {
                    \"role\": \"system\",
                    \"content\": \"$PROMPT\"
                },
                {
                    \"role\": \"user\",
                    \"content\": \"${input}\"
                }
            ]
        }" | jq '.choices[0].message.content' --raw-output)

    # zle -U "$suggestion"

    local first_char=${response:0:1}
    local suggestion=${response:1:${#response}}

    if [[ "$first_char" == '=' ]]; then
        BUFFER=""
        CURSOR=0

        zle -U "$suggestion"

        # Reset suggestion
    elif [[ "$first_char" == '+' ]]; then
        _zsh_autosuggest_suggest "$suggestion"
    fi
}

function zsh-copilot() {
    echo "ZSH Copilot is now active. Press $ZSH_COPILOT_KEY to get suggestions."
    echo ""
    echo "Configurations:"
    echo "    - ZSH_COPILOT_KEY: Key to press to get suggestions (default: ^z, value: $ZSH_COPILOT_KEY)."
    echo "    - ZSH_COPILOT_SEND_CONTEXT: If \`true\`, zsh-copilot will send context information (whoami, shell, pwd, etc.) to the AI model (default: true, value: $ZSH_COPILOT_SEND_CONTEXT)."
    echo "    - ZSH_COPILOT_SEND_GIT_DIFF: If \`true\`, zsh-copilot will send the git diff (if available) to the AI model (default: true, value: $ZSH_COPILOT_SEND_GIT_DIFF)."
}

zle -N _suggest_ai
bindkey $ZSH_COPILOT_KEY _suggest_ai

