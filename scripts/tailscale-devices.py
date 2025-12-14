#!/usr/bin/env python3
# launcher-ignore
"""
tailscale-devices.py
Display tailscale devices with names, full MagicDNS names, and IP addresses
"""

import subprocess
import json
import sys

def get_tailscale_status():
    """Get tailscale status as JSON"""
    try:
        result = subprocess.run(
            ["tailscale", "status", "--json"],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode != 0:
            return None
        return json.loads(result.stdout)
    except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
        return None

def format_output(data):
    """Format tailscale data for display"""
    lines = []

    suffix = data.get("MagicDNSSuffix", "")
    tailnet = data.get("CurrentTailnet", {}).get("Name", "Unknown")

    lines.append("=" * 70)
    lines.append("TAILSCALE DEVICES")
    lines.append("=" * 70)
    lines.append(f"Tailnet:        {tailnet}")
    lines.append(f"MagicDNS:       *.{suffix}")
    lines.append("")

    # Header
    lines.append(f"{'NAME':<20} {'IP':<18} {'FULL DNS NAME'}")
    lines.append(f"{'-' * 20} {'-' * 18} {'-' * 30}")

    devices = []

    # Self
    self_info = data.get("Self", {})
    if self_info:
        name = self_info.get("HostName", "unknown")
        ips = self_info.get("TailscaleIPs", [])
        ip = ips[0] if ips else "N/A"
        full_name = f"{name}.{suffix}" if suffix else name
        devices.append((name, ip, full_name, True, True))  # is_self=True, online=True

    # Peers
    peers = data.get("Peer", {})
    for peer_id, peer in peers.items():
        # Use DNSName to get the actual device name (HostName is "localhost" for mobile devices)
        dns_name = peer.get("DNSName", "")
        if dns_name:
            # DNSName is like "device-name.tailnet.ts.net." - extract first part
            name = dns_name.split(".")[0]
            full_name = dns_name.rstrip(".")
        else:
            name = peer.get("HostName", "unknown")
            full_name = f"{name}.{suffix}" if suffix else name
        ips = peer.get("TailscaleIPs", [])
        ip = ips[0] if ips else "N/A"
        online = peer.get("Online", False)
        devices.append((name, ip, full_name, False, online))

    # Sort: self first, then online devices, then offline
    devices.sort(key=lambda x: (not x[3], not x[4], x[0].lower()))

    online_count = 0
    offline_count = 0

    for name, ip, full_name, is_self, online in devices:
        if is_self:
            status = " <- this device"
            online_count += 1
        elif online:
            status = ""
            online_count += 1
        else:
            status = " (offline)"
            offline_count += 1

        lines.append(f"{name:<20} {ip:<18} {full_name}{status}")

    lines.append("")
    lines.append(f"Total: {len(devices)} devices ({online_count} online, {offline_count} offline)")
    lines.append("")

    return "\n".join(lines)

def main():
    data = get_tailscale_status()

    if data is None:
        print("Error: Could not get tailscale status")
        print("Make sure tailscale is installed and running")
        sys.exit(1)

    print(format_output(data))

if __name__ == "__main__":
    main()
