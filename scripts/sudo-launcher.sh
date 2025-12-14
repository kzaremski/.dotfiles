#!/bin/bash
# sudo-launcher.sh
# dmenu-based launcher for running applications with elevated privileges via pkexec

# List of common applications that need root privileges
apps=(
    "gparted | Partition editor"
    "gnome-disks | Disk utility"
    "nm-connection-editor | Network connections"
    "dconf-editor | dconf settings editor"
    "pcmanfm | File manager (as root)"
    "thunar | File manager (as root)"
    "urxvt | Terminal (as root)"
    "pavucontrol | PulseAudio volume control"
    "blueman-manager | Bluetooth manager"
)

# Build the menu
menu=""
for app in "${apps[@]}"; do
    menu+="$app"$'\n'
done

# Show dmenu and get selection
selected=$(echo -n "$menu" | dmenu -i -l 15 -p "Run as root:" -fn "Terminus-10")

# Exit if nothing selected
[ -z "$selected" ] && exit 0

# Extract application name (before the | if present)
app_name=$(echo "$selected" | cut -d'|' -f1 | xargs)

# Check if the application exists
if ! command -v "$app_name" &>/dev/null; then
    notify-send "Sudo Launcher" "Application not found: $app_name"
    exit 1
fi

# Run with pkexec
pkexec "$app_name"
