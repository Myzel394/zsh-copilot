# zsh-copilot

Get suggestions **truly** in your shell. No `suggest` bullshit. Just press `CTRL + Z` and get your suggestion.

https://github.com/Myzel394/zsh-copilot/assets/50424412/ec8203b6-fe76-4071-bf8e-86c5fc790c39

## Installation

### Dependencies

Please make sure you have the following dependencies installed:

* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)

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

## Usage

Type in your command or your message and press `CTRL + Z` to get your suggestion!

