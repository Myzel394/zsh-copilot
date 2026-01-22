**NOTICE**: I'm slowly migrating my repositories to my own Git server. Please visit this repository at [https://git.myzel394.app/Myzel394/zsh-copilot](https://git.myzel394.app/Myzel394/zsh-copilot) for the latest updates.

# zsh-copilot

Get suggestions **truly** in your shell. No `suggest` bullshit. Just press `CTRL + Z` and get your suggestion.

https://github.com/Myzel394/zsh-copilot/assets/50424412/ed2bc8ac-ce49-4012-ab73-53cf6f3151a2

## Installation

### Dependencies

Please make sure you have the following dependencies installed:

* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
* [jq](https://github.com/jqlang/jq)
* [curl](https://github.com/curl/curl)

### Oh My Zsh

1. Clone `zsh-copilot` into `$ZSH_CUSTOM/plugins` (by default ~/.config/oh-my-zsh/custom/plugins)

```sh
git clone https://git.myzel394.app/Myzel394/zsh-copilot ${ZSH_CUSTOM:-~/.config/oh-my-zsh/custom}/plugins/zsh-copilot
```

2. Add `zsh-copilot` to the plugins array in your `.zshrc` file:

```bash
plugins=( 
    # your other plugins...
    zsh-autosuggestions
)
```

### Manual Installation

```sh
git clone https://git.myzel394.app/Myzel394/zsh-copilot ~/.config/zsh-copilot
echo "source ~/.config/zsh-copilot/zsh-copilot.plugin.zsh" >> ~/.zshrc
```

## Configuration

### Setting up a Provider

zsh-copilot uses a plugin system for AI providers. You need to load a provider before using the plugin.

**Using OpenAI:**
```sh
export OPENAI_API_KEY=<your-openai-api-key>
zsh-copilot-load-provider openai
```

**Using Anthropic:**
```sh
export ANTHROPIC_API_KEY=<your-anthropic-api-key>
zsh-copilot-load-provider anthropic
```

Add these lines to your `.zshrc` after sourcing zsh-copilot.

You can also set the provider explicitly:
```sh
export ZSH_COPILOT_AI_PROVIDER="openai"  # or "anthropic"
```

### Other Options

- `ZSH_COPILOT_KEY`: Key to press to get suggestions (default: ^z)
- `ZSH_COPILOT_SEND_CONTEXT`: If `true`, zsh-copilot will send context information to the AI model (default: true)
- `ZSH_COPILOT_DEBUG`: Enable debug logging (default: false)
- `ZSH_COPILOT_PLUGINS_DIR`: Custom plugins directory (default: ~/.zsh-copilot/plugins)

To see all available configurations and their current values, run:

```sh
zsh-copilot
```

## Custom Providers

You can create your own AI provider by defining a function following this pattern:

```sh
# ~/.zsh-copilot/plugins/providers/ollama.zsh
_zsh_copilot_provider_ollama() {
    local input="$1"
    local system_prompt="$2"

    # Your implementation here...
    # Must write result to /tmp/zsh_copilot_suggestion
    # Must write errors to /tmp/.zsh_copilot_error
    # Return 0 on success, 1 on failure

    local response=$(curl http://localhost:11434/api/generate \
        --silent \
        -d "{\"model\": \"llama2\", \"prompt\": \"$system_prompt\n\nUser: $input\", \"stream\": false}" \
        | jq -r '.response')

    echo "$response" > /tmp/zsh_copilot_suggestion
}
```

Then set `ZSH_COPILOT_AI_PROVIDER=ollama` and your custom provider will be used.

Files in `~/.zsh-copilot/plugins/providers/` are automatically loaded.

## Usage

Type in your command or your message and press `CTRL + Z` to get your suggestion!

