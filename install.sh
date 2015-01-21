#!/bin/bash

set -e

# Begin installation:
echo -e "Installing dot-files:"
echo -e "\t[+] Creating soft-links to dot-files."

# Soft-link all files and directories (except .git of course)
for dotfile in $(find $(pwd) -maxdepth 1 -name ".*" | sed '/.git$/d');
do
    echo -e "\t\t[>] Copying $dotfile"
    if [[ -d $dotfile ]];
    then
        cp -r $dotfile ~
    else
        ln -sf $dotfile ~
    fi
done

# Only copy update script on debian
if [[ `uname -s` == "Linux" ]];
then
    ln -sf `pwd`/update.sh ~
fi

# Install vundle
if [[ ! -d ~/.vim/bundle/vundle ]]; then
    echo -e "\t[+] Installing vundle."
    git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle &> /dev/null
fi

echo -e "\t[+] Installing new vundles."
vim +PluginInstall +qall

echo -e "[!] Restart terminal session for changes to take effect."
