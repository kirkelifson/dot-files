#!/bin/zsh

# assumed: zsh installed and already being used

# install oh-my-zsh if not installed
if [ ! -d ~/.oh-my-zsh ]; then
    wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
fi

# install using symlinks
cd $HOME
# vim
ln -sb dot-files/vim/.vimrc .
cp -r dot-files/vim/.vim .

# zsh
ln -sb dot-files/zsh/.zshrc .
ln -sb dot-files/zsh/.zshenv .

# tmux
ln -sb dot-files/tmux/.tmux.conf .

# git
ln -sb dot-files/git/.gitconfig .

# scripts
ln -sb dot-files/scripts/update.sh .

# install vundle
if [ ! -d ~/.vim/bundle/vundle ]; then
    git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
fi

vim +BundleInstall +qall

# execute zshrc to utilize new config
source ~/.zshrc
