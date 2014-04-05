# load from dot-files directory (~/dot-files)
DOT_FILES=~/dot-files
ZSH=~/.oh-my-zsh

autoload -U colors && colors
autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh

# list of all zsh files
typeset -U config_files
config_files=($DOT_FILES/**/*.zsh)

# load all configurating files
for file in ${${config_files:#*/path.zsh}:#*/completion.zsh}
do
    source $file
done

# load in local settings
if [ -f ~/.zshlocal ];
then
    source ~/.zshlocal
fi
