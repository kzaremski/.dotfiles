"""
Ethernet module that cycles between IP address and link speed.

Configuration parameters:
    interface: Network interface to monitor (default "enp0s31f6")
    cycle_interval: Seconds between cycling display (default 2)
    format_ip: Format string for IP display (default "LAN {ip}")
    format_speed: Format string for speed display (default "LAN {speed}")
    format_down: Format string when interface is down (default "NO LAN")
"""

import subprocess


class Py3status:
    interface = "_first_"
    cycle_interval = 2
    format_ip = "LAN {ip}"
    format_speed = "LAN {speed}"
    format_down = "NO LAN"

    def post_config_hook(self):
        self._cycle_state = 0
        self._actual_interface = None

    def _find_first_interface(self):
        """Find the first active ethernet interface."""
        try:
            result = subprocess.run(
                ["ip", "-o", "link", "show", "up"],
                capture_output=True,
                text=True
            )
            for line in result.stdout.strip().split("\n"):
                parts = line.split(": ")
                if len(parts) >= 2:
                    iface = parts[1].split("@")[0]
                    # Skip loopback and wireless interfaces
                    if iface != "lo" and not iface.startswith("wl"):
                        return iface
        except Exception:
            pass
        return None

    def _get_interface(self):
        """Get the interface to use."""
        if self.interface == "_first_":
            if self._actual_interface is None:
                self._actual_interface = self._find_first_interface()
            return self._actual_interface
        return self.interface

    def _get_ip(self, iface):
        """Get IP address for interface."""
        try:
            result = subprocess.run(
                ["ip", "-4", "addr", "show", iface],
                capture_output=True,
                text=True
            )
            for line in result.stdout.split("\n"):
                line = line.strip()
                if line.startswith("inet "):
                    return line.split()[1].split("/")[0]
        except Exception:
            pass
        return None

    def _get_speed(self, iface):
        """Get link speed for interface."""
        try:
            with open(f"/sys/class/net/{iface}/speed") as f:
                speed = int(f.read().strip())
                if speed >= 1000:
                    return f"{speed // 1000}Gb/s"
                return f"{speed}Mb/s"
        except Exception:
            return "?"

    def _is_up(self, iface):
        """Check if interface is up."""
        try:
            with open(f"/sys/class/net/{iface}/operstate") as f:
                return f.read().strip() == "up"
        except Exception:
            return False

    def eth_cycle(self):
        iface = self._get_interface()

        if not iface or not self._is_up(iface):
            # Reset interface cache when down
            if self.interface == "_first_":
                self._actual_interface = None
            return {
                "full_text": self.format_down,
                "cached_until": self.py3.time_in(5)
            }

        ip = self._get_ip(iface)
        speed = self._get_speed(iface)

        # Cycle between IP and speed
        self._cycle_state = (self._cycle_state + 1) % 2

        if self._cycle_state == 0:
            text = self.format_ip.format(ip=ip, speed=speed, interface=iface)
        else:
            text = self.format_speed.format(ip=ip, speed=speed, interface=iface)

        return {
            "full_text": text,
            "color": self.py3.COLOR_GOOD,
            "cached_until": self.py3.time_in(self.cycle_interval)
        }


if __name__ == "__main__":
    from py3status.module_test import module_test
    module_test(Py3status)
