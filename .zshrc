# zshell options
setopt autocd
setopt complete_in_word
setopt correct
setopt menu_complete
setopt prompt_subst
setopt append_history
setopt no_beep

# Custom prompt
autoload -Uz promptinit && promptinit -u
prompt grb

# Completion
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select=10
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]} r:|[._-]=* r:|=*' 'l:|=* r:|=*'
bindkey '^[[Z' reverse-menu-complete
bindkey '^R' history-incremental-search-backward
bindkey '^F' history-incremental-search-forward
# Fix ssh tab completion
compdef mosh=ssh
zstyle -e ':completion::*:*:*:hosts' hosts 'reply=(${=${${(f)"$(cat ~/.ssh/known_hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# Aliases
alias cd='cd -P'
alias cp='cp -Rv'
alias gdb='gdb -q'
alias grep='grep --color=auto'
alias less='less -R'
alias ls='ls -lGhpF'
alias mv='mv -v'
alias ps='ps aux --forest'
alias sba='source bin/activate'
alias tmux='tmux -2 -u'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias clbin="curl -F 'clbin=<-' https://clbin.com"
alias strings='strings -a'

export EDITOR=vim
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000
export PATH=/usr/local/bin:$HOME/bin:$PATH
export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"

if [[ -f ~/.zshlocal ]]; then
    source ~/.zshlocal
fi
