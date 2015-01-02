# Completion
autoload -U compinit
compinit

# Custom prompt
setopt prompt_subst
autoload -U promptinit
promptinit
prompt grb

export PATH=$HOME/bin:/usr/local/sbin:/usr/local/bin:$PATH

setopt auto_cd
setopt complete_aliases
setopt complete_in_word

# Aliases
# General linux
alias cd='cd -P'
alias cp='cp -Rv'
alias gdb='gdb -q'
alias grep='grep --color=always'
alias ls='ls -lAG --color=always'
alias make='make -j5'
alias mv='mv -v'
alias ps='ps --forest'
# Tmux
alias ta='tmux attach -t'
# Python
alias sba='source bin/activate'
# Because I never remember to sudo
alias apt-get='sudo apt-get'
alias aptitude='sudo aptitude'
alias ifconfig='sudo ifconfig'

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
    for x in `find ./ -maxdepth 1 -type d | sed -n '1!p' | sed 's/^...//'`;
    do
        if [[ -d $x/.git ]]; then
            echo "Updating: $x" && (cd $x && git fetch)
        fi
    done
}

# Environment variables
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000
export MAILCHECK=0
export DISABLE_AUTO_TITLE=true

# Load optional local settings
if [ -f ~/.zshlocal ]; then
    source ~/.zshlocal
fi
