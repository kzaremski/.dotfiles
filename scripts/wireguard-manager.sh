#!/bin/bash
# wireguard-manager.sh
# dmenu-based WireGuard VPN manager

WG_CONFIG_DIR="/etc/wireguard"

# Get list of wireguard configs and their status
get_configs() {
    # Get active interfaces
    active=$(sudo -n wg show interfaces 2>/dev/null || echo "")

    # List config files
    shopt -s nullglob
    for conf in "$WG_CONFIG_DIR"/*.conf; do
        [ -f "$conf" ] || continue
        name=$(basename "$conf" .conf)

        if echo "$active" | grep -qw "$name"; then
            echo "[ACTIVE] $name"
        else
            echo "[      ] $name"
        fi
    done
    shopt -u nullglob
}

# Check if we can read configs - if not, re-run self in urxvt with sudo prompt
if ! sudo -n ls "$WG_CONFIG_DIR" &>/dev/null; then
    urxvt -title "WireGuard Manager" -e bash -c "
        echo 'WireGuard Manager needs sudo access.'
        echo ''
        if sudo ls '$WG_CONFIG_DIR' >/dev/null 2>&1; then
            exec $0
        else
            echo 'Failed to get sudo access.'
            read -p 'Press Enter to close...'
        fi
    "
    exit 0
fi

# Get configs
configs=$(get_configs)

if [ -z "$configs" ]; then
    notify-send "WireGuard" "No configs found in $WG_CONFIG_DIR"
    exit 1
fi

# Select config
selected=$(echo "$configs" | dmenu -i -l 10 -p "WireGuard:" -fn "Terminus-10")
[ -z "$selected" ] && exit 0

# Parse selection
is_active=false
[[ "$selected" == "[ACTIVE]"* ]] && is_active=true
name=$(echo "$selected" | sed 's/\[.*\] //')

# Show action menu
if $is_active; then
    action=$(echo -e "Deactivate $name\nCancel" | dmenu -i -l 2 -p "Action:" -fn "Terminus-10")
else
    action=$(echo -e "Activate $name\nCancel" | dmenu -i -l 2 -p "Action:" -fn "Terminus-10")
fi

[ -z "$action" ] || [[ "$action" == "Cancel" ]] && exit 0

# Execute in urxvt with explanation
if [[ "$action" == "Activate"* ]]; then
    urxvt -title "WireGuard: Activate $name" -e bash -c "
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ' WireGuard Manager - Activating: $name'
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ''
        echo 'This will run:'
        echo '  sudo wg-quick up $name'
        echo ''
        echo 'This brings up the WireGuard interface and configures'
        echo 'routing according to $WG_CONFIG_DIR/$name.conf'
        echo ''
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ''
        sudo wg-quick up $name
        echo ''
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        if [ \$? -eq 0 ]; then
            echo ' ✓ $name activated successfully'
        else
            echo ' ✗ Failed to activate $name'
        fi
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ''
        read -p 'Press Enter to close...'
    "
else
    urxvt -title "WireGuard: Deactivate $name" -e bash -c "
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ' WireGuard Manager - Deactivating: $name'
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ''
        echo 'This will run:'
        echo '  sudo wg-quick down $name'
        echo ''
        echo 'This tears down the WireGuard interface and removes'
        echo 'associated routes.'
        echo ''
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ''
        sudo wg-quick down $name
        echo ''
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        if [ \$? -eq 0 ]; then
            echo ' ✓ $name deactivated successfully'
        else
            echo ' ✗ Failed to deactivate $name'
        fi
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ''
        read -p 'Press Enter to close...'
    "
fi
