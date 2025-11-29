#!/bin/bash
# tailscale-devices.sh
# Show Tailscale devices with IPs and MagicDNS names
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
kitty --title "Tailscale Devices" bash -c "python3 '$SCRIPT_DIR/tailscale-devices.py' | less"
