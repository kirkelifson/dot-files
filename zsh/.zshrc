# load zsh extensions
ZSH=$HOME/.oh-my-zsh

autoload -U compinit && compinit
autoload -U colors && colors
plugins=(git)

source $ZSH/oh-my-zsh.sh

# prompt
export PROMPT="%{$fg[cyan]%}%n:%m%{$reset_color%} [%~] %(!.#.λ) "

# aliases
alias apt-get="sudo apt-get"
alias aptitude="sudo aptitude"
alias tmux="tmux -2"
alias ls="ls -lAvF --si --color=auto"
alias gdb="gdb --quiet"
