(( ! ${+ZSH_COPILOT_KEY_OPENAI} )) &&
    typeset -g ZSH_COPILOT_KEY_OPENAI='^z'

(( ! ${+ZSH_COPILOT_KEY_OLLAMA} )) &&
    typeset -g ZSH_COPILOT_KEY_OLLAMA='^e'

(( ! ${+ZSH_COPILOT_SEND_CONTEXT} )) &&
    typeset -g ZSH_COPILOT_SEND_CONTEXT=true

(( ! ${+ZSH_COPILOT_DEBUG} )) &&
    typeset -g ZSH_COPILOT_DEBUG=false

read -r -d '' SYSTEM_PROMPT <<- EOM
  You will be given the raw input of a shell command. 
  Your task is to either complete the command or provide a new command that you think the user is trying to type. 
  If you return a completely new command for the user, prefix it with an equal sign (=). 
  If you return a completion for the user's command, prefix it with a plus sign (+). 
  MAKE SURE TO ONLY INCLUDE THE REST OF THE COMPLETION!!! 
  Do not write any leading or trailing characters except if required for the completion to work. 
  Only respond with either a completion or a new command, not both. 
  Your response may only start with either a plus sign or an equal sign.
  You MAY NOT start with both! This means that your response IS NOT ALLOWED to start with '+=' or '=+'.
  You MAY explain the command by writing a short line after the comment symbol (#).
  Do not ask for more information, you won't receive it. 
  Your response will be run in the user's shell. 
  Make sure input is escaped correctly if needed so. 
  Your input should be able to run without any modifications to it.
  Don't you dare return anything else other than a shell command!!! 
  DO NOT INTERACT WITH THE USER IN NATURAL LANGUAGE! If you do, you will be banned from the system. 
  Note that the double quote sign is escaped. Keep this in mind when you create quotes. 
  Here are two examples: 
    * User input: 'list files in current directory'; Your response: '=ls # ls is the builtin command for listing files' 
    * User input: 'cd /tm'; Your response: '+p # /tmp is the standard temp folder on linux and mac'.
EOM

if [[ "$OSTYPE" == "darwin"* ]]; then
    SYSTEM="Your system is ${$(sw_vers | xargs | sed 's/ /./g')}."
else 
    SYSTEM="Your system is ${$(cat /etc/*-release | xargs | sed 's/ /,/g')}."
fi

# Function for activation via OpenAI (triggered by ^z)
function _suggest_ai_openai() {
    if [[ "$ZSH_COPILOT_SEND_CONTEXT" == 'true' ]]; then
        local PROMPT="$SYSTEM_PROMPT 
            Context: You are user $(whoami) with id $(id) in directory $(pwd). 
            Your shell is $(echo $SHELL) and your terminal is $(echo $TERM) running on $(uname -a).
            $SYSTEM"
    fi

    # Get input
    local input=$(echo "${BUFFER:0:$CURSOR}" | tr '\n' ';')
    input=$(echo "$input" | sed 's/"/\\"/g')

    _zsh_autosuggest_clear
    zle -R "Thinking..."

    PROMPT=$(echo "$PROMPT" | tr -d '\n')

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
        -d $data)

    local message=$(echo "$response" | jq -r '.choices[0].message.content')

    local first_char=${message:0:1}
    local suggestion=${message:1:${#message}}

    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        touch /tmp/zsh-copilot.log
        echo "$(date);INPUT:$input;RESPONSE:$response;FIRST_CHAR:$first_char;SUGGESTION:$suggestion:DATA:$data" >> /tmp/zsh-copilot.log
    fi

    if [[ "$first_char" == '=' ]]; then
        BUFFER=""
        CURSOR=0
        zle -U "$suggestion"
    elif [[ "$first_char" == '+' ]]; then
        _zsh_autosuggest_suggest "$suggestion"
    fi
}

# Function for activation via Ollama (triggered by ^e)
function _suggest_ai_ollama() {
    if [[ "$ZSH_COPILOT_SEND_CONTEXT" == 'true' ]]; then
        local PROMPT="$SYSTEM_PROMPT 
            Context: You are user $(whoami) with id $(id) in directory $(pwd). 
            Your shell is $(echo $SHELL) and your terminal is $(echo $TERM) running on $(uname -a).
            $SYSTEM"
    fi

    local input=$(echo "${BUFFER:0:$CURSOR}" | tr '\n' ';')
    input=$(echo "$input" | sed 's/"/\\"/g')

    _zsh_autosuggest_clear
    zle -R "Thinking (Ollama)..."

    PROMPT=$(echo "$PROMPT" | tr -d '\n')

    # Call to Ollama using the llama3 model
    local response=$(echo "$PROMPT $input" | ollama run llama3)
    local message=$(echo "$response" | jq -r '.response')

    local first_char=${message:0:1}
    local suggestion=${message:1:${#message}}

    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        touch /tmp/zsh-copilot.log
        echo "$(date);INPUT:$input;RESPONSE:$response;FIRST_CHAR:$first_char;SUGGESTION:$suggestion" >> /tmp/zsh-copilot.log
    fi

    if [[ "$first_char" == '=' ]]; then
        BUFFER=""
        CURSOR=0
        zle -U "$suggestion"
    elif [[ "$first_char" == '+' ]]; then
        _zsh_autosuggest_suggest "$suggestion"
    fi
}

# Main function to initialize keys and parameters
function zsh-copilot() {
    echo "ZSH Copilot is now active."
    echo ""
    echo "Activation keys:"
    echo "    - OpenAI: $ZSH_COPILOT_KEY_OPENAI"
    echo "    - Ollama (llama3): $ZSH_COPILOT_KEY_OLLAMA"
    echo ""
    echo "Configurations:"
    echo "    - ZSH_COPILOT_SEND_CONTEXT: Send context information (whoami, shell, pwd, etc.) to the AI model."
}

# Bind the keys for each model
zle -N _suggest_ai_openai
zle -N _suggest_ai_ollama
bindkey $ZSH_COPILOT_KEY_OPENAI _suggest_ai_openai
bindkey $ZSH_COPILOT_KEY_OLLAMA _suggest_ai_ollama
