#!/bin/sh
chosenAppImage=$(ls $HOME/Applications/ | sed -e 's/\.AppImage$//' | dmenu -fn "CaskaydiaCove Nerd Font Mono-10")
if [[ "$(expr length "$chosenAppImage")" != "0" ]]
then
    $HOME/Applications/$chosenAppImage.AppImage
	exit
fi
echo "No AppImage file selected."


