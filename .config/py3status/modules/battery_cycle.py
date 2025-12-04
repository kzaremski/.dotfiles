"""
Battery module that cycles between percentage and time remaining.

Configuration parameters:
    cycle_interval: Seconds between cycling display (default 2)
    format_percent: Format string for percentage display (default "BAT {percent}%")
    format_time: Format string for time display (default "BAT {time}")
    format_charging: Format string when charging (default "CHG {percent}%")
    format_full: Format string when full (default "FULL")
    format_service: Format string for service warning (default "SERVICE BATTERY")
    good_threshold: Percentage above which to show green (default 70)
    degraded_threshold: Percentage below which to show yellow (default 30)
    health_bad_threshold: Health % below which to show red service warning (default 60)
    health_degraded_threshold: Health % below which to show yellow service warning (default 80)
"""


class Py3status:
    cycle_interval = 2
    format_percent = "BAT {percent}%"
    format_time = "BAT {time}"
    format_charging = "CHG {percent}%"
    format_full = "FULL"
    format_service = "SERVICE BATTERY"
    good_threshold = 70
    degraded_threshold = 30
    health_bad_threshold = 60
    health_degraded_threshold = 80

    def post_config_hook(self):
        self._cycle_state = 0
        self._battery_health = None
        self._health_checked = False

    def _get_battery_info(self):
        """Get battery status, percentage, and time remaining."""
        try:
            with open("/sys/class/power_supply/BAT0/status") as f:
                status = f.read().strip()
        except Exception:
            try:
                with open("/sys/class/power_supply/BAT1/status") as f:
                    status = f.read().strip()
            except Exception:
                return None, None, None

        bat_path = "/sys/class/power_supply/BAT0"
        try:
            with open(f"{bat_path}/capacity") as f:
                percent = int(f.read().strip())
        except Exception:
            try:
                bat_path = "/sys/class/power_supply/BAT1"
                with open(f"{bat_path}/capacity") as f:
                    percent = int(f.read().strip())
            except Exception:
                return status, None, None

        # Try to get time remaining
        time_str = None
        try:
            with open(f"{bat_path}/energy_now") as f:
                energy_now = int(f.read().strip())
            with open(f"{bat_path}/power_now") as f:
                power_now = int(f.read().strip())

            if power_now > 0:
                if status == "Discharging":
                    hours = energy_now / power_now
                elif status == "Charging":
                    with open(f"{bat_path}/energy_full") as f:
                        energy_full = int(f.read().strip())
                    hours = (energy_full - energy_now) / power_now
                else:
                    hours = 0

                if hours > 0:
                    h = int(hours)
                    m = int((hours - h) * 60)
                    time_str = f"{h}:{m:02d}"
        except Exception:
            pass

        return status, percent, time_str, bat_path

    def _get_battery_health(self, bat_path):
        """Get battery health as percentage of design capacity."""
        if self._health_checked:
            return self._battery_health

        self._health_checked = True
        try:
            with open(f"{bat_path}/energy_full") as f:
                energy_full = int(f.read().strip())
            with open(f"{bat_path}/energy_full_design") as f:
                energy_full_design = int(f.read().strip())

            if energy_full_design > 0:
                self._battery_health = int(100 * energy_full / energy_full_design)
            else:
                self._battery_health = None
        except Exception:
            # Try charge_full instead of energy_full (some systems use this)
            try:
                with open(f"{bat_path}/charge_full") as f:
                    charge_full = int(f.read().strip())
                with open(f"{bat_path}/charge_full_design") as f:
                    charge_full_design = int(f.read().strip())

                if charge_full_design > 0:
                    self._battery_health = int(100 * charge_full / charge_full_design)
                else:
                    self._battery_health = None
            except Exception:
                self._battery_health = None

        return self._battery_health

    def _get_color(self, status, percent):
        """Get color based on status and percentage."""
        if status == "Full" or (percent is not None and percent > self.good_threshold):
            return self.py3.COLOR_GOOD
        elif percent is not None and percent < self.degraded_threshold:
            return self.py3.COLOR_BAD
        elif percent is not None and percent < 50:
            return self.py3.COLOR_DEGRADED
        return None

    def battery_cycle(self):
        status, percent, time_str, bat_path = self._get_battery_info()

        # No battery
        if status is None:
            return {
                "full_text": "",
                "cached_until": self.py3.time_in(30)
            }

        color = self._get_color(status, percent)

        # Check battery health
        health = self._get_battery_health(bat_path) if bat_path else None
        needs_service = health is not None and health < self.health_degraded_threshold

        # Determine cycle states based on whether service warning is needed
        if needs_service:
            if time_str:
                cycle_count = 3  # percent, time, service
            else:
                cycle_count = 2  # percent, service
        else:
            if time_str:
                cycle_count = 2  # percent, time
            else:
                cycle_count = 1  # percent only

        self._cycle_state = (self._cycle_state + 1) % cycle_count

        # Full battery
        if status == "Full":
            if needs_service and self._cycle_state == cycle_count - 1:
                service_color = self.py3.COLOR_BAD if health < self.health_bad_threshold else self.py3.COLOR_DEGRADED
                return {
                    "full_text": self.format_service,
                    "color": service_color,
                    "cached_until": self.py3.time_in(self.cycle_interval)
                }
            return {
                "full_text": self.format_full,
                "color": color,
                "cached_until": self.py3.time_in(self.cycle_interval if needs_service else 30)
            }

        # Charging - show percentage or service warning
        if status == "Charging":
            if needs_service and self._cycle_state == cycle_count - 1:
                service_color = self.py3.COLOR_BAD if health < self.health_bad_threshold else self.py3.COLOR_DEGRADED
                return {
                    "full_text": self.format_service,
                    "color": service_color,
                    "cached_until": self.py3.time_in(self.cycle_interval)
                }
            text = self.format_charging.format(percent=percent, time=time_str or "??:??")
            return {
                "full_text": text,
                "color": color,
                "cached_until": self.py3.time_in(self.cycle_interval)
            }

        # Discharging - cycle between percent, time, and service (if needed)
        if needs_service and self._cycle_state == cycle_count - 1:
            service_color = self.py3.COLOR_BAD if health < self.health_bad_threshold else self.py3.COLOR_DEGRADED
            return {
                "full_text": self.format_service,
                "color": service_color,
                "cached_until": self.py3.time_in(self.cycle_interval)
            }
        elif self._cycle_state == 0:
            text = self.format_percent.format(percent=percent, time=time_str or "??:??")
        else:
            text = self.format_time.format(percent=percent, time=time_str or "??:??")

        return {
            "full_text": text,
            "color": color,
            "cached_until": self.py3.time_in(self.cycle_interval)
        }


if __name__ == "__main__":
    from py3status.module_test import module_test
    module_test(Py3status)
