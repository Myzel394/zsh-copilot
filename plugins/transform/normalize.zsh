#!/usr/bin/env zsh
# Normalize transform plugin for zsh-copilot
#
# Cleans up AI responses by:
# - Trimming whitespace
# - Removing surrounding quotes
# - Removing markdown code block markers
# - Stripping common AI prefixes

_zsh_copilot_transform_normalize() {
    local message="$1"

    # Trim leading/trailing whitespace
    message="${message#"${message%%[![:space:]]*}"}"
    message="${message%"${message##*[![:space:]]}"}"

    # Remove markdown code block markers (```bash, ```sh, ```, etc.)
    message="${message#\`\`\`*$'\n'}"
    message="${message%$'\n'\`\`\`}"
    message="${message#\`\`\`}"
    message="${message%\`\`\`}"

    # Remove single backticks wrapping the whole command
    if [[ "$message" == \`*\` ]]; then
        message="${message#\`}"
        message="${message%\`}"
    fi

    # Remove surrounding double quotes
    if [[ "$message" == \"*\" ]]; then
        message="${message#\"}"
        message="${message%\"}"
    fi

    # Remove surrounding single quotes
    if [[ "$message" == \'*\' ]]; then
        message="${message#\'}"
        message="${message%\'}"
    fi

    # Trim again after removals
    message="${message#"${message%%[![:space:]]*}"}"
    message="${message%"${message##*[![:space:]]}"}"

    echo "$message"
}
