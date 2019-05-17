# Prompt
fpath=($fpath ~/.zsh/func)
typeset -U fpath
autoload -Uz promptinit; promptinit -u
prompt grb
setopt prompt_subst

# History
setopt share_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_verify
setopt hist_ignore_dups
setopt inc_append_history

# Completion
autoload -Uz compinit && compinit -u
setopt complete_in_word
setopt always_to_end
zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'
zstyle ':completion:*' completer _complete
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' '+l:|=* r:|=*' # case insensitive completion
zstyle ':completion:*:*:vim:*:*files' ignored-patterns '(*.class|*.out|*.o)' # ignore these files from vim completion
bindkey '^[[Z' reverse-menu-complete
bindkey '^R' history-incremental-search-backward
bindkey '^F' history-incremental-search-forward
compdef mosh=ssh # mosh completes like ssh
zstyle -e ':completion::*:*:*:hosts' hosts 'reply=(${=${${(f)"$(cat $HOME/.ssh/known_hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })' # ssh completion for hosts file

# Various
setopt no_beep
disable r # r is a built-in for replaying command, use !!

bindkey -e
bindkey '\e\e[C' forward-word
bindkey '\e\e[D' backward-word

# Aliases
alias cats='highlight -O ansi --force'
alias clbin="curl -F 'clbin=<-' https://clbin.com"
alias cp='cp -Rv' # recursive and prints file names
alias egrep='egrep --color -n'
alias gdb='gdb -q' # launch without license noise
alias grep='grep --color -n'
alias less='less -R' # fix non-ansi colors
alias ls='ls -lGhF --color=always' # long list, no groups, readable size, file type indicator, always color
alias mv='mv -v' # list files
alias ps='ps aux --forest' # pretty print w tree
if [[ -d /Applications/RubyMine.app ]];
then
  alias rubymine='/Applications/RubyMine.app/Contents/MacOS/rubymine'
fi
alias search='grep --color -R -C3 -n' # color even when piping into less
alias strings='strings -a'
alias vi='vim -p'
alias vim='vim -p'
# tmux
alias ta='tmux -2 -u attach -t'
alias tmux='tmux -2 -u'
alias tn='tmux -2 -u new -s'
# Python
alias sba='source bin/activate'
# Javascript
alias jsc="env NODE_NO_READLINE=1 rlwrap node"

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
  alias brew-update='brew update; brew upgrade; brew services cleanup; brew doctor; brew cleanup'
  # recursive, preserve times, verbose, update (only if change time greater)
  alias sync-music='rsync -rtvu --delete "/Users/kirk/Music/iTunes/iTunes Media/Music/" /Volumes/xtc/media/Music/'
  alias md5sum='md5 -q'
  alias ls='ls -GlohF' # color, long, omit group, human sizes, file type symbols
fi

# Add tools to PATH
if [[ -z $TMUX && -d $HOME/tools ]];
then
  export PATH=$HOME/tools:$PATH
fi

# Add bin to PATH
if [[ -z $TMUX && -d $HOME/bin ]];
then
  export PATH=$HOME/bin:$PATH
fi

# Add homebrew curl to PATH
if [[ -z $TMUX && -d /usr/local/opt/curl/bin ]];
then
  export PATH=/usr/local/opt/curl/bin:$PATH
fi

# Add homebrew sbin to PATH
if [[ -z $TMUX && -d /usr/local/sbin ]];
then
  export PATH=/usr/local/sbin:$PATH
fi

# Per-machine settings
if [[ -z $TMUX && -f $HOME/.zshlocal ]];
then
  source $HOME/.zshlocal
fi

# rvm
if [[ -d $HOME/.rvm ]];
then
  if [[ -z $TMUX ]];
  then
    export PATH="$HOME/.rvm/bin:$PATH"
  fi

  source "$HOME/.rvm/scripts/rvm"
fi

# fuzzy finder
if [[ -f ~/.fzf.zsh ]];
then
  source ~/.fzf.zsh
fi
