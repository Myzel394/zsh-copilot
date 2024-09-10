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

You need to have an OPENAI API key with access to `gpt-4` to use this plugin. Expose this via the `OPENAI_API_KEY` environment variable:

```sh
export OPENAI_API_KEY=<your-api-key>
```

I tried out using `gpt-3` but the results were garbage.

To see available configurations, run:

```sh
zsh-copilot --help
```

## Usage

Type in your command or your message and press `CTRL + Z` to get your suggestion!

## Ollama Llama3 usage

### Configuration

You need to have Ollama and llama3 installed : 

```sh
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl start ollama
ollama pull llama3.1
```

### Set Ollama active

Modify the **zsh-copilot.plugin.zsh** file to set the keycap of your choice like this : 
```sh
(( ! ${+ZSH_COPILOT_KEY_OPENAI} )) && typeset -g ZSH_COPILOT_KEY_OPENAI=''
(( ! ${+ZSH_COPILOT_KEY_OLLAMA} )) && typeset -g ZSH_COPILOT_KEY_OLLAMA='^z'
```