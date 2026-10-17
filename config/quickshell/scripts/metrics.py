"""Small Linux-only collector; native Quickshell services handle desktop state."""

import json
import os
from pathlib import Path
import select
import shutil
import struct
import time


def cpu_times():
    result = []
    for line in Path("/proc/stat").read_text().splitlines():
        if not line.startswith("cpu"):
            break
        values = list(map(int, line.split()[1:9]))
        result.append((sum(values), values[3] + values[4]))
    return result


def cpu_usage(previous, current):
    return [round(100 * (1 - (idle - old_idle) / (total - old_total))) if total > old_total else 0
            for (old_total, old_idle), (total, idle) in zip(previous, current)]


def memory():
    values = {parts[0].rstrip(":"): int(parts[1])
              for line in Path("/proc/meminfo").read_text().splitlines()
              if len(parts := line.split()) >= 2}
    total = values["MemTotal"]
    used = total - values["MemAvailable"]
    return {"memoryUsed": used / 1024**2, "memoryTotal": total / 1024**2,
            "memoryPercent": round(100 * used / total)}


def brightness():
    for device in sorted(Path("/sys/class/backlight").glob("*")):
        try:
            return round(100 * int((device / "brightness").read_text())
                         / int((device / "max_brightness").read_text()))
        except (OSError, ValueError, ZeroDivisionError):
            continue
    return -1


CPU_SENSORS = ("coretemp", "k10temp", "zenpower", "cpu_thermal", "acpitz")


def temperature(root=Path("/sys/class/hwmon")):
    """CPU package temperature in °C, preferring CPU drivers over ACPI zones; -1 if unknown."""
    readings = {}
    for device in root.glob("hwmon*"):
        try:
            name = (device / "name").read_text().strip()
            if name in CPU_SENSORS and name not in readings:
                readings[name] = round(int((device / "temp1_input").read_text()) / 1000)
        except (OSError, ValueError):
            continue
    return next((readings[name] for name in CPU_SENSORS if name in readings), -1)


def airplane(root=Path("/sys/class/rfkill")):
    """True when every radio is soft-blocked (rfkill block all)."""
    states = []
    for device in root.glob("rfkill*"):
        try:
            states.append((device / "soft").read_text().strip() == "1")
        except OSError:
            continue
    return bool(states) and all(states)


class Radios:
    """Soft-block state of every radio, kept current from /dev/rfkill events.
    Opening the device delivers one event per existing radio, and another
    follows each block, unblock, add or removal."""
    EVENT = struct.Struct("=IBBBB")     # index, type, operation, soft, hard
    DELETE = 1

    def __init__(self, fd):
        self.fd = fd
        self.soft = {}
        self.read()

    @classmethod
    def open(cls, path="/dev/rfkill"):
        try:
            return cls(os.open(path, os.O_RDONLY | os.O_NONBLOCK))
        except OSError:
            return None

    def read(self):
        """Applies the pending events; reads one event at a time, as the kernel hands them out."""
        while True:
            try:
                event = os.read(self.fd, self.EVENT.size)
            except BlockingIOError:
                return
            if len(event) < self.EVENT.size:
                return
            index, _type, operation, soft, _hard = self.EVENT.unpack(event)
            if operation == self.DELETE:
                self.soft.pop(index, None)
            else:
                self.soft[index] = bool(soft)

    @property
    def airplane(self):
        return bool(self.soft) and all(self.soft.values())


def caps_lock(root=Path("/sys/class/leds")):
    """True when any keyboard's Caps Lock LED is lit. Hyprland has no event
    for it, and reading the LED is cheaper than asking hyprctl every second."""
    for led in root.glob("*::capslock"):
        try:
            if int((led / "brightness").read_text()) > 0:
                return True
        except (OSError, ValueError):
            continue
    return False


def main():
    previous_cpu = cpu_times()
    radios = Radios.open()      # without /dev/rfkill, airplane mode is read from sysfs each second
    data = {}
    tick = 0
    while True:
        started = time.monotonic()
        current_cpu = cpu_times()
        usage = cpu_usage(previous_cpu, current_cpu)
        data.update(cpu=usage[0], cores=usage[1:], brightness=brightness(),
                    temperature=temperature(), airplane=radios.airplane if radios else airplane())
        data["capsLock"] = caps_lock()
        if tick % 10 == 0:
            data.update(memory())
        if tick % 30 == 0:
            disk = shutil.disk_usage("/")
            data.update(diskPercent=round(100 * disk.used / disk.total),
                        diskUsed=f"{disk.used / 1024**3:.1f} GiB", diskTotal=f"{disk.total / 1024**3:.1f} GiB")
        print(json.dumps(data), flush=True)
        previous_cpu = current_cpu
        tick += 1
        # Wait out the second, but report an airplane mode change as it happens.
        deadline = started + 1
        while (remaining := deadline - time.monotonic()) > 0:
            if not radios:
                time.sleep(max(0.1, remaining))
                break
            ready, _, _ = select.select([radios.fd], [], [], remaining)
            if not ready:
                break
            radios.read()
            if radios.airplane != data["airplane"]:
                data["airplane"] = radios.airplane
                print(json.dumps(data), flush=True)


if __name__ == "__main__":
    main()
