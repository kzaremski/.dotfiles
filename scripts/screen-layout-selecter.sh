#!/bin/sh
chosenLayout=$(ls ~/.screenlayout/ | sed -e 's/\.sh$//' | dmenu -fn "CaskaydiaCove Nerd Font Mono-10")
if [[ "$(expr length "$chosenLayout")" != "0" ]]
then
	echo "Switching layout to: $chosenLayout.sh"
	# Run the chosen screen layout set script
	sh ~/.screenlayout/$chosenLayout.sh
	# Set the wallpaper
	feh --bg-fill ~/Pictures/wallpaper.jpg
	exit
fi
echo "No layout selected."
