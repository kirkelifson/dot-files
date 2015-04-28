#!/bin/bash

args=(update upgrade dist-upgrade autoremove autoclean)
for arg in args; do
    sudo apt-get $arg
done

# Purge packages marked for uninstall
sudo dpkg --get-selections | grep deinstall | cut -f1 | xargs sudo apt-get -y purge

# Purge orphaned packages
sudo deborphan | xargs sudo apt-get -y purge
