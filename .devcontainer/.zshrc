# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will load a random theme each time oh-my-zsh is loaded
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git aws)

source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"

# Aliases
alias ll='ls -al'