ZSH=$HOME/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
plugins=(git)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/var/lib/gems/1.8/bin

alias tmux="tmux -2"

PS1='%(?.%F{green}.%F{red})%#%f '
RPS1='[%B%F{blue}%~%f%b]'
