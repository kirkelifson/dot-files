# exec oh-my-zsh
ZSH=$HOME/.oh-my-zsh
source $ZSH/oh-my-zsh.sh

# env
export PROMPT="%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[cyan]%}%~%{$reset_color%} %(!.#.λ) "
export PATH=$PATH:$HOME/.rvm/bin
export DISABLE_AUTO_TITLE=true
export LANG=en_US.UTF-8

# load zsh extensions
autoload -U colors
autoload -U zutil
autoload -U compinit
autoload -U complist
colors && compinit
plugins=(git)

# save a good amount of history
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000

# aliases
alias apt-get="sudo apt-get"
alias aptitude="sudo aptitude"
alias tmux="tmux -2"

# aliases
alias ls="ls -lAvF --si --color=auto"
