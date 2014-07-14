export ZSH=~/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
autoload -U compinit && compinit -u

ZSH_THEME_GIT_PROMPT_PREFIX="on %{$fg[magenta]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[green]%}!"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}?"
ZSH_THEME_GIT_PROMPT_CLEAN=""

export PROMPT='%1~ $(git_prompt_info)%(!.#.$) '

if [ $SSH_CONNECTION ]; then
    export PROMPT="%n:%m $PROMPT"
fi

# aliases {{{

# utilize all of my cores
alias make='make -j5'
alias cd='cd -P'
# recursive and verbose
alias cp='cp -Rv'
alias tmux='tmux -2'
alias ta='tmux attach -t'
alias ls='ls --color=always'
alias ll='ls -lA --color=always'
alias gdb='gdb --quiet'
alias grep='grep --color=always'
alias x='chmod +x'
alias sba='source bin/activate'
# always forget to add sudo
alias apt-get='sudo apt-get'
alias aptitude='sudo aptitude'
alias ifconfig='sudo ifconfig'

# }}}

setopt append_history
setopt auto_cd
setopt complete_aliases
setopt complete_in_word
setopt prompt_subst

zstyle ':completion:*:functions' ignored-patterns '_*'

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
MAILCHECK=0

# env
export PATH=$PATH:$HOME/.rvm/bin
export DISABLE_AUTO_TITLE=true

# load optional local settings
if [ -f ~/.zshlocal ]; then
    source ~/.zshlocal
fi
