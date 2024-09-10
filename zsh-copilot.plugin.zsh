# Initialize default configuration parameters
# ZSH Copilot is configured to use OpenAI by default
# To switch to Ollama, set the ZSH_COPILOT_KEY_OLLAMA variable with the keycap of your choice
(( ! ${+ZSH_COPILOT_KEY_OPENAI} )) && typeset -g ZSH_COPILOT_KEY_OPENAI='^z'
(( ! ${+ZSH_COPILOT_KEY_OLLAMA} )) && typeset -g ZSH_COPILOT_KEY_OLLAMA=''
(( ! ${+ZSH_COPILOT_SEND_CONTEXT} )) && typeset -g ZSH_COPILOT_SEND_CONTEXT=true
(( ! ${+ZSH_COPILOT_DEBUG} )) && typeset -g ZSH_COPILOT_DEBUG=false

# Define the system prompt
read -r -d '' SYSTEM_PROMPT <<- EOM
  You will be given the raw input of a shell command. 
  Your task is to either complete the command or provide a new command that you think the user is trying to type. 
  If you return a completely new command for the user, prefix it with an equal sign (=). 
  If you return a completion for the user's command, prefix it with a plus sign (+). 
  MAKE SURE TO ONLY INCLUDE THE REST OF THE COMPLETION!!! 
  Do not write any leading or trailing characters except if required for the completion to work. 
  Only respond with either a completion or a new command, not both. 
  Your response may only start with either a plus sign or an equal sign. 
  You MAY explain the command by writing a short line after the comment symbol (#). 
  Do not ask for more information, you won't receive it. 
  Your response will be run in the user's shell. 
  Make sure input is escaped correctly if needed. 
  Your input should be able to run without any modifications to it. 
  Do not return anything else other than a shell command! 
  DO NOT INTERACT WITH THE USER IN NATURAL LANGUAGE!
EOM

# Set system information based on the OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    SYSTEM="Your system is $(sw_vers | xargs | sed 's/ /./g')."
else 
    SYSTEM="Your system is $(cat /etc/*-release | xargs | sed 's/ /,/g')."
fi

# Unified function to trigger suggestions based on configuration (OpenAI or Ollama)
function _suggest_ai() {
    if [[ "$ZSH_COPILOT_SEND_CONTEXT" == 'true' ]]; then
        local PROMPT="$SYSTEM_PROMPT 
            Context: You are user $(whoami) with id $(id) in directory $(pwd). 
            Your shell is $(echo $SHELL) and your terminal is $(echo $TERM) running on $(uname -a).
            $SYSTEM"
    fi

    # Capture user input up to the cursor position
    local input=$(echo "${BUFFER:0:$CURSOR}" | tr '\n' ';')
    input=$(echo "$input" | sed 's/"/\\"/g')

    # Clear existing suggestions
    _zsh_autosuggest_clear
    zle -R "Thinking..."

    # Prepare prompt without line breaks
    PROMPT=$(echo "$PROMPT" | tr -d '\n')
    # Wasn't able to get this to work :(
    # if [[ "$ZSH_COPILOT_SEND_GIT_DIFF" == 'true' ]]; then
    #     if [[ $(git rev-parse --is-inside-work-tree) == 'true' ]]; then
    #         local git_diff=$(git diff --staged --no-color)
    #         local git_exit_code=$?
    #         git_diff=$(echo "$git_diff" | tr '\\' ' ' | sed 's/[\$\"\`]/\\&/g' | tr '\\' '\\\\' | tr -d '\n')
    #
    #         if [[ git_exit_code -eq 0 ]]; then
    #             PROMPT="$PROMPT; This is the git diff: <---->$git_diff<----> You may provide a git commit message if the user is trying to commit changes. You are an expert at committing changes, you don't give generic messages. You give the best commit messages"
    #         fi
    #     fi
    # fi

    # If Ollama is configured, use it; otherwise, fallback to OpenAI
    if [[ -n "$ZSH_COPILOT_KEY_OLLAMA" ]]; then
        zle -R "Thinking (Ollama)..."
        
        # Call Ollama using llama3 model
        local response=$(echo "$PROMPT $input" | ollama run llama3.1)
        local message=$(echo "$response" | jq -r '.response')
    else
        # Default to OpenAI if Ollama is not configured
        local data="{
                \"model\": \"gpt-4\",
                \"messages\": [
                    {
                        \"role\": \"system\",
                        \"content\": \"$PROMPT\"
                    },
                    {
                        \"role\": \"user\",
                        \"content\": \"$input\"
                    }
                ]
            }"
        
        local response=$(curl "https://${OPENAI_API_URL}/v1/chat/completions" \
            --silent \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $OPENAI_API_KEY" \
            -d "$data")
        local message=$(echo "$response" | jq -r '.choices[0].message.content')
    fi

    # Extract the first character and the rest of the suggestion
    local first_char=${message:0:1}
    local suggestion=${message:1:${#message}}

    # Debug logging if enabled
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        touch /tmp/zsh-copilot.log
        echo "$(date);INPUT:$input;RESPONSE:$response;FIRST_CHAR:$first_char;SUGGESTION:$suggestion" >> /tmp/zsh-copilot.log
    fi

    # Handle the response based on whether it starts with '=' or '+'
    if [[ "$first_char" == '=' ]]; then
        BUFFER=""
        CURSOR=0
        zle -U "$suggestion"
    elif [[ "$first_char" == '+' ]]; then
        _zsh_autosuggest_suggest "$suggestion"
    fi
}

# Main function to initialize ZSH Copilot
function zsh-copilot() {
    echo "ZSH Copilot is now active."
    echo ""
    echo "Activation key: $ZSH_COPILOT_KEY_OPENAI"
    echo ""
    echo "Configurations:"
    echo "    - ZSH_COPILOT_SEND_CONTEXT: $ZSH_COPILOT_SEND_CONTEXT (Send context information to the AI model)."
}

# Bind a single key for suggestions based on the AI model selected
zle -N _suggest_ai
bindkey '^z' _suggest_ai
