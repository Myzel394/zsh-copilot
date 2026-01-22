#!/usr/bin/env zsh
# Anthropic provider for zsh-copilot
#
# Required environment variables:
#   ANTHROPIC_API_KEY - Your Anthropic API key
#
# Optional environment variables:
#   ANTHROPIC_API_URL - Custom API URL (default: api.anthropic.com)

_zsh_copilot_provider_anthropic() {
    local input="$1"
    local system_prompt="$2"
    local anthropic_api_url=${ANTHROPIC_API_URL:-"api.anthropic.com"}

    local data="{
        \"model\": \"claude-3-haiku-20240307\",
        \"max_tokens\": 500,
        \"system\": \"$system_prompt\",
        \"messages\": [
            {
                \"role\": \"user\",
                \"content\": \"$input\"
            }
        ]
    }"

    local response
    response=$(curl "https://${anthropic_api_url}/v1/messages" \
        --silent \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "$data")
    local response_code=$?

    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        echo "{\"date\":\"$(date)\",\"log\":\"Called Anthropic API\",\"input\":\"$input\",\"response\":\"$response\",\"response_code\":\"$response_code\"}" >> /tmp/zsh-copilot.log
    fi

    if [[ $response_code -ne 0 ]] || [[ $(echo "$response" | jq -r '.type') == 'error' ]]; then
        if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
            echo "{\"date\":\"$(date)\",\"log\":\"Error fetching Anthropic\"}" >> /tmp/zsh-copilot.log
        fi

        echo "Error fetching suggestions from the Anthropic API. Please check your API key and try again." > /tmp/.zsh_copilot_error
        return 1
    fi

    local message
    message=$(echo "$response" | tr -d '\n' | jq -r '.content[0].text')

    echo "$message" > /tmp/zsh_copilot_suggestion || return 1
}
