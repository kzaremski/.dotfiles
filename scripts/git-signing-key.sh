#!/bin/bash
# git-signing-key.sh
# Select GPG key for git commit signing via dmenu or TTY menu

# Check if gpg is available
if ! command -v gpg &> /dev/null; then
    echo "Error: GPG is not installed"
    exit 1
fi

# Get list of secret keys (signing capable)
# Format: KEYID | uid
key_list=$(gpg --list-secret-keys --keyid-format long 2>/dev/null | \
    awk '/^sec/ {
        split($2, a, "/")
        keyid = a[2]
    }
    /^uid/ {
        sub(/^uid *\[.*\] */, "")
        print keyid " | " $0
    }')

if [ -z "$key_list" ]; then
    echo "Error: No GPG secret keys found"
    exit 1
fi

# Add option to disable signing
key_list="[Disable signing]"$'\n'"$key_list"

# Check if we have X display and dmenu available
if [ -n "$DISPLAY" ] && command -v dmenu &> /dev/null; then
    # Use dmenu
    selected=$(echo "$key_list" | dmenu -i -l 10 -p "GPG Key:" -fn "CaskaydiaCove Nerd Font Mono-10")
else
    # TTY/SSH fallback - use numbered menu
    echo "Select GPG signing key:"
    echo ""

    # Convert to array
    mapfile -t keys <<< "$key_list"

    # Display numbered options
    for i in "${!keys[@]}"; do
        echo "  $((i+1))) ${keys[$i]}"
    done

    echo ""
    read -p "Enter number (or q to quit): " choice

    # Handle quit
    [[ "$choice" == "q" || "$choice" == "Q" ]] && exit 0

    # Validate input
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#keys[@]}" ]; then
        echo "Invalid selection"
        exit 1
    fi

    selected="${keys[$((choice-1))]}"
fi

# Exit if nothing selected
[ -z "$selected" ] && exit 0

# Function to notify (GUI or terminal)
notify() {
    if [ -n "$DISPLAY" ] && command -v notify-send &> /dev/null; then
        notify-send "Git Signing Key" "$1"
    fi
    echo "$1"
}

if [ "$selected" = "[Disable signing]" ]; then
    git config --global --unset user.signingkey
    git config --global --unset commit.gpgsign
    notify "Commit signing disabled"
else
    # Extract key ID (before the |)
    keyid=$(echo "$selected" | cut -d'|' -f1 | xargs)

    git config --global user.signingkey "$keyid"
    git config --global commit.gpgsign true
    notify "Signing with: $keyid"
fi
