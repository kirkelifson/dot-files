# Fish configuration

# Environment variables
set -gx EDITOR vim
set -gx VISUAL $EDITOR
set -gx BUNDLER_EDITOR code
set -gx PS_FORMAT "pid,user:20,cmd:200,etime,pcpu,rss"

# Locale
set -gx LC_ALL en_US.UTF-8
set -gx LANG en_US.UTF-8
set -gx LANGUAGE en_US.UTF-8

# fzf + fd
set -gx FZF_DEFAULT_COMMAND 'fd --type f'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"

# Disable greeting
set -g fish_greeting

# Detect platform once
set -l os (uname -s)

# --- PATH Management ---

# Common paths
fish_add_path $HOME/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.bun/bin
fish_add_path $HOME/.docker/bin

# Homebrew (macOS only)
if test "$os" = Darwin
    fish_add_path /opt/homebrew/bin /opt/homebrew/sbin
    fish_add_path /opt/homebrew/opt/openjdk/bin
    fish_add_path "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
end

fish_add_path $HOME/.opencode/bin
fish_add_path -a $HOME/.lmstudio/bin

# ASDF - only load if devenv is not active
if not set -q DEVENV_PROFILE; and not set -q DEVENV_ROOT
    if test -z $ASDF_DATA_DIR
        set _asdf_shims "$HOME/.asdf/shims"
    else
        set _asdf_shims "$ASDF_DATA_DIR/shims"
    end

    if not contains $_asdf_shims $PATH
        set -gx --prepend PATH $_asdf_shims
    end
    set --erase _asdf_shims
end

# --- Command aliases (available in scripts and interactive shells) ---

alias be='bundle exec'
alias goodcop='rubocop -Pfs'

switch $os
    case Linux
        alias apt='sudo apt'
        alias aptitude='sudo aptitude'
        alias apt-get='sudo apt-get'
        alias ifconfig='sudo ifconfig'
        alias open='xdg-open'
    case Darwin
        alias brew-restart='brew services restart'
        alias brew-start='brew services start'
        alias brew-stop='brew services stop'
        alias brew-update='brew update; brew upgrade; brew doctor; brew cleanup -s --prune=all'
        alias md5sum='md5 -q'
end

# --- Interactive only ---
if status is-interactive
    # fzf keybindings and completion
    if type -q fzf
        fzf --fish | source
    end

    # direnv
    if type -q direnv
        direnv hook fish | source
    end

    # zoxide (smarter cd)
    if type -q zoxide
        zoxide init fish | source
    end

    # Increase open file limit (default 256 on macOS is too low for dev)
    if test (ulimit -n) -lt 4096
        ulimit -n 4096
    end

    # Per-machine settings
    if test -f $HOME/.config/fish/local.fish
        source $HOME/.config/fish/local.fish
    end

    # --- Abbreviations (expand inline so you see the full command) ---
    abbr -a g git
    abbr -a gst git status
    abbr -a gd git diff
    abbr -a gdc git diff --cached
    abbr -a gl git lg
    abbr -a gco git checkout
    abbr -a gpu git push
    abbr -a gpl git pull
    abbr -a ga git add
    abbr -a gci git commit --verbose
    abbr -a gca git commit --amend
    abbr -a gcane git commit --amend --no-edit

    abbr -a ts tmux-sessionizer
    abbr -a bi bundle install
    abbr -a rc bin/rails console
    abbr -a rs bin/rails server
    abbr -a rr bin/rails routes
    abbr -a rdb bin/rails db

    # --- Aliases ---

    alias clbin="curl -F 'clbin=<-' https://clbin.com"
    alias coverage-web="ruby -run -e httpd coverage -p 3005"
    alias cp='cp -Rv'
    alias dev='bin/dev'
    alias dog="pygmentize -g"
    alias egrep='egrep --color=auto -n'
    alias gdb='gdb -q'
    alias grep='grep --color=auto -n'
    alias less='less -R'
    alias mv='mv -v'
    alias search='grep --color=auto -R -C3 -n'
    alias strings='strings -a'
    # alias vim='nvim'
    alias tmux='tmux -2 -u'
    alias jsc="env NODE_NO_READLINE=1 rlwrap node"

    # Batch git operations across repos in current directory
    alias fetch-all='find . -maxdepth 2 -name .git -type d -execdir git fetch --all --prune \;'
    alias pull-all='find . -maxdepth 2 -name .git -type d -execdir git pull \;'

    # Platform-specific display aliases
    switch $os
        case Linux
            alias ls='ls -ltrGh'
            alias ps='ps aux --forest'
        case Darwin
            alias ps="ps -eo pid,args,etime,%cpu,rss"
            alias ls='ls -Goh'
    end
end
