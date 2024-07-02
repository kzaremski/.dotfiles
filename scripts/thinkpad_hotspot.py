# Konstantin Zaremski
#   September 11, 2023
# 
# ThinkPadHotspot.py
#   This program manages the hostapd hotspot service to rebroadcast the internet connection
#   from the system through the built-in ASUS Wi-Fi adapter.

# Import dependencies
import sys
import subprocess
import time

# Menu Method
def menuInput(prompt, items):
    choice = 0
    while choice > len(items) or choice < 1:
        print(prompt)
        for itemNo in range(0, len(items)):
            print(f"{str(len(itemNo) + 1)} {stritems[itemNo]}")

    print("")

# Main Method
def main(args):
    # Make sure that we are running as root
    userID = int(subprocess.run("id -u", shell=True, capture_output=True).stdout)
    if userID != 0:
        return print("*** Run this script as root or with sudo!")

    # Make the wireless interface unmanaged
    subprocess.run("nmcli dev set wlp0s26u1u4 managed no", shell=True, capture_output=True)
    print("Set ASUS WiFi adapter as an unmanaged interface by NetworkManager")

    # Take action based on the command line arguments
    if "--enable" in args:
        # Start the DNS service
        subprocess.run("systemctl start dnsmasq.service", shell=True, capture_output=True)
        # Set a static IP for this computer as the access point
        subprocess.run("ip link set up dev wlp0s26u1u4", shell=True, capture_output=True)
        subprocess.run("ip addr add 192.168.10.10/24 dev wlp0s26u1u4", shell=True, capture_output=True)
        print("Set static IP for the access point, 192.168.10.10")
        # Enable Packet Forwarding
        subprocess.run("sysctl net.ipv4.ip_forward=1", shell=True, capture_output=True)
        print("Enabled packet forwarding")
        # Enable NAT w. IPTABLES
        subprocess.run("iptables -t nat -A POSTROUTING -o wlp3s0 -j MASQUERADE", shell=True, capture_output=True)
        subprocess.run("iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT", shell=True, capture_output=True)
        subprocess.run("iptables -A FORWARD -i wlp0s26u1u4 -o wlp3s0 -j ACCEPT", shell=True, capture_output=True)
        print("Enabled NAT w. iptables")
        # Allow DHCP incoming connections
        subprocess.run("iptables -I INPUT -p udp --dport 67 -i wlp0s26u1u4 -j ACCEPT", shell=True, capture_output=True)
        subprocess.run("iptables -I INPUT -p udp --dport 53 -s 192.168.10.10/24 -j ACCEPT", shell=True, capture_output=True)
        subprocess.run("iptables -I INPUT -p tcp --dport 53 -s 192.168.10.10/24 -j ACCEPT", shell=True, capture_output=True)
        print("Enabled connections to the local DHCP server on IP 192.168.10.10")
        # Start hostapd
        subprocess.run("systemctl start hostapd.service", shell=True, capture_output=True)
        print("Started hostapd.service")
        # Reload Samba (so that it binds to the new interface)
        time.sleep(2)
        subprocess.run("systemctl restart smb.service", shell=True, capture_output=True)
        print("Restarted and bound smb.service")
        print("*** The hotspot is now online!")
    elif "--disable" in args:
        # Stop HOSTAPDD
        subprocess.run("systemctl stop hostapd.service", shell=True, capture_output=True)
        print("Stopped service hostapd.service")
        print("*** The hotspot is now offline!")
    else:
        print("Neither --enable or --disable was supplied in the command line arguments, doing nothing.")

if __name__ == "__main__":
    # Get the arguments from the command line
    arguments = sys.argv
    arguments.pop(0)
    main(arguments)

