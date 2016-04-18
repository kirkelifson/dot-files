# zsh options
setopt autocd
setopt complete_in_word
setopt correct
setopt menu_complete
setopt prompt_subst
setopt share_history
setopt hist_ignore_dups
setopt no_beep

# Custom prompt
autoload -Uz promptinit && promptinit -u
prompt grb

# Completion
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select=10
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|=* r:|=*'
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
alias r='bin/rails'
alias rake='bin/rake'
alias rspec='rspec --color spec'
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

# Linux specific
if [[ $(uname -s) == "Linux" ]];
then
    alias aptitude='sudo aptitude'
    alias apt-get='sudo apt-get'
    alias ifconfig='sudo ifconfig'
    alias ls='ls -lhp --color=always'
fi

# OSX specific
if [[ $(uname -s) == "Darwin" ]];
then
    unalias ps
    alias brew_update='brew update && brew upgrade --all && brew services cleanup && brew doctor && brew linkapps && brew cleanup && brew prune'

    # recursive, preserve times, verbose, update (only if change time greater)
    alias sync_music='rsync -rtvu --delete "/Users/kirk/Music/iTunes/iTunes Media/Music/" /Volumes/xtc-external/Media/Music/'
    alias md5sum='md5 -q'

    # OPAM (OCaml)
    . /Users/kirk/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true
fi

# Per-machine settings
if [[ -f ~/.zshlocal ]];
then
    source ~/.zshlocal
fi
