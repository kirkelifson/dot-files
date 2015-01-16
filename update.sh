# Do everything apt-get can possibly accomplish
sudo apt-get update
sudo apt-get upgrade
sudo apt-get dist-upgrade
sudo apt-get autoremove
sudo apt-get autoclean

# Purge packages marked for uninstall
dpkg --get-selections | grep deinstall | cut -f1 | xargs sudo apt-get -y purge

# Purge orphaned packages
deborphan | xargs sudo apt-get -y purge
