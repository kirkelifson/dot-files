ZSH=$HOME/.oh-my-zsh

ZSH_THEME="fishy"

# load aliases only if script is found
if [ -f $ZSH/.zsh_aliases ]; then
    $ZSH/.zsh_aliases
fi

plugins=(git ruby pip)

source $ZSH/oh-my-zsh.sh

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
