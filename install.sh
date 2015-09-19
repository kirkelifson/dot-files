#!/bin/bash

set -e
dir=$(pwd)

# Begin installation:
echo -e "Installing dot-files:"
echo -e "\t[+] Creating soft-links to dot-files."

# Soft-link all files and directories (except .git of course)
for dotfile in $(find $dir -maxdepth 1 -name ".*" | sed '/.git$/d'); do
    if [[ -d $dotfile ]]; then
        echo -e "\t\t[>] Copying $dotfile"
        cp -r $dotfile ~
    else
        echo -e "\t\t[>] Linking $dotfile"
        ln -sf $dotfile ~
    fi
done

# Copy bin as well
echo -e "\t\t[>] Linking $dir/bin"
ln -sf $dir/bin ~

# Only copy update script on debian
if [[ $(uname -s) == "Linux" ]]; then
    ln -sf $dir/update.sh ~
fi

if [[ ! -d ~/peda ]]; then
    echo -e "\t[+] Installing peda (gdb)."
    git clone https://github.com/longld/peda.git ~/peda &> /dev/null
fi

# Install vundle
if [[ ! -d ~/.vim/bundle/vundle ]]; then
    echo -e "\t[+] Installing vundle."
    git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle &> /dev/null
fi

echo -e "\t[+] Installing new vundles."
vim +PluginInstall +qall

echo -e "[!] Restart terminal session for changes to take effect."
