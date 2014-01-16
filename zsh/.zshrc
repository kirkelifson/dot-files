# load from dot-files directory (~/dot-files)
export DOT_FILES=~/dot-files
export ZSH=~/.oh-my-zsh

autoload -U colors && colors
autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh

# list of all zsh files
typeset -U config_files
config_files=($DOT_FILES/**/*.zsh)

# load everything except completion file
for file in ${${config_files:#*/path.zsh}:#*/completion.zsh}
do
    source $file
done

zstyle ':completion:*:*:kill:*:processes' command 'ps --forest -e -o pid,user,tty,cmd'

unset DOT_FILES
