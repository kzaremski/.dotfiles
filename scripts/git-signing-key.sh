#!/bin/bash
# git-signing-key.sh
# Select GPG key for git commit signing via dmenu

# Check if gpg is available
if ! command -v gpg &> /dev/null; then
    notify-send "Git Signing Key" "GPG is not installed"
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
    notify-send "Git Signing Key" "No GPG secret keys found"
    exit 1
fi

# Add option to disable signing
key_list="[Disable signing]"$'\n'"$key_list"

# Show dmenu and get selection
selected=$(echo "$key_list" | dmenu -i -l 10 -p "GPG Key:" -fn "CaskaydiaCove Nerd Font Mono-10")

# Exit if nothing selected
[ -z "$selected" ] && exit 0

if [ "$selected" = "[Disable signing]" ]; then
    git config --global --unset user.signingkey
    git config --global --unset commit.gpgsign
    notify-send "Git Signing Key" "Commit signing disabled"
else
    # Extract key ID (before the |)
    keyid=$(echo "$selected" | cut -d'|' -f1 | xargs)

    git config --global user.signingkey "$keyid"
    git config --global commit.gpgsign true
    notify-send "Git Signing Key" "Signing with: $keyid"
fi
