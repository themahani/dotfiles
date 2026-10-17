"""Static/collector checks, plus an opt-in isolated-D-Bus Wayland smoke test."""

import importlib.util
import configparser
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
SHELL = ROOT / "config/quickshell"
spec = importlib.util.spec_from_file_location("metrics", SHELL / "scripts/metrics.py")
metrics = importlib.util.module_from_spec(spec)
spec.loader.exec_module(metrics)


class QuickshellTests(unittest.TestCase):
    def test_material_type_and_icon_fonts(self):
        theme = (SHELL / "theme/Theme.qml").read_text()
        self.assertIn('font: "Roboto"', theme)
        self.assertIn('iconFont: "Material Symbols Rounded"', theme)
        fonts = json.loads((ROOT / "manifests/modules.json").read_text())["fonts"]
        for package in ("ttf-roboto", "ttf-material-symbols-variable"):
            self.assertIn(package, fonts["packages"])
        tooltip = (SHELL / "components/Tooltip.qml").read_text()
        self.assertIn("import QtQuick.Controls as QtControls", tooltip)
        self.assertNotRegex(tooltip, r"import QtQuick.Controls\s*\n")
        self.assertIn("popupType: QtControls.Popup.Window", tooltip)

    def test_theme_roles_match_matugen_template(self):
        theme = (SHELL / "theme/Theme.qml").read_text()
        template = json.loads(re.sub(r"\{\{[^}]+\}\}", "x", (ROOT / "config/matugen/templates/quickshell.json").read_text()))
        fallback = json.loads((SHELL / "theme/fallback.json").read_text())
        roles = set(re.findall(r'role\("(\w+)"\)', theme))
        self.assertEqual(set(template), set(fallback))
        self.assertLessEqual(roles, set(fallback))
        self.assertIn('Quickshell.shellPath("theme/fallback.json")', theme)

    def test_theme_role_names_do_not_parse_as_handlers(self):
        # A property "onX" beside a property "x" is read as a change handler and never binds.
        theme = (SHELL / "theme/Theme.qml").read_text()
        names = set(re.findall(r"property \w+ (\w+)", theme))
        for name in names:
            if name.startswith("on") and len(name) > 2 and name[2].isupper():
                self.assertNotIn(name[2].lower() + name[3:], names, name)

    def test_scaled_tray_icons_and_native_menus(self):
        icons = (SHELL / "bar/TrayIcons.qml").read_text()
        self.assertIn("backer.sourceSize:", icons)
        self.assertIn("screen.devicePixelRatio", icons)
        self.assertIn("mipmap: true", icons)
        self.assertIn('Panels.open = "tray"', icons)
        menu = (SHELL / "panels/TrayMenu.qml").read_text()
        self.assertIn("QsMenuOpener", menu)
        self.assertIn("entry.modelData.triggered()", menu)
        shell = (SHELL / "shell.qml").read_text()
        self.assertNotIn("UseQApplication", shell)
        # Icon names resolve in the GTK icon theme (set with nwg-look / gsettings).
        self.assertIn("//@ pragma DefaultEnv QT_QPA_PLATFORMTHEME = gtk3", shell)

    def test_single_drawer_window_per_output(self):
        shell = (SHELL / "shell.qml").read_text()
        self.assertIn("Reserver { screen: output.modelData }", shell)
        self.assertIn("Drawer { screen: output.modelData }", shell)
        drawer = (SHELL / "bar/Drawer.qml").read_text()
        self.assertIn("exclusionMode: ExclusionMode.Ignore", drawer)
        self.assertIn("mask: surface.active ? null : barInput", drawer)
        self.assertIn("BarSurface {", drawer)
        self.assertIn("HyprlandFocusGrab", drawer)
        lua = (ROOT / "config/hypr/hyprland.lua").read_text()
        self.assertIn("ipc call panels toggle system", lua)
        self.assertNotIn('"quickshell-notifications" }, blur', lua)

    def test_matugen_runs_on_wallpaper_change(self):
        script = (ROOT / "config/hypr/scripts/rofi-hyprpaper.sh").read_text()
        self.assertIn("matugen image --prefer saturation", script)
        config = (ROOT / "config/matugen/config.toml").read_text()
        self.assertIn("~/.local/state/matugen/quickshell.json", config)
        self.assertIn("/.local/state/matugen/quickshell.json", (SHELL / "theme/Theme.qml").read_text())
        desktop = json.loads((ROOT / "manifests/modules.json").read_text())["hyprland-desktop"]
        self.assertEqual(desktop["links"]["$CONFIG/matugen"], "config/matugen")
        self.assertIn("matugen", desktop["packages"])

    def test_desktop_uses_stable_shell_instead_of_legacy_daemons(self):
        desktop = json.loads((ROOT / "manifests/modules.json").read_text())["hyprland-desktop"]
        self.assertEqual(desktop["links"]["$CONFIG/quickshell/desktop"], "config/quickshell")
        self.assertNotIn("$CONFIG/swaync", desktop["links"])
        self.assertIn("quickshell", desktop["packages"])
        for obsolete in ("waybar", "swaync", "pamixer", "quickshell-git"):
            self.assertNotIn(obsolete, desktop["packages"])
        startup = (ROOT / "config/dotfiles/hypr.lua").read_text()
        self.assertIn("quickshell -c desktop --no-duplicate", startup)
        self.assertNotRegex(startup, r'"(?:swaync|waybar)"')

    def test_ipc_scripts_are_executable_and_valid_bash(self):
        for name in ("Volume.sh", "Brightness.sh"):
            path = ROOT / "config/hypr/scripts" / name
            self.assertTrue(os.access(path, os.X_OK))
            subprocess.run(["bash", "-n", str(path)], check=True)
            self.assertIn("quickshell -c desktop ipc call controls", path.read_text())

    def test_cpu_deltas_and_first_sample(self):
        self.assertEqual(metrics.cpu_usage([(100, 30)], [(200, 50)]), [80])
        self.assertEqual(metrics.cpu_usage([(100, 30)], [(100, 30)]), [0])

    def test_temperature_prefers_cpu_sensors(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for index, (name, millidegrees) in enumerate((("acpitz", 40000), ("coretemp", 51500), ("nvme", 33000))):
                device = root / f"hwmon{index}"
                device.mkdir()
                (device / "name").write_text(name + "\n")
                (device / "temp1_input").write_text(str(millidegrees))
            self.assertEqual(metrics.temperature(root), 52)
            self.assertEqual(metrics.temperature(root / "missing"), -1)

    def test_airplane_requires_every_radio_blocked(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertFalse(metrics.airplane(root))
            for index, blocked in enumerate(("1", "0")):
                (root / f"rfkill{index}").mkdir()
                (root / f"rfkill{index}" / "soft").write_text(blocked)
            self.assertFalse(metrics.airplane(root))
            (root / "rfkill1" / "soft").write_text("1")
            self.assertTrue(metrics.airplane(root))

    def test_power_profile_drivers(self):
        text = "  performance:\n    Driver: intel_pstate\n* balanced:\n    CPU Driver: amd_pstate\n    Platform Driver: platform_profile\n"
        self.assertEqual(metrics.parse_profile_drivers(text), {
            "performance": "intel_pstate", "balanced": "amd_pstate, platform_profile"})

    def test_metrics_live_sample(self):
        process = subprocess.Popen([sys.executable, "-B", str(SHELL / "scripts/metrics.py")],
                                   stdout=subprocess.PIPE, text=True)
        try:
            sample = json.loads(process.stdout.readline())
            for key in ("cpu", "cores", "memoryUsed", "memoryTotal", "diskPercent", "brightness", "temperature",
                        "airplane", "keyboard", "interfaces"):
                self.assertIn(key, sample)
            self.assertGreater(sample["memoryTotal"], 0)
            self.assertGreaterEqual(sample["brightness"], -1)
        finally:
            process.terminate()
            process.wait(timeout=5)
            process.stdout.close()

    @unittest.skipUnless(os.environ.get("DOTFILES_TEST_QUICKSHELL") == "1", "opt-in Wayland smoke test")
    def test_wayland_smoke(self):
        for binary in ("quickshell", "dbus-run-session", "notify-send"):
            self.assertIsNotNone(shutil.which(binary))
        self.assertTrue(os.environ.get("WAYLAND_DISPLAY"))
        subprocess.run(["dbus-run-session", "--", sys.executable, "-B", str(Path(__file__)), "--smoke"],
                       check=True, timeout=45)


def smoke():
    """Runs on a private session bus, without replacing the user's notification daemon."""
    env = {**os.environ, "QT_QPA_PLATFORM": "wayland", "QT_NO_XDG_DESKTOP_PORTAL": "1"}
    with tempfile.TemporaryFile(mode="w+", dir="/tmp/opencode") as log:
        process = subprocess.Popen(["quickshell", "-p", str(SHELL), "--no-color"], env=env,
                                   stdout=log, stderr=log)

        def ipc(target, function):
            result = subprocess.run(["quickshell", "-p", str(SHELL), "ipc", "call", target, function],
                                    capture_output=True, text=True, env=env, timeout=5, check=True)
            return result.stdout.strip()

        def state():
            return json.loads(ipc("notifications", "status"))

        try:
            deadline = time.monotonic() + 20
            while True:
                if process.poll() is not None:
                    raise AssertionError("Shell exited before initialization")
                try:
                    state()
                    break
                except (subprocess.SubprocessError, ValueError):
                    if time.monotonic() >= deadline:
                        raise AssertionError("Shell did not initialize")
                    time.sleep(0.2)
            subprocess.run(["notify-send", "-a", "Shell smoke", "Code 123456",
                            '<b>Notification body</b> <font color="black">Readable text</font>'], check=True, env=env)
            time.sleep(0.3)
            assert state()["count"] == 1 and state()["popups"] == 1
            ipc("notifications", "toggle")
            assert state()["centerOpen"]
            ipc("notifications", "toggleDnd")
            subprocess.run(["notify-send", "DND test", "History only"], check=True, env=env)
            time.sleep(0.3)
            assert state()["count"] == 2 and state()["popups"] == 1
            subprocess.run(["notify-send", "-h", "string:x-canonical-private-synchronous:volume_notif",
                            "-h", "int:value:42", "Volume"], check=True, env=env)
            time.sleep(0.3)
            osd = json.loads(ipc("controls", "status"))
            assert osd["osdVisible"] and osd["value"] == 42
            ipc("notifications", "clear")
            assert state()["count"] == 0 and not state()["centerOpen"]
            time.sleep(0.3)
        finally:
            process.terminate()
            process.wait(timeout=5)
            log.seek(0)
            output = log.read()
            print(output)
            assert "Configuration Loaded" in output
            assert "ERROR:" not in output
            assert not re.search(r"(?:TypeError|ReferenceError|Binding loop|Unable to assign|is not a function)", output)


if __name__ == "__main__":
    if "--smoke" in sys.argv:
        smoke()
    else:
        unittest.main()
