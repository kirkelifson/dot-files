# aliases {{{

alias apt-get="sudo apt-get"
alias aptitude="sudo aptitude"
alias ifconfig="sudo ifconfig"
alias tmux="tmux -2"
alias ls="ls --color=always"
alias ll="ls -lA --color=always"
alias gdb="gdb --quiet"
alias grep="grep --color=always"
alias x="chmod +x"
alias ta="tmux attach -t"

# }}}

setopt AUTO_CD
setopt CORRECT
setopt completealiases
setopt append_history
setopt promptsubst
zstyle ':completion::complete:*' use-cache 1

autoload -U compinit && compinit

# load optional local settings
if [ -f ~/.zshlocal ]; then
    source ~/.zshlocal
fi

source $ZSH/oh-my-zsh.sh
