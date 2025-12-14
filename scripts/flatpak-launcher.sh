#!/bin/bash
# flatpak-launcher.sh
# Launch Flatpak applications via dmenu

# Check if flatpak is available
if ! command -v flatpak &> /dev/null; then
    notify-send "Flatpak Launcher" "Flatpak is not installed"
    exit 1
fi

# Get list of installed applications (not runtimes)
# Format: Name | Application ID
app_list=$(flatpak list --app --columns=name,application 2>/dev/null | tail -n +1)

if [ -z "$app_list" ]; then
    notify-send "Flatpak Launcher" "No Flatpak applications found"
    exit 1
fi

# Show dmenu and get selection
selected=$(echo "$app_list" | dmenu -i -l 15 -p "Flatpak:" -fn "Terminus-10")

# Exit if nothing selected
[ -z "$selected" ] && exit 0

# Extract application ID (second column, tab-separated)
app_id=$(echo "$selected" | awk '{print $NF}')

# Run the flatpak
exec flatpak run "$app_id"
