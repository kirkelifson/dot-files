# zshell options
setopt prompt_subst
setopt auto_cd

# Custom prompt
autoload -U promptinit
promptinit
prompt grb

# Completion
autoload -U compinit
compinit
zstyle ':completion:*' menu select=20
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
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000
export DISABLE_AUTO_TITLE=true
export EDITOR=vim
# Colors
export LSCOLORS="ExGxBxDxCxEgEdxbxgxcxd"
export GREP_OPTIONS="--color"

# Load optional local settings
if [ -f ~/.zshlocal ]; then
    source ~/.zshlocal
fi
