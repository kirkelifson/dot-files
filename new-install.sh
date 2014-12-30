cd
sudo apt-get install build-essential curl gdb git htop libncurses5-dev linux-headers-$(uname -r) nasm python2.7-dev radare2 ssh tmux zsh
sudo apt-get build-dep vim
wget ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2
tar xzf vim-7.4.tar.bz2
cd vim74
./configure --enable-pythoninterp=yes --with-python-config-dir=/usr/lib/python2.7/config --enable-rubyinterp --with-features=huge
make && sudo make install
cd
ssh-keygen
git clone https://github.com/kirkelifson/dot-files
cd dot-files
./install
