# zshell options
setopt auto_cd
setopt completeinword
setopt correct
setopt extendedhistory
setopt prompt_subst
setopt sharehistory

# Custom prompt
autoload -Uz promptinit
promptinit
prompt grb

# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]} r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# Fix ssh tab completion (not sure what the problem is)
if [[ -f ~/.ssh/known_hosts ]];
then
    knownhosts=(${${${${(f)"$( < ~/.ssh/known_hosts )"}:#[0-9]*}%%\ *}%%,*})
    zstyle ':completion:*:(ssh|scp|sftp):*' hosts $knownhosts
fi

# Aliases
alias cd='cd -P'
alias cp='cp -Rv'
alias gdb='gdb -q'
alias less='less -r'
alias ls='ls -lAGhp'
alias mv='mv -v'
alias ps='ps --forest'
alias sba='source bin/activate'
alias ta='tmux attach -t'
# Linux specific
if [[ `uname -s` == "Linux" ]]; then
    alias aptitude='sudo aptitude'
    alias apt-get='sudo apt-get'
    alias ifconfig='sudo ifconfig'
    alias ls='ls -lAGhp --color=always'
fi

# Environment variables
export DISABLE_AUTO_TITLE=true
export EDITOR=vim
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export PATH=$HOME/bin:$PATH
export SAVEHIST=1000000
# Colors
export GREP_OPTIONS="--color"
export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"

# Load optional local settings
if [ -f ~/.zshlocal ]; then
    source ~/.zshlocal
fi
