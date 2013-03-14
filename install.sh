# install oh-my-zsh
wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh

# copy current dot files into home directory 
# ^^ (way to do this dynamically?)
cp -r .vim .vimrc .oh-my-zsh .zshrc .tmux.conf .gitconfig .gdbinit .htoprc update.sh ~

# execute zshrc to see new config
source ~/.zshrc
