#!/bin/bash

date=`date +%Y%m%d%H%M%S`
hostname=ubuntu${date}

sudo hostname $hostname

echo "deb http://archive.ubuntu.com/ubuntu/ precise universe" | sudo tee -a /etc/apt/sources.list

sudo apt-get update
sudo apt-get install git

git config --global user.name "Gabor Heja"
git config --global user.email "gheja@${hostname}"

ssh-keygen

gconftool-2 --set '/apps/compiz-1/plugins/unityshell/screen0/options/panel_first_menu' --type string 'Disabled'
gconftool-2 --set '/desktop/gnome/interface/menubar_accel' --type string 'Disabled'
gconftool-2 --set '/apps/gnome-terminal/global/use_menu_accelerators' --type bool false
gconftool-2 --set '/apps/gnome-terminal/keybindings/full_screen' --type string 'Disabled'
gconftool-2 --set '/apps/gnome-terminal/keybindings/help' --type string 'Disabled'
gconftool-2 --set '/apps/gnome-terminal/profiles/Default/palette' --type string '#000000000000:#AAAA00000000:#0000AAAA0000:#AAAA55550000:#00000000AAAA:#AAAA0000AAAA:#0000AAAAAAAA:#AAAAAAAAAAAA:#555555555555:#FFFF55555555:#5555FFFF5555:#FFFFFFFF5555:#55555555FFFF:#FFFF5555FFFF:#5555FFFFFFFF:#FFFFFFFFFFFF'

cat > ~/.selected_editor <<EOF
SELECTED_EDITOR="/usr/bin/mcedit"
EOF
