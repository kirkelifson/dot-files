# ruby
alias r='bin/rails'
alias rake='bin/rake'
alias rspec='rspec --color spec'

# rvm
if [[ -d ~/.rvm ]];
then
    export PATH="$HOME/.rvm/bin:$PATH"
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
fi

# Linux specific
if [[ $(uname -s) == "Linux" ]]; then
    alias aptitude='sudo aptitude'
    alias apt-get='sudo apt-get'
    alias ifconfig='sudo ifconfig'
    alias ls='ls -lhp --color=always'
fi

if [[ $_system_name == "OSX" ]];
then
    unalias ps
    alias brew_update='brew update && brew upgrade --all && brew cleanup && brew services cleanup && brew doctor && brew linkapps && brew prune'

    # recursive, preserve times, verbose, update (only if change time greater)
    alias sync_music='rsync -rtvu --delete "/Users/kirk/Music/iTunes/iTunes Media/Music/" /Volumes/xtc-external/Media/Music/'
    alias md5sum='md5 -q'
fi
