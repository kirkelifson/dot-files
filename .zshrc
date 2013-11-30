# exec oh-my-zsh
ZSH=$HOME/.oh-my-zsh
source $ZSH/oh-my-zsh.sh

# load zsh extensions
autoload -U zutil
autoload -U colors && colors
plugins=(git)

# env
export PROMPT="%{$fg[cyan]%}%n:%m%{$reset_color%} [%~] %(!.#.λ) "
export PATH=$PATH:$HOME/.rvm/bin
export DISABLE_AUTO_TITLE=true
export LANG=en_US.UTF-8

# save a good amount of history
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000

# aliases
alias apt-get="sudo apt-get"
alias aptitude="sudo aptitude"
alias tmux="tmux -2"
alias ls="ls -lAvF --si --color=auto"
alias gdb="gdb --quiet"
