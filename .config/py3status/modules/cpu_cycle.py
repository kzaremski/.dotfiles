"""
CPU module that cycles between usage percentage and temperature.

Configuration parameters:
    cycle_interval: Seconds between cycling display (default 2)
    temp_sensor: Sensor name to use (default "coretemp", falls back to others)
    format_usage: Format string for usage display (default "CPU {usage}%")
    format_temp: Format string for temp display (default "CPU {temp}°C")
    degraded_threshold: Usage % to show degraded color (default 75)
    max_threshold: Usage % to show bad color (default 90)
"""

import os


class Py3status:
    cycle_interval = 2
    temp_sensor = "coretemp"
    format_usage = "CPU {usage}%"
    format_temp = "CPU {temp}°C"
    degraded_threshold = 75
    max_threshold = 90
    temp_degraded = 75
    temp_max = 90

    def post_config_hook(self):
        self._cycle_state = 0
        self._temp_path = self._find_temp_sensor()

    def _find_temp_sensor(self):
        """Find the correct hwmon path for CPU temperature."""
        hwmon_base = "/sys/class/hwmon"
        # Preferred sensors in order (coretemp is Intel CPU, k10temp is AMD)
        preferred = [self.temp_sensor, "coretemp", "k10temp", "thinkpad", "acpitz"]

        for sensor in preferred:
            for hwmon in os.listdir(hwmon_base):
                name_path = os.path.join(hwmon_base, hwmon, "name")
                try:
                    with open(name_path) as f:
                        if f.read().strip() == sensor:
                            temp_path = os.path.join(hwmon_base, hwmon, "temp1_input")
                            if os.path.exists(temp_path):
                                return temp_path
                except Exception:
                    continue
        return None

    def _get_cpu_usage(self):
        """Get CPU usage percentage."""
        try:
            with open("/proc/stat") as f:
                line = f.readline()

            if not hasattr(self, '_prev_idle') or not hasattr(self, '_prev_total'):
                # First run - initialize and return 0
                parts = line.split()[1:]
                idle = int(parts[3])
                total = sum(int(p) for p in parts)
                self._prev_idle = idle
                self._prev_total = total
                return 0

            parts = line.split()[1:]
            idle = int(parts[3])
            total = sum(int(p) for p in parts)

            diff_idle = idle - self._prev_idle
            diff_total = total - self._prev_total

            self._prev_idle = idle
            self._prev_total = total

            if diff_total == 0:
                return 0

            usage = 100 * (diff_total - diff_idle) / diff_total
            return round(usage)
        except Exception:
            return 0

    def _get_temp(self):
        """Get CPU temperature. Returns None if not available."""
        if not self._temp_path:
            return None
        try:
            with open(self._temp_path) as f:
                temp = int(f.read().strip()) // 1000
            if temp <= 0:
                return None
            return temp
        except Exception:
            return None

    def _get_color(self, usage, temp=None):
        """Get color based on worst of usage or temperature."""
        # 0 = good, 1 = degraded, 2 = bad
        usage_level = 0
        temp_level = 0

        if usage >= self.max_threshold:
            usage_level = 2
        elif usage >= self.degraded_threshold:
            usage_level = 1

        if temp is not None:
            if temp >= self.temp_max:
                temp_level = 2
            elif temp >= self.temp_degraded:
                temp_level = 1

        # Use the worst of the two
        worst = max(usage_level, temp_level)
        if worst == 2:
            return self.py3.COLOR_BAD
        elif worst == 1:
            return self.py3.COLOR_DEGRADED
        return None

    def cpu_cycle(self):
        usage = self._get_cpu_usage()
        temp = self._get_temp()

        # Only cycle if temp is available
        if temp is not None:
            self._cycle_state = (self._cycle_state + 1) % 2
            if self._cycle_state == 1:
                text = self.format_temp.format(usage=usage, temp=temp)
            else:
                text = self.format_usage.format(usage=usage, temp=temp)
        else:
            # No temp available, only show usage
            text = self.format_usage.format(usage=usage, temp=0)

        return {
            "full_text": text,
            "color": self._get_color(usage, temp),
            "cached_until": self.py3.time_in(self.cycle_interval)
        }


if __name__ == "__main__":
    from py3status.module_test import module_test
    module_test(Py3status)
