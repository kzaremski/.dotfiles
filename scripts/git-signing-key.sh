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
    selected=$(echo "$key_list" | dmenu -i -l 10 -p "GPG Key:" -fn "Terminus-10")
else
    # TTY/SSH fallback - use numbered menu
    echo "Select GPG signing key:"
    echo ""

    # Display numbered options and count them
    num_keys=0
    echo "$key_list" | while IFS= read -r line; do
        num_keys=$((num_keys + 1))
        echo "  $num_keys) $line"
    done

    # Count total keys
    num_keys=$(echo "$key_list" | wc -l | tr -d ' ')

    echo ""
    printf "Enter number (or q to quit): "
    read choice

    # Handle quit
    case "$choice" in
        q|Q) exit 0 ;;
    esac

    # Validate input is a number
    case "$choice" in
        ''|*[!0-9]*)
            echo "Invalid selection"
            exit 1
            ;;
    esac

    if [ "$choice" -lt 1 ] || [ "$choice" -gt "$num_keys" ]; then
        echo "Invalid selection"
        exit 1
    fi

    # Get the selected line
    selected=$(echo "$key_list" | sed -n "${choice}p")
fi

# Exit if nothing selected
[ -z "$selected" ] && exit 0

# Function to notify (GUI or terminal)
notify() {
    if [ -n "$DISPLAY" ] && command -v notify-send &> /dev/null; then
        notify-send "Git Signing Key" "$1"
    fi
    printf '%b\n' "$1"
}

if [ "$selected" = "[Disable signing]" ]; then
    git config --global --unset user.signingkey
    git config --global --unset commit.gpgsign
    notify "Commit signing disabled"
else
    # Extract key ID (before the |)
    keyid=$(echo "$selected" | cut -d'|' -f1 | xargs)

    # Extract email from the uid (format: "Name <email@example.com>")
    email=$(echo "$selected" | sed -n 's/.*<\([^>]*\)>.*/\1/p')

    git config --global user.signingkey "$keyid"
    git config --global commit.gpgsign true

    if [ -n "$email" ]; then
        git config --global user.email "$email"
        notify "Signing with: $keyid\nEmail set to: $email"
    else
        notify "Signing with: $keyid"
    fi
fi
