(( ! ${+ZSH_COPILOT_KEY} )) &&
typeset -g ZSH_COPILOT_KEY='^z'

function _suggest_ai() {
    # Get input
    local input="${BUFFER:0:$CURSOR}"

    zle -R "Thinking..."

    local response=$(curl 'https://api.openai.com/v1/chat/completions' \
        --silent \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"gpt-4\",
            \"messages\": [
                {
                    \"role\": \"system\",
                    \"content\": \"You will be given the raw input of a shell command. Your task is to either complete the command or provide a new command that you think the user is trying to type. If you return a completely new command for the user, prefix is with an equal sign (=). If you return a completion for the user's command, prefix it with a plus sign (+). Only respond with either a completion or a new command, not both. Do not explain the command. Do not ask for more information, you won't receive it. Your response will be run in the user's shell. So don't do you dare to return anything else other than a shell command. If you do, you will be banned from the system. Here are two examples: * User input: 'list files in current directory'; Your response: '=ls' * User input: 'cd /tm'; Your response: '+p'\"
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
        BUFFER="$suggestion"
        CURSOR=${#BUFFER}

        # Reset suggestion
        _zsh_autosuggest_suggest ''
    elif [[ "$first_char" == '+' ]]; then
        _zsh_autosuggest_suggest "$suggestion"
    fi
}

zle -N _suggest_ai
bindkey $ZSH_COPILOT_KEY _suggest_ai

