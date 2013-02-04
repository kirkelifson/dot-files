ZSH=$HOME/.oh-my-zsh

ZSH_THEME="fishy"

# load aliases only if script is found
if [ -f ~/.aliases.sh ]; then
    $ZSH/aliases.sh
fi

plugins=(git ruby pip)

source $ZSH/oh-my-zsh.sh
