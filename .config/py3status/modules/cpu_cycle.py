"""
CPU module that cycles between usage percentage and temperature.

Configuration parameters:
    cycle_interval: Seconds between cycling display (default 2)
    temp_path: Path to temperature sensor (default "/sys/class/hwmon/hwmon4/temp1_input")
    format_usage: Format string for usage display (default "CPU {usage}%")
    format_temp: Format string for temp display (default "CPU {temp}°C")
    degraded_threshold: Usage % to show degraded color (default 75)
    max_threshold: Usage % to show bad color (default 90)
"""


class Py3status:
    cycle_interval = 2
    temp_path = "/sys/class/hwmon/hwmon4/temp1_input"
    format_usage = "CPU {usage}%"
    format_temp = "CPU {temp}°C"
    degraded_threshold = 75
    max_threshold = 90

    def post_config_hook(self):
        self._cycle_state = 0

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
        try:
            with open(self.temp_path) as f:
                temp = int(f.read().strip()) // 1000
            if temp <= 0:
                return None
            return temp
        except Exception:
            return None

    def _get_color(self, usage):
        """Get color based on usage threshold."""
        if usage >= self.max_threshold:
            return self.py3.COLOR_BAD
        elif usage >= self.degraded_threshold:
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
            "color": self._get_color(usage),
            "cached_until": self.py3.time_in(self.cycle_interval)
        }


if __name__ == "__main__":
    from py3status.module_test import module_test
    module_test(Py3status)
