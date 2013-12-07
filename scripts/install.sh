#!/bin/zsh

# grab directory structure
_dir="$(dirname $(readlink -f $0) | sed -e 's/\/scripts//')"

# assumed: zsh installed and already being used

# install oh-my-zsh if not installed
if [ ! -d ~/.oh-my-zsh ]; then
    wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
fi

# install using symlinks
# vim
ln -sb $_dir/vim/.vimrc ~/
cp -r $_dir/vim/.vim ~/

# zsh
ln -sb $_dir/zsh/.zshrc ~/
ln -sb $_dir/zsh/.zshenv ~/

# tmux
ln -sb $_dir/tmux/.tmux.conf ~/

# git
ln -sb $_dir/git/.gitconfig ~/

# gdb
ln -sb $_dir/gdb/.gdbinit ~/

# scripts
ln -sb $_dir/scripts/update.sh ~/

# install vundle
if [ ! -d ~/.vim/bundle/vundle ]; then
    git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
fi

vim +BundleInstall +qall

# execute zshrc to utilize new config
source ~/.zshrc
