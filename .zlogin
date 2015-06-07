alias password='ruby ~/tools/password.rb -an'
alias r='bin/rails'
alias rspec='rspec --color spec'

# less colors
export CLICOLOR_FORCE=1

# rvm
if [[ -d ~/.rvm ]];
then
    export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
fi

if [[ $_system_name == "OSX" ]];
then
    unalias ps
    alias brew_update='brew update && brew upgrade --all && brew cleanup && brew services cleanup && brew doctor && brew linkapps && brew prune'

    # recursive, preserve times, verbose, update (only if change time greater)
    alias sync_music='rsync --iconv=utf8 -rtvu --delete "/Users/kirk/Music/iTunes/iTunes Media/Music/" /Volumes/xtc/Media'
fi
