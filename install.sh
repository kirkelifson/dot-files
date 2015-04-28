#!/bin/bash

set -e
dir=$(pwd)

# Begin installation:
echo -ne "Installing dot-files:"
echo -ne "\t[+] Creating soft-links to dot-files."

# Soft-link all files and directories (except .git of course)
for dotfile in $(find $dir -maxdepth 1 -name ".*" | sed '/.git$/d'); do
    if [[ -d $dotfile ]]; then
        echo -ne "\t\t[>] Copying $dotfile"
        cp -r $dotfile ~
    else
        echo -ne "\t\t[>] Linking $dotfile"
        ln -sf $dotfile ~
    fi
done

# Copy bin as well
echo -ne "\t\t[>] Linking $dir/bin"
ln -sf $dir/bin ~

# Only copy update script on debian
if [[ $(uname -s) == "Linux" ]]; then
    ln -sf $dir/update.sh ~
fi

if [[ ! -d ~/peda ]]; then
    echo -ne "\t[+] Installing peda (gdb)."
    git clone https://github.com/crowell/p3da ~/peda &> /dev/null
fi

# Install vundle
if [[ ! -d ~/.vim/bundle/vundle ]]; then
    echo -ne "\t[+] Installing vundle."
    git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle &> /dev/null
fi

echo -ne "\t[+] Installing new vundles."
vim +PluginInstall +qall

echo -ne "[!] Restart terminal session for changes to take effect."
