autoload -U colors && colors

ZSH=$HOME/.oh-my-zsh

# aliases
alias apt-get="sudo apt-get"
alias aptitude="sudo aptitude"
alias tmux="tmux -2"

plugins=(git)

source $ZSH/oh-my-zsh.sh

PROMPT="%{$fg[green]%}%n%{$reset_color%} : %{$fg[cyan]%}%1~%{$reset_color%} %(!.#.λ) "

# rvm
export PATH=$PATH:/home/xtc/.rvm/gems/ruby-1.9.3-p392/bin:/home/xtc/.rvm/gems/ruby-1.9.3-p392@global/bin:/home/xtc/.rvm/rubies/ruby-1.9.3-p392/bin:/home/xtc/.rvm/bin:/usr/local/bin:/usr/bin:/bin:/usr/bin/X11:/usr/games:/home/xtc/.rvm/bin
