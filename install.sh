#!/bin/zsh

# assumed that zsh is installed

# install oh-my-zsh if not installed
if [ ! -d ~/.oh-my-zsh ]; then
    wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
fi

# create symbolic links for all dot-files
cd $HOME

ln -sb dot-files/.vimrc .
ln -sb dot-files/.zshrc .
ln -sb dot-files/.tmux.conf .
ln -sb dot-files/.gitconfig .
ln -sb dot-files/bench.sh .
ln -sb dot-files/update.sh .

chmod +x bench.sh update.sh

# symbolic links with vundle would get messy
cp -r dot-files/.vim .

# execute zshrc to utilize new config
source ~/.zshrc
