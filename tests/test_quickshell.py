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
    def test_readable_text_and_scaled_tray_icons(self):
        theme = (SHELL / "theme/Theme.qml").read_text()
        self.assertIn('fontFamily: "Ubuntu Nerd Font"', theme)
        self.assertIn("letterSpacing: 0.5", theme)
        self.assertIn("font.letterSpacing: Theme.letterSpacing", (SHELL / "components/Label.qml").read_text())
        for path in ("components/Chip.qml", "notifications/ControlCenter.qml"):
            text = (SHELL / path).read_text()
            self.assertIn("import QtQuick.Controls as QtControls", text)
            self.assertNotRegex(text, r"import QtQuick.Controls\s*\n")
        chip = (SHELL / "components/Chip.qml").read_text()
        self.assertIn("popupType: QtControls.Popup.Window", chip)
        self.assertIn("y: root.height + 12", chip)
        tray = (SHELL / "bar/Tray.qml").read_text()
        self.assertIn("IconImage {", tray)
        self.assertIn("backer.sourceSize:", tray)
        self.assertIn("screen.devicePixelRatio", tray)
        self.assertIn("mipmap: true", tray)
        fonts = json.loads((ROOT / "manifests/modules.json").read_text())["fonts"]
        self.assertIn("ttf-ubuntu-nerd", fonts["packages"])

    def test_original_palette_is_preserved(self):
        old = (ROOT / "config/waybar/styles/catppuccin/mocha.css").read_text()
        new = (SHELL / "theme/Theme.qml").read_text()
        for name, value in re.findall(r"@define-color\s+(\w+)\s+(#[\da-f]+)", old):
            self.assertIn(f'color {name}: "{value}"', new)

    def test_tray_menus_have_application_support_and_compact_spacing(self):
        self.assertTrue((SHELL / "shell.qml").read_text().startswith("//@ pragma UseQApplication\n"))
        tray = (SHELL / "bar/Tray.qml").read_text()
        self.assertIn("spacing: 2", tray)
        self.assertIn("width: 26; height: 30", tray)
        self.assertIn("item.modelData.hasMenu &&", tray)
        self.assertIn("if (menu.visible) menu.close();", tray)

    def test_native_menu_theme(self):
        shell = (SHELL / "shell.qml").read_text()
        self.assertIn("//@ pragma RespectSystemStyle", shell)
        self.assertIn("//@ pragma DefaultEnv QT_QPA_PLATFORMTHEME = qt6ct", shell)
        settings = configparser.ConfigParser()
        settings.read(ROOT / "config/qt6ct/qt6ct.conf")
        self.assertEqual(settings["Appearance"]["custom_palette"], "true")
        self.assertIn("catppuccin-mocha-blue.conf", settings["Appearance"]["color_scheme_path"])
        palette = configparser.ConfigParser()
        palette.read(ROOT / "config/qt6ct/colors/catppuccin-mocha-blue.conf")
        for group in ("active_colors", "inactive_colors", "disabled_colors"):
            colors = [value.strip() for value in palette["ColorScheme"][group].split(",")]
            self.assertEqual(len(colors), 22)
            self.assertTrue(all(re.fullmatch(r"#[0-9a-f]{8}", color) for color in colors))
        active = [value.strip() for value in palette["ColorScheme"]["active_colors"].split(",")]
        self.assertEqual(active[6], "#ffcdd6f4")  # Text
        self.assertEqual(active[10], "#ff181825")  # Window
        self.assertEqual(active[12], "#ff89b4fa")  # Highlight
        desktop = json.loads((ROOT / "manifests/modules.json").read_text())["hyprland-desktop"]
        self.assertIn("qt6ct", desktop["packages"])
        self.assertIn("$CONFIG/qt6ct/qt6ct.conf", desktop["links"])

    def test_native_menu_frame_matches_tooltip(self):
        settings = configparser.ConfigParser()
        settings.read(ROOT / "config/qt6ct/qt6ct.conf")
        stylesheet = ROOT / "config/qt6ct/qss/tray-menus.qss"
        self.assertEqual(Path(settings["Appearance"]["stylesheets"]), stylesheet)
        qss = stylesheet.read_text()
        tooltip = (SHELL / "components/Chip.qml").read_text()
        self.assertIn("border: 1px solid #6c7086", qss)
        self.assertIn("border-radius: 8px", qss)
        self.assertIn("background-color: #181825", qss)
        self.assertIn("border.width: 1", tooltip)
        self.assertIn("border.color: Theme.overlay0", tooltip)
        self.assertIn("radius: 8", tooltip)

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

    def test_power_profile_drivers(self):
        text = "  performance:\n    Driver: intel_pstate\n* balanced:\n    CPU Driver: amd_pstate\n    Platform Driver: platform_profile\n"
        self.assertEqual(metrics.parse_profile_drivers(text), {
            "performance": "intel_pstate", "balanced": "amd_pstate, platform_profile"})

    def test_metrics_live_sample(self):
        process = subprocess.Popen([sys.executable, "-B", str(SHELL / "scripts/metrics.py")],
                                   stdout=subprocess.PIPE, text=True)
        try:
            sample = json.loads(process.stdout.readline())
            for key in ("cpu", "cores", "memoryUsed", "memoryTotal", "diskPercent", "brightness", "keyboard", "interfaces"):
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
