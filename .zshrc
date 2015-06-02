# zshell options
setopt auto_cd
setopt completeinword
setopt correct
setopt extendedhistory
setopt menu_complete
setopt prompt_subst
setopt sharehistory

# Custom prompt
autoload -Uz promptinit && promptinit
prompt grb

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select=10
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]} r:|[._-]=* r:|=*' 'l:|=* r:|=*'
bindkey '^[[Z' reverse-menu-complete
bindkey '^R' history-incremental-search-backward
bindkey '^F' history-incremental-search-forward
# Fix ssh tab completion
compdef mosh=ssh
zstyle -e ':completion::*:*:*:hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# Aliases
alias cd='cd -P'
alias cp='cp -Rv'
alias gdb='gdb -q'
alias less='less -R'
alias ls='ls -lGhp'
alias mv='mv -v'
alias ps='ps --forest'
alias sba='source bin/activate'
alias ta='tmux attach -t'
alias clbin="curl -F 'clbin=<-' https://clbin.com"
alias strings='strings -a'
# Linux specific
if [[ $(uname -s) == "Linux" ]]; then
    alias aptitude='sudo aptitude'
    alias apt-get='sudo apt-get'
    alias ifconfig='sudo ifconfig'
    alias ls='ls -lhp --color=always'
fi

export DISABLE_AUTO_TITLE=true
export EDITOR=vim
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000
export PATH=$HOME/bin:$PATH
export GREP_OPTIONS="--color"
export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"
