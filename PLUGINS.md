# Creating Plugins for zsh-copilot

zsh-copilot supports three types of plugins:

| Type | Purpose | Function Pattern |
|------|---------|------------------|
| **Provider** | AI backend (API calls) | `_zsh_copilot_provider_<name>` |
| **Context** | Add info to prompts | `_zsh_copilot_context_<name>` |
| **Transform** | Process AI responses | `_zsh_copilot_transform_<name>` |

## Provider Plugins

Provider plugins handle communication with AI backends.

### Interface

```zsh
_zsh_copilot_provider_<name>() {
    local input="$1"         # User's input (escaped)
    local system_prompt="$2" # System prompt + context

    # Make API call, parse response
    # Write result to /tmp/zsh_copilot_suggestion
    # Write errors to /tmp/.zsh_copilot_error
    # Return 0 on success, 1 on failure
}
```

### Example: Ollama Provider

```zsh
# ~/.config/zsh-copilot/plugins/providers/ollama.zsh

_zsh_copilot_provider_ollama() {
    local input="$1"
    local system_prompt="$2"
    local model=${OLLAMA_MODEL:-"llama2"}
    local url=${OLLAMA_URL:-"http://localhost:11434"}

    local data="{
        \"model\": \"$model\",
        \"prompt\": \"$system_prompt\n\nUser: $input\",
        \"stream\": false
    }"

    local response
    response=$(curl "$url/api/generate" \
        --silent \
        -H "Content-Type: application/json" \
        -d "$data")
    local response_code=$?

    if [[ $response_code -ne 0 ]]; then
        echo "Error connecting to Ollama at $url" > /tmp/.zsh_copilot_error
        return 1
    fi

    local message
    message=$(echo "$response" | jq -r '.response')

    if [[ -z "$message" || "$message" == "null" ]]; then
        echo "Empty response from Ollama" > /tmp/.zsh_copilot_error
        return 1
    fi

    echo "$message" > /tmp/zsh_copilot_suggestion
}
```

### Usage

```zsh
# In .zshrc
source ~/.config/zsh-copilot/plugins/providers/ollama.zsh
export ZSH_COPILOT_AI_PROVIDER="ollama"
```

---

## Context Plugins

Context plugins add information to the prompt sent to the AI. They chain together - each plugin receives the output of previous plugins.

### Interface

```zsh
_zsh_copilot_context_<name>() {
    local context="$1"  # Current context from previous plugins

    local my_info="..."

    # Append to existing context
    if [[ -n "$context" ]]; then
        echo "$context $my_info"
    else
        echo "$my_info"
    fi
}
```

### Example: Git Context

```zsh
# ~/.config/zsh-copilot/plugins/context/git.zsh

_zsh_copilot_context_git() {
    local context="$1"

    local git_info=""
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch=$(git branch --show-current 2>/dev/null)
        local status=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        git_info="Git repo on branch '$branch' with $status uncommitted changes."
    fi

    if [[ -n "$context" ]]; then
        echo "$context $git_info"
    else
        echo "$git_info"
    fi
}
```

### Example: Node.js Project Context

```zsh
# ~/.config/zsh-copilot/plugins/context/nodejs.zsh

_zsh_copilot_context_nodejs() {
    local context="$1"

    local node_info=""
    if [[ -f "package.json" ]]; then
        local name=$(jq -r '.name // empty' package.json 2>/dev/null)
        local pm="npm"
        [[ -f "yarn.lock" ]] && pm="yarn"
        [[ -f "pnpm-lock.yaml" ]] && pm="pnpm"
        [[ -f "bun.lockb" ]] && pm="bun"
        node_info="Node.js project${name:+ '$name'} using $pm."
    fi

    if [[ -n "$context" ]]; then
        echo "$context $node_info"
    else
        echo "$node_info"
    fi
}
```

---

## Transform Plugins

Transform plugins process the AI response before displaying it. They chain together.

### Interface

```zsh
_zsh_copilot_transform_<name>() {
    local message="$1"  # Current message (possibly from previous transforms)

    # Process message
    echo "$processed_message"
}
```

### Example: Strip Explanations

```zsh
# ~/.config/zsh-copilot/plugins/transform/strip-explanation.zsh

_zsh_copilot_transform_strip_explanation() {
    local message="$1"

    # Remove common AI prefixes
    message="${message#Here is the command: }"
    message="${message#The command is: }"
    message="${message#Try this: }"
    message="${message#Run: }"

    echo "$message"
}
```

### Example: Dangerous Command Warning

```zsh
# ~/.config/zsh-copilot/plugins/transform/warn-dangerous.zsh

_zsh_copilot_transform_warn_dangerous() {
    local message="$1"

    # Check for dangerous patterns
    if [[ "$message" == *"rm -rf"* ]] || \
       [[ "$message" == *"sudo rm"* ]] || \
       [[ "$message" == *"> /dev/"* ]]; then
        echo "# WARNING: Potentially dangerous command\n$message"
    else
        echo "$message"
    fi
}
```

---

## Plugin Loading

Plugins are loaded by sourcing them in your `.zshrc`:

```zsh
# Source zsh-copilot first
source ~/.config/zsh-copilot/zsh-copilot.plugin.zsh

# Then source plugins
source ~/.config/zsh-copilot/plugins/providers/openai.zsh
source ~/.config/zsh-copilot/plugins/context/system.zsh
source ~/.config/zsh-copilot/plugins/context/git.zsh
source ~/.config/zsh-copilot/plugins/transform/normalize.zsh
```

### Custom Plugin Directory

You can keep your custom plugins anywhere. A common pattern:

```zsh
# Custom plugins in ~/.zsh-copilot/plugins/
for plugin in ~/.zsh-copilot/plugins/**/*.zsh(N); do
    source "$plugin"
done
```

---

## Tips

1. **Keep plugins fast** - They run on every suggestion request
2. **Handle errors gracefully** - Don't break the shell if something fails
3. **Use `(N)` glob qualifier** - Prevents errors when no files match
4. **Test incrementally** - Source plugins manually before adding to `.zshrc`
5. **Check `$ZSH_COPILOT_DEBUG`** - Log debug info when enabled

```zsh
if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
    echo "{\"plugin\":\"my-plugin\",\"data\":\"...\"}" >> /tmp/zsh-copilot.log
fi
```
