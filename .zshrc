# Oh-my-zsh
ZSH=$HOME/.oh-my-zsh
source $ZSH/oh-my-zsh.sh

# [user@host ~pwd]$
PS1='[%n@%m %~]%(!.#.$) '

# Plugins
plugins=(git)

# environment variables
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/var/lib/gems/1.8/bin

# 256-color tmux by default
alias tmux="tmux -2"

# Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

# RVM
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
