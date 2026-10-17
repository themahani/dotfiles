"""Small Linux-only collector; native Quickshell services handle desktop state."""

import json
from pathlib import Path
import re
import shutil
import subprocess
import time


def command_json(arguments, fallback):
    try:
        result = subprocess.run(arguments, capture_output=True, text=True, timeout=2, check=True)
        return json.loads(result.stdout)
    except (OSError, subprocess.SubprocessError, ValueError):
        return fallback


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


def keyboard():
    devices = command_json(["hyprctl", "-j", "devices"], {})
    main = next((item for item in devices.get("keyboards", []) if item.get("main")), {})
    return {"keyboard": main.get("active_keymap", ""), "keyboardName": main.get("name", "")}


def parse_profile_drivers(text):
    drivers = {}
    profile = None
    for line in text.splitlines():
        header = re.match(r"\s*\*?\s*(performance|balanced|power-saver):", line)
        if header:
            profile = header[1]
        elif profile and "Driver:" in line:
            driver = line.split("Driver:", 1)[1].strip()
            drivers[profile] = ", ".join(filter(None, [drivers.get(profile), driver]))
    return drivers


def profile_drivers():
    try:
        result = subprocess.run(["powerprofilesctl", "list"], capture_output=True,
                                text=True, timeout=2, check=True)
        return parse_profile_drivers(result.stdout)
    except (OSError, subprocess.SubprocessError):
        return {}


def interfaces(previous, elapsed):
    addresses = command_json(["ip", "-j", "address"], [])
    result, counters = {}, {}
    for device in addresses:
        name = device["ifname"]
        try:
            path = Path("/sys/class/net") / name / "statistics"
            rx, tx = (int((path / f"{direction}_bytes").read_text()) for direction in ("rx", "tx"))
        except (OSError, ValueError):
            continue
        old_rx, old_tx = previous.get(name, (rx, tx))
        counters[name] = (rx, tx)
        result[name] = {
            "ip": ", ".join(item["local"] for item in device.get("addr_info", []) if item["scope"] == "global"),
            "down": max(0, (rx - old_rx) * 8 / elapsed),
            "up": max(0, (tx - old_tx) * 8 / elapsed),
        }
    return result, counters


def main():
    previous_cpu = cpu_times()
    previous_net = {}
    previous_time = time.monotonic()
    data = {}
    tick = 0
    while True:
        started = time.monotonic()
        current_cpu = cpu_times()
        usage = cpu_usage(previous_cpu, current_cpu)
        data.update(cpu=usage[0], cores=usage[1:], brightness=brightness(),
                    temperature=temperature(), airplane=airplane())
        data.update(keyboard())
        if tick % 10 == 0:
            data.update(memory())
        if tick % 30 == 0:
            disk = shutil.disk_usage("/")
            data.update(diskPercent=round(100 * disk.used / disk.total),
                        diskUsed=f"{disk.used / 1024**3:.1f} GiB", diskTotal=f"{disk.total / 1024**3:.1f} GiB")
            data["profileDrivers"] = profile_drivers()
        data["interfaces"], previous_net = interfaces(previous_net, max(0.01, started - previous_time))
        print(json.dumps(data), flush=True)
        previous_cpu, previous_time = current_cpu, started
        tick += 1
        time.sleep(max(0.1, 1 - (time.monotonic() - started)))


if __name__ == "__main__":
    main()
