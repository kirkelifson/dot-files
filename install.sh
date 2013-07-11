#!/bin/zsh

# assumed that zsh is installed

# install oh-my-zsh if not installed
if [ ! -d ~/.oh-my-zsh ]; then
    wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
fi

# copy current dot files into home directory 
cp -r .vim .vimrc .zshrc .tmux.conf .gitconfig .gdbinit update.sh bench.sh ~

# execute zshrc to utilize new config
source ~/.zshrc
