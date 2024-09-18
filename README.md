# zsh-copilot


Get suggestions **truly** in your shell. No `suggest` bullshit. Just press `CTRL + Z` and get your suggestion.

https://github.com/Myzel394/zsh-copilot/assets/50424412/ed2bc8ac-ce49-4012-ab73-53cf6f3151a2

## Installation

### Dependencies

Please make sure you have the following dependencies installed:

* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
* [jq](https://github.com/jqlang/jq)
* [curl](https://github.com/curl/curl)

```sh
git clone https://github.com/Myzel394/zsh-copilot.git ~/.zsh-copilot
echo "source ~/.zsh-copilot/zsh-copilot.plugin.zsh" >> ~/.zshrc
```

### Configuration

You need to have an API key for either OpenAI or Anthropic to use this plugin. Expose this via the appropriate environment variable:

For OpenAI (default):
```sh
export OPENAI_API_KEY=<your-openai-api-key>
```

For Anthropic:
```sh
export ANTHROPIC_API_KEY=<your-anthropic-api-key>
```

You can configure the AI provider using the `ZSH_COPILOT_AI_PROVIDER` variable:

```sh
export ZSH_COPILOT_AI_PROVIDER="openai"  # or "anthropic"
```

Other configuration options:

- `ZSH_COPILOT_KEY`: Key to press to get suggestions (default: ^z)
- `ZSH_COPILOT_SEND_CONTEXT`: If `true`, zsh-copilot will send context information to the AI model (default: true)
- `ZSH_COPILOT_DEBUG`: Enable debug logging (default: false)

To see all available configurations and their current values, run:

```sh
zsh-copilot
```

## Usage

Type in your command or your message and press `CTRL + Z` to get your suggestion!

