#!/usr/bin/env bash
# ssh-agent-setup.sh
# Unlocks SSH keys using keychain (no terminal required)

# Function to notify user
notify() {
    if [ -n "$DISPLAY" ] && command -v notify-send &> /dev/null; then
        notify-send "SSH Agent" "$1"
    fi
}

# Check if keychain is installed
if ! command -v keychain &> /dev/null; then
    notify "keychain is not installed"
    exit 1
fi

# Get hostname reliably (Arch Linux doesn't always set $HOSTNAME)
MACHINE_HOSTNAME=$(cat /etc/hostname 2>/dev/null | tr -d '\n')
if [ -z "$MACHINE_HOSTNAME" ]; then
    notify "Could not determine hostname"
    exit 1
fi

# Check if key is already loaded
if [ -f "$HOME/.keychain/$MACHINE_HOSTNAME-sh" ]; then
    source "$HOME/.keychain/$MACHINE_HOSTNAME-sh"
    if ssh-add -l &>/dev/null; then
        notify "SSH key already loaded"
        exit 0
    fi
fi

# Run keychain (it will prompt for passphrase via ssh-askpass or pinentry)
# The --quiet flag suppresses output, --agents ssh only starts ssh-agent
keychain --quiet --agents ssh id_ed25519 2>/dev/null

# Source the keychain environment
if [ -f "$HOME/.keychain/$MACHINE_HOSTNAME-sh" ]; then
    source "$HOME/.keychain/$MACHINE_HOSTNAME-sh"

    # Verify key was loaded
    if ssh-add -l &>/dev/null; then
        notify "SSH key unlocked successfully"
    else
        notify "SSH key unlock may have failed"
    fi
else
    notify "Keychain environment file not found"
    exit 1
fi
