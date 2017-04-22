setopt complete_in_word
setopt prompt_subst
setopt share_history
setopt hist_ignore_dups
setopt no_beep

autoload -Uz promptinit; promptinit -u
prompt grb

# Completion
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select=10
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|=* r:|=*' # case insensitive completion
zstyle ':completion:*:*:vim:*:*files' ignored-patterns '(*.class|*.out|*.o)' # ignore these files from vim completion
bindkey '^[[Z' reverse-menu-complete
bindkey '^R' history-incremental-search-backward
bindkey '^F' history-incremental-search-forward
compdef mosh=ssh # mosh completes like ssh
zstyle -e ':completion::*:*:*:hosts' hosts 'reply=(${=${${(f)"$(cat $HOME/.ssh/known_hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })' # ssh completion for hosts file

bindkey -e
bindkey '\e\e[C' forward-word
bindkey '\e\e[D' backward-word

# Aliases
alias cd='cd -P' # physical dir structure without sym links
alias cp='cp -Rv' # recursive and prints file names
alias gdb='gdb -q' # launch without license noise
alias grep='grep --color=always' # color even when piping into less
alias less='less -R' # fix non-ansi colors
alias ls='ls -lGhF --color=always' # long list, no groups, readable size, file type indicator, always color
alias mv='mv -v' # list files
alias ps='ps aux --forest' # pretty print w tree
alias r='bin/rails' # no system rails
alias rake='bin/rake' # no system rake
alias rspec='rspec --color spec'
alias sba='source bin/activate'
alias tmux='tmux -2 -u' # 256 colors, unicode
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias clbin="curl -F 'clbin=<-' https://clbin.com"
alias strings='strings -a'
alias vim='vim -p'
alias vi='vim'
alias gfortran="gfortran -O2  -fimplicit-none  -Wall  -Wline-truncation  -Wcharacter-truncation  -Wsurprising  -Waliasing -Wunused-parameter  -fwhole-file  -fcheck=all  -std=f2008  -pedantic  -fbacktrace"

# Linux specific
if [[ $(uname -s) == "Linux" ]];
then
    alias aptitude='sudo aptitude'
    alias apt-get='sudo apt-get'
    alias ifconfig='sudo ifconfig'
    alias open='xdg-open'
fi

# OSX specific
if [[ $(uname -s) == "Darwin" ]];
then
    unalias ps
    alias brew-update='brew update; brew upgrade; brew services cleanup; brew doctor; brew prune; brew cleanup'
    # recursive, preserve times, verbose, update (only if change time greater)
    alias sync-music='rsync -rtvu --delete "/Users/kirk/Music/iTunes/iTunes Media/Music/" /Volumes/xtc/Music/'
    alias md5sum='md5 -q'
    alias ls='ls -GlohF' # color, long, omit group, human sizes, file type symbols
fi

# Add tools to PATH
if [[ -d $HOME/tools ]];
then
  export PATH=$HOME/tools:$PATH
fi

# Add bin to PATH
if [[ -d $HOME/bin ]];
then
  export PATH=$HOME/bin:$PATH
fi

# Per-machine settings
if [[ -f $HOME/.zshlocal ]];
then
    source $HOME/.zshlocal
fi
