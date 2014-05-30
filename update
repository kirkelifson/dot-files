sudo apt-get update
sudo apt-get upgrade
sudo apt-get dist-upgrade
sudo apt-get autoremove
sudo apt-get autoclean

dpkg --get-selections | grep deinstall | cut -f1 | xargs sudo apt-get -y purge

deborphan | xargs sudo apt-get -y purge
