# zsh, oh-my-zsh
export ZSH=~/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
autoload -U compinit && compinit -u
setopt append_history
setopt auto_cd
setopt complete_aliases
setopt complete_in_word
# need for git stuff in prompt
setopt prompt_subst
zstyle ':completion:*:functions' ignored-patterns '_*'

# Git-infused prompt
ZSH_THEME_GIT_PROMPT_PREFIX="on %{$fg[magenta]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[green]%}!"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}?"
ZSH_THEME_GIT_PROMPT_CLEAN=""
export PROMPT='%1~ $(git_prompt_info)%(!.#.$) '
if [ $SSH_CONNECTION ]; then
    export PROMPT="(%n@%m) $PROMPT"
fi

# Aliases
# General linux
alias cd='cd -P'
alias cp='cp -Rv'
alias gdb='gdb --quiet'
alias grep='grep --color=always'
alias ll='ls -lA --color=always'
alias ls='ls --color=always'
alias make='make -j5'
alias mv='mv -v'
alias ps='ps --forest'
alias x='chmod +x'
# Tmux
alias tmux='tmux -2'
alias tat='tmux new -s `basename $PWD`'
alias ta='tmux attach -t'
# Python
alias sba='source bin/activate'
alias clean-py='find . -name \*.pyc -delete'
# Because I never remember to sudo
alias apt-get='sudo apt-get'
alias aptitude='sudo aptitude'
alias pkgcount='sudo dpkg --get-selections | wc -l'
alias ifconfig='sudo ifconfig'

# Various tools
bin() { echo "obase=2;$1" | bc }
# Adds gpg key; usage: apt-gpg KEY_HASH
apt-gpg() {
    gpg --keyserver pgpkeys.mit.edu --recv-key $1
    gpg -a --export $1 | sudo apt-key add -
}
# Recursively updates (git-fetch) every directory from current
# TODO: Only fetch directories with .git folder
fetch-recursive() {
    for x in `find ./ -maxdepth 1 -type d | sed -n '1!p' | sed 's/^...//'`; do echo "Updating: $x" && cd $x && git fetch; cd ..; done
}

# Environment variables
export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000
export MAILCHECK=0
export DISABLE_AUTO_TITLE=true

# load optional local settings
if [ -f ~/.zshlocal ]; then
    source ~/.zshlocal
fi
