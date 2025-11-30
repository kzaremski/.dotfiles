#!/bin/bash
# tailscale-devices.sh
# Show Tailscale devices with IPs and MagicDNS names
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

if [ -n "$DISPLAY" ] && command -v kitty &> /dev/null; then
    # GUI mode - open in kitty with less
    kitty --title "Tailscale Devices" bash -c "python3 '$SCRIPT_DIR/tailscale-devices.py' | less"
else
    # TTY/SSH fallback - run directly with less or just output
    if command -v less &> /dev/null; then
        python3 "$SCRIPT_DIR/tailscale-devices.py" | less
    else
        python3 "$SCRIPT_DIR/tailscale-devices.py"
    fi
fi
