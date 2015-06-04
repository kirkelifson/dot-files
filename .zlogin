unalias ps
alias brew_update='brew update && brew upgrade --all && brew cleanup && brew services cleanup && brew doctor && brew linkapps && brew prune'
alias password='ruby ~/tools/password.rb -an'
alias r='bin/rails'
alias rspec='rspec --color spec'

# recursive, preserve times, verbose, update (only if change time greater)
alias sync_music='rsync --iconv=utf8 -rtvu --delete "/Users/kirk/Music/iTunes/iTunes Media/Music/" /Volumes/xtc/Media'

# less colors
export CLICOLOR_FORCE=1
