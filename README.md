**NOTICE**: I'm slowly migrating my repositories to my own Git server. Please visit this repository at [https://git.myzel394.app/Myzel394/zsh-copilot](https://git.myzel394.app/Myzel394/zsh-copilot) for the latest updates.

# zsh-copilot

Get suggestions **truly** in your shell. No `suggest` bullshit. Just press `CTRL + Z` and get your suggestion.

https://github.com/Myzel394/zsh-copilot/assets/50424412/ed2bc8ac-ce49-4012-ab73-53cf6f3151a2

## Installation

### Dependencies

* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
* [jq](https://github.com/jqlang/jq)
* [curl](https://github.com/curl/curl)

### Recommended Installation

It's highly recommended to git clone zsh-copilot into `~/.config/zsh-copilot`. zsh-copilot uses a plugin system and this makes it easy to load the built-in plugins.

```sh
git clone https://git.myzel394.app/Myzel394/zsh-copilot ~/.config/zsh-copilot
```

Add to your `.zshrc`:
```sh
source ~/.config/zsh-copilot/zsh-copilot.plugin.zsh
```

### Oh My Zsh

```sh
git clone https://git.myzel394.app/Myzel394/zsh-copilot ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-copilot
```

Add `zsh-copilot` to the plugins array in your `.zshrc`.

## Configuration

### Loading a Provider

You need to source a provider plugin. Add one of these to your `.zshrc` after sourcing zsh-copilot:

**OpenAI:**
```sh
export OPENAI_API_KEY=<your-api-key>
source ~/.config/zsh-copilot/plugins/providers/openai.zsh
```

**Anthropic:**
```sh
export ANTHROPIC_API_KEY=<your-api-key>
source ~/.config/zsh-copilot/plugins/providers/anthropic.zsh
```

### Loading Plugins

Source the plugins you want:

```sh
# Provider (required - pick one)
source ~/.config/zsh-copilot/plugins/providers/openai.zsh

# Context plugins (optional - adds info to prompts)
source ~/.config/zsh-copilot/plugins/context/system.zsh

# Transform plugins (optional - processes AI responses)
source ~/.config/zsh-copilot/plugins/transform/normalize.zsh
```

### Built-in Plugins

Take a look at the [plugins directory](./plugins) for built-in plugins.

| Type | Plugin | Description |
|------|--------|-------------|
| Provider | `openai` | OpenAI API (gpt-4o-mini) |
| Provider | `anthropic` | Anthropic API (claude-3-haiku) |
| Context | `system` | Adds user, shell, terminal, OS info |
| Transform | `normalize` | Trims whitespace, removes quotes/code blocks |

### Options

| Variable | Default | Description |
|----------|---------|-------------|
| `ZSH_COPILOT_KEY` | `^z` | Key binding for suggestions |
| `ZSH_COPILOT_SEND_CONTEXT` | `true` | Send context info to AI |
| `ZSH_COPILOT_DEBUG` | `false` | Enable debug logging |

Run `zsh-copilot` to see current configuration.

## Usage

Type your command or message and press `CTRL + Z` to get a suggestion.

## Creating Custom Plugins

See [PLUGINS.md](PLUGINS.md) for documentation on creating your own providers, context plugins, and transform plugins.
