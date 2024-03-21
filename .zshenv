# History
export HISTFILE=$HOME/.zsh_history
export HISTSIZE=4096
export SAVEHIST=4096

# Locales
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# Various
export EDITOR=vim
export VISUAL=$EDITOR

# fzf + fd / quick fuzzy finder
export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Rails
export DISABLE_SPRING=1
