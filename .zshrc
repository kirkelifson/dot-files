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
# General linux
alias cd='cd -P'
alias cp='cp -Rv'
alias gdb='gdb -q'
alias ls='ls -lAGhp'
# Linux specific
if [[ `uname -s` == "Linux" ]]; then
    alias ls='ls -lAGhp --color=always'
    # Because I never remember to sudo
    alias apt-get='sudo apt-get'
    alias aptitude='sudo aptitude'
    alias ifconfig='sudo ifconfig'
fi
alias mv='mv -v'
alias ps='ps --forest'
# Tmux
alias ta='tmux attach -t'
# Python
alias sba='source bin/activate'

# Various tools
# Convert to binary
bin() { echo "obase=2;$1" | bc }
# Adds gpg key; usage: apt-gpg KEY_HASH
apt-gpg() {
    gpg --keyserver pgpkeys.mit.edu --recv-key $1
    gpg -a --export $1 | sudo apt-key add -
}
# Recursively updates (git-fetch) every directory from current
git-fetch-recursive() {
    for x in `find ./ -name .git -type d`;
    do
        name=`echo $x | sed 's/[./]*//' | sed 's/\/.git//'`
        echo "Updating: $name" && (cd $x && git fa -p)
    done
}
# List contributors to git repo, # of commits (sorted)
git-contrib() {
    git log --format=%an | sort | uniq -c | sort -rk1
}

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
