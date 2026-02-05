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

# Rails
set -gx DISABLE_SPRING 1

# fzf + fd
set -gx FZF_DEFAULT_COMMAND 'fd --type f'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"

# Homebrew paths - always add (fish_add_path deduplicates)
if test -d /opt/homebrew/bin
    fish_add_path -p /opt/homebrew/bin /opt/homebrew/sbin
end

# Only load other PATH modifications and integrations outside of tmux
# (tmux inherits environment from parent shell)
if not set -q TMUX
    # Add ~/bin to PATH (fish_add_path automatically deduplicates)
    if test -d $HOME/bin
        fish_add_path -p $HOME/bin
    end

    # pyenv (installed via Homebrew)
    if type -q pyenv
        set -gx PYENV_ROOT "$HOME/.pyenv"
        pyenv init - fish | source
    end

    # fzf integration
    if test -f $HOME/.fzf.fish
        source $HOME/.fzf.fish
    end

    # LM Studio CLI
    fish_add_path -a $HOME/.lmstudio/bin

    # Per-machine settings
    if test -f $HOME/.config/fish/local.fish
        source $HOME/.config/fish/local.fish
    end
end

# Aliases (loaded every time)
alias be='bundle exec'
alias clbin="curl -F 'clbin=<-' https://clbin.com"
alias coverage-web="ruby -run -e httpd coverage -p 3005"
alias cp='cp -Rv'
alias dev='bin/dev'
alias dog="pygmentize -g"
alias egrep='egrep --color -n'
alias gdb='gdb -q'
alias goodcop='rubocop -Pfs'
alias grep='grep --color -n'
alias less='less -R'
alias mv='mv -v'
alias search='grep --color -R -C3 -n'
alias strings='strings -a'
alias vim='nvim'
alias tmux='tmux -2 -u'
alias jsc="env NODE_NO_READLINE=1 rlwrap node"

# Platform-specific aliases
switch (uname -s)
    case Linux
        alias apt='sudo apt'
        alias aptitude='sudo aptitude'
        alias apt-get='sudo apt-get'
        alias ifconfig='sudo ifconfig'
        alias open='xdg-open'
        alias ls='ls -ltrGh'
        alias ps='ps aux --forest'
    case Darwin
        alias ps="ps -eo pid,args,etime,%cpu,rss"
        alias brew-restart='brew services restart'
        alias brew-start='brew services start'
        alias brew-stop='brew services stop'
        alias brew-update='brew update; brew upgrade; brew doctor; brew cleanup -s --prune=all'
        alias md5sum='md5 -q'
        alias ls='ls -Goh'
end

# Disable greeting
set -g fish_greeting

# opencode
fish_add_path /Users/kronk/.opencode/bin

fish_add_path /Users/kronk/.bun/bin

fish_add_path /Users/kronk/.cargo/bin

# Added by `rbenv init` on Mon Jan  5 14:06:01 EST 2026
# status --is-interactive; and rbenv init - --no-rehash fish | source

fish_add_path "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

fish_add_path /Users/kronk/.docker/bin

# ASDF configuration code - only load if devenv is not active
# Devenv sets its own environment and tool versions, so asdf should not interfere
if not set -q DEVENV_PROFILE; and not set -q DEVENV_ROOT
    if test -z $ASDF_DATA_DIR
        set _asdf_shims "$HOME/.asdf/shims"
    else
        set _asdf_shims "$ASDF_DATA_DIR/shims"
    end

    # Do not use fish_add_path (added in Fish 3.2) because it
    # potentially changes the order of items in PATH
    if not contains $_asdf_shims $PATH
        set -gx --prepend PATH $_asdf_shims
    end
    set --erase _asdf_shims
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/kronk/.lmstudio/bin
# End of LM Studio CLI section

fish_add_path /opt/homebrew/opt/openjdk/bin
