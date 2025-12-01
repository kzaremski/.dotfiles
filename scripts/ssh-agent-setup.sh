#!/usr/bin/env bash
# SSH Agent Setup Script
# Unlocks SSH keys using keychain at system startup

# Check if keychain is installed
if ! command -v keychain &> /dev/null; then
    echo "keychain is not installed on this system"
    echo "SSH agent will not be configured"
    echo ""
    echo "Press Enter to close..."
    read
    exit 0
fi

# Run keychain to unlock SSH keys
echo "Unlocking SSH keys..."
echo ""
keychain id_ed25519

# Source the keychain environment
if [ -f "$HOME/.keychain/$(hostname)-sh" ]; then
    source "$HOME/.keychain/$(hostname)-sh"
    echo ""
    echo "SSH agent configured successfully"
    echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
else
    echo ""
    echo "Warning: keychain environment file not found"
fi

echo ""
echo "Press Enter to close..."
read
