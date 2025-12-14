#!/bin/bash
# tailscale-devices.sh
# Dmenu interface for Tailscale devices - select to copy DNS or IP

DMENU_FONT="Terminus-10"

# Get tailscale status as JSON
get_devices() {
    tailscale status --json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
suffix = data.get('MagicDNSSuffix', '')

devices = []

# Self
self_info = data.get('Self', {})
if self_info:
    name = self_info.get('HostName', 'unknown')
    ips = self_info.get('TailscaleIPs', [])
    ip = ips[0] if ips else 'N/A'
    os = self_info.get('OS', 'unknown')
    full_name = f'{name}.{suffix}' if suffix else name
    devices.append((name, ip, full_name, os, True, True))

# Peers
peers = data.get('Peer', {})
for peer_id, peer in peers.items():
    dns_name = peer.get('DNSName', '')
    if dns_name:
        name = dns_name.split('.')[0]
        full_name = dns_name.rstrip('.')
    else:
        name = peer.get('HostName', 'unknown')
        full_name = f'{name}.{suffix}' if suffix else name
    ips = peer.get('TailscaleIPs', [])
    ip = ips[0] if ips else 'N/A'
    os = peer.get('OS', 'unknown')
    online = peer.get('Online', False)
    devices.append((name, ip, full_name, os, False, online))

# Sort: self first, then online, then offline
devices.sort(key=lambda x: (not x[4], not x[5], x[0].lower()))

for name, ip, full_name, os, is_self, online in devices:
    status = '*' if is_self else ('+' if online else '-')
    # Format: STATUS|NAME|IP|DNS|OS
    print(f'{status}|{name}|{ip}|{full_name}|{os}')
"
}

# Check dependencies
if ! command -v tailscale &> /dev/null; then
    notify-send "Error" "tailscale not installed" 2>/dev/null
    echo "Error: tailscale not installed"
    exit 1
fi

if [ -z "$DISPLAY" ] || ! command -v dmenu &> /dev/null; then
    echo "Error: Requires X display and dmenu"
    exit 1
fi

# Get device list
DEVICES=$(get_devices)

if [ -z "$DEVICES" ]; then
    notify-send "Tailscale" "Could not get device list" 2>/dev/null
    exit 1
fi

# Build dmenu list with formatted output
# Format for display: [status] name (os) - dns
MENU_ITEMS=$(echo "$DEVICES" | while IFS='|' read -r status name ip dns os; do
    case "$status" in
        '*') indicator="◆" ;;  # this device
        '+') indicator="●" ;;  # online
        '-') indicator="○" ;;  # offline
    esac
    printf "%s %-20s %-8s %s\n" "$indicator" "$name" "($os)" "$dns"
done)

# Show device selection dmenu
SELECTED=$(echo "$MENU_ITEMS" | dmenu -i -l 15 -p "Tailscale Devices:" -fn "$DMENU_FONT")

[ -z "$SELECTED" ] && exit 0

# Extract the device name from selection (second field after indicator)
SELECTED_NAME=$(echo "$SELECTED" | awk '{print $2}')

# Find the matching device data
DEVICE_DATA=$(echo "$DEVICES" | grep "|${SELECTED_NAME}|")
IP=$(echo "$DEVICE_DATA" | cut -d'|' -f3)
DNS=$(echo "$DEVICE_DATA" | cut -d'|' -f4)

# Show action selection dmenu
ACTIONS="Copy DNS: $DNS
Copy IP: $IP"

ACTION=$(echo "$ACTIONS" | dmenu -i -l 2 -p "Action:" -fn "$DMENU_FONT")

[ -z "$ACTION" ] && exit 0

# Perform action
case "$ACTION" in
    "Copy DNS:"*)
        echo -n "$DNS" | xclip -selection clipboard
        notify-send "Copied" "$DNS" 2>/dev/null
        ;;
    "Copy IP:"*)
        echo -n "$IP" | xclip -selection clipboard
        notify-send "Copied" "$IP" 2>/dev/null
        ;;
esac
