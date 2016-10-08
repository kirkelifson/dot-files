# rvm
if [[ -d $HOME/.rvm ]];
then
    export PATH="$HOME/.rvm/bin:$PATH"
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
fi
