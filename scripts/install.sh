#!/bin/zsh

# grab directory structure
_dir="$(dirname $(readlink -f $0) | sed -e 's/\/scripts//')"

# install oh-my-zsh if not installed
if [ ! -d ~/.oh-my-zsh ]; then
    wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
fi

# Installation:

# vim
# backup ~/.vim
if [ -d ~/.vim-backup ]; then
    echo -ne "[!] Backing up ~/.vim to ~/.vim-backup\n\n"
    rm -rf ~/.vim-backup
fi

mv ~/.vim ~/.vim-backup

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

# delete all duplicated symlinks
rm ~/*.*~
rm ~/.*~

# install vundle
if [ ! -d ~/.vim/bundle/vundle ]; then
    git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle &> /dev/null
fi

vim +BundleInstall +qall

# execute zshrc to utilize new config
source ~/.zshrc
