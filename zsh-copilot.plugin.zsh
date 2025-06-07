#!/usr/bin/env zsh

# Default key binding
(( ! ${+ZSH_COPILOT_KEY} )) &&
    typeset -g ZSH_COPILOT_KEY='^z'

# Configuration options
(( ! ${+ZSH_COPILOT_SEND_CONTEXT} )) &&
    typeset -g ZSH_COPILOT_SEND_CONTEXT=true

(( ! ${+ZSH_COPILOT_DEBUG} )) &&
    typeset -g ZSH_COPILOT_DEBUG=false

# New option to select AI provider
if [[ -z "$ZSH_COPILOT_AI_PROVIDER" ]]; then
    if [[ -n "$OPENAI_API_KEY" ]]; then
        typeset -g ZSH_COPILOT_AI_PROVIDER="openai"
    elif [[ -n "$ANTHROPIC_API_KEY" ]]; then
        typeset -g ZSH_COPILOT_AI_PROVIDER="anthropic"
    else
        echo "No AI provider selected. Please set either OPENAI_API_KEY or ANTHROPIC_API_KEY."
        return 1
    fi
fi

# System prompt
if [[ -z "$ZSH_COPILOT_SYSTEM_PROMPT" ]]; then
read -r -d '' ZSH_COPILOT_SYSTEM_PROMPT <<- EOM
  You will be given the raw input of a shell command. 
  Your task is to either complete the command or provide a new command that you think the user is trying to type. 
  If you return a completely new command for the user, prefix is with an equal sign (=). 
  If you return a completion for the user's command, prefix it with a plus sign (+). 
  MAKE SURE TO ONLY INCLUDE THE REST OF THE COMPLETION!!! 
  Do not write any leading or trailing characters except if required for the completion to work. 

  Only respond with either a completion or a new command, not both. 
  Your response may only start with either a plus sign or an equal sign.
  Your response MAY NOT start with both! This means that your response IS NOT ALLOWED to start with '+=' or '=+'.

  Your response MAY NOT contain any newlines!
  Do NOT add any additional text, comments, or explanations to your response.
  Do not ask for more information, you won't receive it. 

  Your response will be run in the user's shell. 
  Make sure input is escaped correctly if needed so. 
  Your input should be able to run without any modifications to it.
  DO NOT INTERACT WITH THE USER IN NATURAL LANGUAGE! If you do, you will be banned from the system. 
  Note that the double quote sign is escaped. Keep this in mind when you create quotes. 
  Here are two examples: 
    * User input: 'list files in current directory'; Your response: '=ls' (ls is the builtin command for listing files)
    * User input: 'cd /tm'; Your response: '+p' (/tmp is the standard temp folder on linux and mac).
EOM
fi

function _suggest_ai() {
    #### Prepare environment
    local openai_api_url=${OPENAI_API_URL:-"api.openai.com"}
    local anthropic_api_url=${ANTHROPIC_API_URL:-"api.anthropic.com"}

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
    local input=$(echo "${BUFFER:0:$CURSOR}" | tr '\n' ';')
    input=$(echo "$input" | sed 's/"/\\"/g')

    _zsh_autosuggest_clear
    zle -R "Thinking..."

    local full_prompt=$(echo "$ZSH_COPILOT_SYSTEM_PROMPT $context_info" | tr -d '\n')

    ##### Fetch message
    local data
    local response
    local message

    if [[ "$ZSH_COPILOT_AI_PROVIDER" == "openai" ]]; then
        # OpenAI's API payload
        data="{
            \"model\": \"gpt-4o-mini\",
            \"messages\": [
                {
                    \"role\": \"system\",
                    \"content\": \"$full_prompt\"
                },
                {
                    \"role\": \"user\",
                    \"content\": \"$input\"
                }
            ]
        }"
        response=$(curl "https://${openai_api_url}/v1/chat/completions" \
            --silent \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $OPENAI_API_KEY" \
            -d "$data")

        message=$(echo "$response" | tr -d '\n' | jq -r '.choices[0].message.content')
    elif [[ "$ZSH_COPILOT_AI_PROVIDER" == "anthropic" ]]; then
        # Anthropic's API payload
        data="{
            \"model\": \"claude-3-5-sonnet-latest\",
            \"max_tokens\": 1000,
            \"system\": \"$full_prompt\",
            \"messages\": [
                {
                    \"role\": \"user\",
                    \"content\": \"$input\"
                }
            ]
        }"
        response=$(curl "https://${anthropic_api_url}/v1/messages" \
            --silent \
            -H "Content-Type: application/json" \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "$data")

        message=$(echo "$response" | tr -d '\n' | jq -r '.content[0].text')
    else
        echo "Invalid AI provider selected. Please choose 'openai' or 'anthropic'."
        return 1
    fi

    ##### Process response

    local first_char=${message:0:1}
    local suggestion=${message:1:${#message}}
    
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        touch /tmp/zsh-copilot.log
        echo "$(date);INPUT:$input;RESPONSE:$response;FIRST_CHAR:$first_char;SUGGESTION:$suggestion:DATA:$data" >> /tmp/zsh-copilot.log
    fi

    ##### And now, let's actually show the suggestion to the user!

    if [[ "$first_char" == '=' ]]; then
        # Reset user input
        BUFFER=""
        CURSOR=0

        zle -U "$suggestion"
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
    echo "    - ZSH_COPILOT_AI_PROVIDER: AI provider to use ('openai' or 'anthropic', value: $ZSH_COPILOT_AI_PROVIDER)."
    echo "    - ZSH_COPILOT_SYSTEM_PROMPT: System prompt to use for the AI model (uses a built-in prompt by default)."
}

zle -N _suggest_ai
bindkey "$ZSH_COPILOT_KEY" _suggest_ai

