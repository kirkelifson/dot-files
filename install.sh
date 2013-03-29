#!/bin/zsh

# install oh-my-zsh if not installed
if [ ! -d ~/.oh-my-zsh ]; then
    sudo apt-get install zsh
    wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
fi

# copy current dot files into home directory 
cp -r .vim .vimrc .oh-my-zsh .zshrc .tmux.conf .gitconfig .gdbinit .htoprc update.sh ~

# execute zshrc to see new config
source ~/.zshrc
