# load zsh extensions
ZSH=$HOME/.oh-my-zsh

autoload -U compinit && compinit
autoload colors && colors
plugins=(git)

source $ZSH/oh-my-zsh.sh
