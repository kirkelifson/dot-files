autoload -U colors
autoload -U zutil
autoload -U compinit
autoload -U complist
colors && compinit

ZSH=$HOME/.oh-my-zsh
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000

# aliases
alias apt-get="sudo apt-get"
alias aptitude="sudo aptitude"
alias tmux="tmux -2"

source $ZSH/oh-my-zsh.sh

alias ls="ls -lAvF --si --color=auto"

plugins=(git)

PROMPT="%{$fg[green]%}%n%{$reset_color%} : %{$fg[cyan]%}%1~%{$reset_color%} %(!.#.$) "
RPROMPT="[%m]"

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
