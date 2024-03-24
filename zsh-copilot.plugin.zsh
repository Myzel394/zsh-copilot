(( ! ${+ZSH_COPILOT_KEY} )) &&
    typeset -g ZSH_COPILOT_KEY='^z'

(( ! ${+ZSH_COPILOT_SEND_CONTEXT} )) &&
    typeset -g ZSH_COPILOT_SEND_CONTEXT=true

(( ! ${+ZSH_COPILOT_SEND_GIT_DIFF} )) &&
    typeset -g ZSH_COPILOT_SEND_GIT_DIFF=true

(( ! ${+ZSH_COPILOT_DEBUG} )) &&
    typeset -g ZSH_COPILOT_DEBUG=false

SYSTEM_PROMPT="You will be given the raw input of a shell command. Your task is to either complete the command or provide a new command that you think the user is trying to type. If you return a completely new command for the user, prefix is with an equal sign (=). If you return a completion for the user's command, prefix it with a plus sign (+). MAKE SURE TO ONLY INCLUDE THE REST OF THE COMPLETION!!! Do not write any leading or trailing characters except if required for the completion to work. Only respond with either a completion or a new command, not both. Your response may only start with either a plus sign or an equal sign. Your response MAY NOT start with both! This means that your response IS NOT ALLOWED to start with '+=' or '=+'. Do not explain the command. Do not ask for more information, you won't receive it. Your response will be run in the user's shell. Make sure input is escaped correctly if needed so. Your input should be able to run without any modifications to it. Don't you dare to return anything else other than a shell command!!! DO NOT INTERACT WITH THE USER IN NATURAL LANGUAGE! If you do, you will be banned from the system. Note that the double quote sign is escaped. Keep this in mind when you create quotes. Here are two examples: * User input: 'list files in current directory'; Your response: '=ls' * User input: 'cd /tm'; Your response: '+p'."

if [[ "$ZSH_COPILOT_SEND_CONTEXT" == 'true' ]]; then
    SYSTEM_PROMPT="$SYSTEM_PROMPT Context: You are user ${$(whoami)} with id ${$(id)} in directory ${$(pwd)}. Your shell is ${$(echo $SHELL)} and your terminal is ${$(echo $TERM)} running on ${$(uname -a)}. Your system is ${$(cat /etc/*-release | xargs | sed 's/ /,/g')}."
fi

function _suggest_ai() {
    # Get input
    local input="${BUFFER:0:$CURSOR}"
    input=$(echo "$input" | sed 's/"/\\"/g')

    _zsh_autosuggest_clear
    zle -R "Thinking..."

    local PROMPT="$SYSTEM_PROMPT"
    if [[ "$ZSH_COPILOT_SEND_GIT_DIFF" == 'true' ]]; then
        if [[ $(git rev-parse --is-inside-work-tree) == 'true' ]]; then
            local git_diff=$(git diff --staged --no-color)
            local git_exit_code=$?
            git_diff=$(echo "$git_diff" | tr -d '\n')

            if [[ git_exit_code -eq 0 ]]; then
                PROMPT="$PROMPT; This is the git diff: <---->$git_diff<----> You may provide a git commit message if the user is trying to commit changes. You are an expert at committing changes, you don't give generic messages. You give the best commit messages"
            fi
        fi
    fi

    local data="{
            \"model\": \"gpt-4\",
            \"messages\": [
                {
                    \"role\": \"system\",
                    \"content\": \"$PROMPT\"
                },
                {
                    \"role\": \"user\",
                    \"content\": \""
    data+=$input
    data+="\"
                }
            ]
        }"
    local response=$(curl 'https://api.openai.com/v1/chat/completions' \
        --silent \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d $data)
    local message=$(echo "$response" | jq -r '.choices[0].message.content')

    # zle -U "$suggestion"

    local first_char=${message:0:1}
    local suggestion=${message:1:${#message}}
    
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        touch /tmp/zsh-copilot.log
        echo "$(date);INPUT:$input;RESPONSE:$response;FIRST_CHAR:$first_char;SUGGESTION:$suggestion:DATA:$data" >> /tmp/zsh-copilot.log
    fi

    if [[ "$first_char" == '=' ]]; then
        # Reset user input
        BUFFER=""
        CURSOR=0

        zle -U "$suggestion"
    elif [[ "$first_char" == '+' ]]; then
        _zsh_autosuggest_suggest "$suggestion"
         # POSTDISPLAY="$suggestion"
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

