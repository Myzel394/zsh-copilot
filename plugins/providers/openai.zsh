#!/usr/bin/env zsh
# OpenAI provider for zsh-copilot
#
# Required environment variables:
#   OPENAI_API_KEY - Your OpenAI API key
#
# Optional environment variables:
#   OPENAI_API_URL - Custom API URL (default: api.openai.com)

_zsh_copilot_provider_openai() {
    local input="$1"
    local system_prompt="$2"
    local openai_api_url=${OPENAI_API_URL:-"api.openai.com"}

    local data="{
        \"model\": \"gpt-4o-mini\",
        \"messages\": [
            {
                \"role\": \"system\",
                \"content\": \"$system_prompt\"
            },
            {
                \"role\": \"user\",
                \"content\": \"$input\"
            }
        ]
    }"

    local response
    response=$(curl "https://${openai_api_url}/v1/chat/completions" \
        --silent \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$data")
    local response_code=$?

    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Called OpenAI API\",\"input\":\"$input\",\"response\":\"$response\",\"response_code\":\"$response_code\"}" >> /tmp/zsh-copilot.log
    fi

    if [[ $response_code -ne 0 ]]; then
        echo "Error fetching suggestions from the OpenAI API. Please check your API key and try again." > /tmp/.zsh_copilot_error
        return 1
    fi

    local message
    message=$(echo "$response" | tr -d '\n' | jq -r '.choices[0].message.content')

    echo "$message" > /tmp/zsh_copilot_suggestion || return 1
}
