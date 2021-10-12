setopt prompt_subst
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats "(%b)"
autoload -Uz promptinit; promptinit -u
precmd() {
  vcs_info
}

RPROMPT=
PROMPT='%B%F{44}%m%f%b %B%F{240}%2~%f%b %B%F{216}${vcs_info_msg_0_}%f%b %# '

# History
setopt hist_ignore_all_dups
setopt inc_append_history

# Completion

fpath=(~/.zsh/completion /usr/local/share/zsh/site-functions $fpath)
autoload -Uz compinit
if [[ -n $HOME/.zcompdump(#qN.mh+72) ]]; then # use cache if updated within 72h
  compinit -d $HOME/.zcompdump;
else
  compinit -C;
fi

setopt nobanghist # allow unescaped ! in arguments

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' # case-insensitive completion
zstyle ':completion:*:*:vim:*:*files' ignored-patterns '(*.class|*.out|*.o)' # ignore these files from vim completion
zstyle -e ':completion::*:*:*:hosts' hosts 'reply=(${=${${(f)"$(cat $HOME/.ssh/known_hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })' # ssh completion for hosts file
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix
zstyle ':completion:*:*:git:*' script ~/.zsh/completion/bash/git-completion.bash
bindkey '^[[Z' reverse-menu-complete
bindkey '^R' history-incremental-search-backward
bindkey '^F' history-incremental-search-forward
compdef mosh=ssh # mosh completes like ssh

# Various
setopt autocd autopushd pushdminus pushdsilent pushdtohome cdablevars
DIRSTACKSIZE=5
setopt extendedglob
unsetopt nomatch # allow [, ]
disable r # r is a built-in for replaying command, use !!

bindkey -e
bindkey '\e\e[C' forward-word
bindkey '\e\e[D' backward-word

# Aliases
alias be='bundle exec'
alias cats='highlight -O ansi --force'
alias clbin="curl -F 'clbin=<-' https://clbin.com"
alias cp='cp -Rv' # recursive and prints file names
alias egrep='egrep --color -n'
alias fetch-all='for i in `/bin/ls`; do cd $i; echo "Fetching and pruning $i"; git fap -q; cd ..; done'
alias gdb='gdb -q' # launch without license noise
alias grep='grep --color -n'
alias less='less -R' # fix non-ansi colors
alias ls='ls -lGhF --color=always' # long list, no groups, readable size, file type indicator, always color
alias mv='mv -v' # list files
alias ps='ps aux --forest' # pretty print w tree
alias pull-all='for i in `/bin/ls`; do cd $i; echo "Pulling $i"; git pull -q; cd ..; done'
alias search='grep --color -R -C3 -n' # color even when piping into less
alias strings='strings -a'
alias vi='vim -p'
alias vim='vim -p'
# tmux
alias ta='tmux -2 -u attach -t'
alias tmux='tmux -2 -u'
# Python
alias python='python3'
alias pip='pip3'
alias sba='source bin/activate'
# Javascript
alias jsc="env NODE_NO_READLINE=1 rlwrap node"

# Linux specific
if [[ $(uname -s) == "Linux" ]];
then
  alias apt='sudo apt'
  alias aptitude='sudo aptitude'
  alias apt-get='sudo apt-get'
  alias ifconfig='sudo ifconfig'
  alias open='xdg-open'
fi

# OSX specific
if [[ $(uname -s) == "Darwin" ]];
then
  unalias ps
  alias brew-restart='brew services restart'
  alias brew-start='brew services start'
  alias brew-stop='brew services stop'
  alias brew-update='brew update; brew upgrade; brew services cleanup; brew doctor; brew cleanup'
  # recursive, preserve times, verbose, update (only if change time greater)
  alias sync-music='rsync -rtvu --delete "/Users/kirk/Music/iTunes/iTunes Media/Music/" /Volumes/xtc/media/Music/'
  alias md5sum='md5 -q'
  alias ls='ls -Goh' # colorized, user but no group info, human readable file sizes

  # vscode
  if [[ -d "/Applications/Visual Studio Code.app" ]];
  then
    export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
  fi
fi

# Add bin to PATH
if [[ -z $TMUX && -d $HOME/bin ]];
then
  export PATH=$HOME/bin:$PATH
fi

# Add homebrew sbin to PATH
if [[ -z $TMUX && -d /usr/local/sbin ]];
then
  export PATH=/usr/local/sbin:$PATH
fi

# Add homebrew curl to PATH
if [[ -z $TMUX && -d /usr/local/opt/curl/bin ]];
then
  export PATH=/usr/local/opt/curl/bin:$PATH
fi

# fuzzy finder
if [[ -f ~/.fzf.zsh ]];
then
  source ~/.fzf.zsh
fi

# nvm
if [[ -d ~/.nvm ]];
then
  export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
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
