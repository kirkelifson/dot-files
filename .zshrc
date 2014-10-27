# zsh, oh-my-zsh
export ZSH=~/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
autoload -U compinit && compinit -u
setopt append_history
setopt auto_cd
setopt complete_aliases
setopt complete_in_word
setopt prompt_subst
zstyle ':completion:*:functions' ignored-patterns '_*'

# prompt
ZSH_THEME_GIT_PROMPT_PREFIX="on %{$fg[magenta]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[green]%}!"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}?"
ZSH_THEME_GIT_PROMPT_CLEAN=""
export PROMPT='%1~ $(git_prompt_info)%(!.#.$) '
if [ $SSH_CONNECTION ]; then
    export PROMPT="%n:%m $PROMPT"
fi

# aliases
alias make='make -j5'
alias cd='cd -P'
alias cp='cp -Rv'
alias mv='mv -v'
alias tmux='tmux -2'
alias tat='tmux new -s `basename $PWD`'
alias ta='tmux attach -t'
alias ls='ls --color=always'
alias ll='ls -lA --color=always'
alias gdb='gdb --quiet'
alias grep='grep --color=always'
alias x='chmod +x'
alias sba='source bin/activate'
alias clean-py='find . -name \*.pyc -delete'
alias apt-get='sudo apt-get'
alias aptitude='sudo aptitude'
alias pkgcount='sudo dpkg --get-selections | wc -l'
alias dpkg='sudo dpkg'
alias ifconfig='sudo ifconfig'
# opens each file in a new tab
alias vim='vim -p'
bin() { echo "obase=2;$1" | bc }

# env
export DISABLE_AUTO_TITLE=true
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
MAILCHECK=0

# load optional local settings
if [ -f ~/.zshlocal ]; then
    source ~/.zshlocal
fi
