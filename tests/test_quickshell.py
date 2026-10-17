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

    def test_labels_render_plain_text(self):
        # Titles, track names and network names come from other people; rich
        # text would fetch their <img> URLs.
        text = (SHELL / "components/StyledText.qml").read_text()
        self.assertIn("textFormat: Text.PlainText", text)
        opted_in = [path.relative_to(SHELL).as_posix() for path in SHELL.rglob("*.qml")
                    if re.search(r"textFormat:\s*Text\.(StyledText|RichText|AutoText|MarkdownText)", path.read_text())]
        self.assertEqual(opted_in, ["panels/NotificationItem.qml"])

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

    def test_workspace_dots_follow_dynamic_workspaces(self):
        dots = (SHELL / "bar/Workspaces.qml").read_text()
        self.assertIn("model: root.slots", dots)
        self.assertIn('Hyprland.dispatch("dynamic_workspaces."', dots)
        self.assertNotIn('workspace = "m', dots)
        lua = (ROOT / "config/hypr/hyprland.lua").read_text()
        self.assertIn('dynamic_workspaces = dofile(configHome .. "/hypr/dynamic-workspaces.lua")', lua)
        self.assertNotIn('workspace = "r', lua)

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

    def test_notification_hints_cannot_draw_osd_or_skip_dnd(self):
        server = (SHELL / "services/Notifications.qml").read_text()
        self.assertNotIn("showOsd", server)
        self.assertNotIn("SWAYNC_BYPASS_DND", server)
        self.assertIn("dnd && item.urgency !== NotificationUrgency.Critical", server)

    def test_notification_history_is_bounded(self):
        server = (SHELL / "services/Notifications.qml").read_text()
        self.assertIn("readonly property int historyLimit: 100", server)
        self.assertIn("older.slice(0, Math.max(0, older.length - (historyLimit - 1))).forEach(other => other.dismiss());", server)
        self.assertIn("delete rest[id];", server)

    def test_notifications_load_nothing_remote(self):
        server = (SHELL / "services/Notifications.qml").read_text()
        self.assertIn("bodyImagesSupported: false", server)
        item = (SHELL / "panels/NotificationItem.qml").read_text()
        self.assertIn("if (Markup.isWebLink(link)) Qt.openUrlExternally(link)", item)
        self.assertIn("Markup.isLocalImage(root.notification.image)", item)
        self.assertIn("Markup.isLocalImage(source)", (SHELL / "panels/AppIcon.qml").read_text())
        if not shutil.which("node"):
            self.skipTest("node is not installed")
        script = (SHELL / "panels/Markup.js").read_text().replace(".pragma library", "") + """
            console.log(JSON.stringify([
                readableBody("<img src='http://x/a.png'>Hi <IMG SRC=x> <b style='color:red'>b</b>"),
                ["https://a", "HTTP://a", "mailto:a@b", "file:///etc/passwd", "steam://run/1", "javascript:x"].map(isWebLink),
                ["/usr/a.png", "file:///a.png", "image://qsimage/1", "https://a/b.png", "ftp://a"].map(isLocalImage),
            ]));"""
        result = subprocess.run(["node", "-e", script], capture_output=True, text=True, check=True)
        body, links, images = json.loads(result.stdout)
        self.assertEqual(body, "Hi  <b>b</b>")
        self.assertEqual(links, [True, True, True, False, False, False])
        self.assertEqual(images, [True, True, True, False, False])

    def test_bluetooth_pairing_goes_through_the_agent(self):
        agent = (SHELL / "services/BluetoothAgent.qml").read_text()
        self.assertIn('command: ["bluetoothctl", "--agent", "KeyboardDisplay"]', agent)
        self.assertIn('onStarted: write("default-agent\\n")', agent)
        self.assertIn("if (Lock.locked) cancel();", agent)
        self.assertIn("property var bluetoothAgent: BluetoothAgent", (SHELL / "shell.qml").read_text())
        page = (SHELL / "panels/BluetoothPage.qml").read_text()
        self.assertIn("BluetoothAgent.ready) candidate.modelData.pair()", page)
        self.assertIn("PairingPrompt", page)

    def test_lock_screen_is_password_only_and_ipc_cannot_unlock(self):
        lock = (SHELL / "services/Lock.qml").read_text()
        ipc = lock[lock.index("IpcHandler"):]
        self.assertIn("function lock()", ipc)
        self.assertNotIn("unlock", ipc.lower())
        # The fingerprint budget spans the whole lock, not one PAM session.
        self.assertIn("fingerprintMisses = 0;", lock[lock.index("function lock()"):lock.index("function unlock()")])
        self.assertIn("if (fingerprintMisses >= fingerprintTries) { fingerprint = \"exhausted\"; return; }", lock)
        # The scan only stays open while someone is at the lock screen, so a
        # suspend rarely finds it open and wedges fprintd.
        self.assertIn('if (!present) { fingerprint = "paused"; return; }', lock)
        self.assertIn("interval: 30000", lock[lock.index("id: presence"):])
        self.assertIn("Keys.onPressed: event => { Lock.activity(); event.accepted = false; }",
                      (SHELL / "lock/PasswordField.qml").read_text())
        surface = (SHELL / "lock/LockSurface.qml").read_text()
        self.assertIn("if (p.x === lastX && p.y === lastY) return;", surface)
        self.assertIn("Lock.activity();", surface[surface.index("HoverHandler"):])
        # A reload while locked would release the session.
        self.assertIn('Binding { target: Quickshell; property: "watchFiles"; value: !root.locked }', lock)
        self.assertIn('configDirectory: Quickshell.shellPath("lock/pam")', lock)
        pam = (SHELL / "lock/pam/password").read_text()
        rules = [line for line in pam.splitlines() if line.strip() and not line.startswith("#")]
        self.assertTrue(any("pam_unix.so" in line for line in rules))
        self.assertTrue(any("pam_faillock.so" in line and "authfail" in line for line in rules))
        self.assertFalse(any("fprintd" in line for line in rules))
        # Fingerprint runs as its own stack in parallel, never inside the password one.
        finger = (SHELL / "lock/pam/fingerprint").read_text()
        self.assertRegex(finger, r"(?m)^auth\s+required\s+pam_fprintd\.so\s+max-tries=5 timeout=-1$")
        self.assertIn('config: "fingerprint"', lock)
        self.assertEqual(lock.count("PamContext {"), 2)
        surface = (SHELL / "lock/LockSurface.qml").read_text()
        self.assertIn("BarSurface { anchors.fill: parent; screen: surface.screen; locked: true }", surface)
        idle = (ROOT / "config/hypr/hypridle.conf").read_text()
        self.assertIn("lock_cmd = pgrep -x quickshell >/dev/null || pidof hyprlock || hyprlock", idle)
        self.assertRegex(idle, r"(?m)^\s*inhibit_sleep = 3\b")
        # The shell locks on logind's signals and holds suspend until the lock is shown.
        self.assertIn('"systemd-inhibit", "--no-ask-password", "--what=sleep", "--mode=delay"', lock)
        # Long-lived helpers end with the shell, so a crash leaves no inhibitor behind.
        self.assertIn('"--why=Lock the screen before sleep", "cat"]\n        stdinEnabled: true', lock)
        self.assertIn('["setpriv", "--pdeathsig", "TERM", "gdbus", "monitor"', lock)
        self.assertIn("function updateSleepDelay() { sleepDelay.running = !(locked && secure); }", lock)
        self.assertIn('line.startsWith(root.sessionPath + ": org.freedesktop.login1.Session.Lock ")', lock)
        self.assertIn("org.freedesktop.login1.Session.SetLockedHint", lock)
        self.assertIn('Binding { target: Lock; property: "secure"; value: lock.secure }',
                      (SHELL / "lock/LockScreen.qml").read_text())
        hyprland = (ROOT / "config/hypr/hyprland.lua").read_text()
        self.assertIn('"+ escape", hl.dsp.exec_cmd("loginctl lock-session")', hyprland)
        self.assertIn("session_lock_xray = false", hyprland)

    def test_session_menu_replaces_wlogout(self):
        session = (SHELL / "services/Session.qml").read_text()
        # wlogout's keys and commands carry over.
        for key, command in (("l", '["loginctl", "lock-session"]'), ("r", '["systemctl", "reboot"]'),
                             ("s", '["systemctl", "poweroff"]'), ("e", '["hyprshutdown"]'),
                             ("u", '["systemctl", "suspend"]'), ("h", '["systemctl", "hibernate"]')):
            self.assertRegex(session, rf'key: "{key}",[^\n]*command: {re.escape(command)}')
        self.assertIn("if (Lock.locked) return;", session)
        self.assertIn("CanHibernate", session)
        ipc = session[session.index("IpcHandler"):]
        self.assertNotIn("function run", ipc)
        # The power sheet and the lock screen pick from the same list.
        sheet = (SHELL / "panels/PowerSheet.qml").read_text()
        lock_controls = (SHELL / "panels/LockControls.qml").read_text()
        self.assertIn('Session.pick(["lock", "suspend", "logout", "reboot", "shutdown"])', sheet)
        self.assertIn('Session.pick(["suspend", "reboot", "shutdown"])', lock_controls)
        for panel in (sheet, lock_controls):
            self.assertIn("Session.run(action.modelData.id);", panel)
            self.assertNotIn("command:", panel)
        menu = (SHELL / "session/SessionMenu.qml").read_text()
        self.assertIn("WlrKeyboardFocus.Exclusive", menu)
        self.assertIn("event.key === Qt.Key_Escape) Session.close()", menu)
        self.assertIn("SessionMenu {}", (SHELL / "shell.qml").read_text())
        hyprland = (ROOT / "config/hypr/hyprland.lua").read_text()
        self.assertIn('"+ X", hl.dsp.exec_cmd("quickshell -c desktop ipc call session toggle")', hyprland)
        self.assertNotIn("wlogout", hyprland)
        self.assertFalse((ROOT / "config/wlogout").exists())

    @unittest.skipUnless(Path("/etc/pam.d/system-auth").exists(), "no system-auth on this system")
    def test_lock_pam_matches_system_auth(self):
        # The lock reads its own PAM files; a system policy change must not
        # silently skip the lock screen.
        def rules(path, *types):
            return [" ".join(line.split()) for line in Path(path).read_text().splitlines()
                    if line.split() and line.split()[0].lstrip("-") in types]
        system = "/etc/pam.d/system-auth"
        self.assertEqual(rules(SHELL / "lock/pam/password", "auth", "account"), rules(system, "auth", "account"))
        self.assertEqual(rules(SHELL / "lock/pam/fingerprint", "account"), rules(system, "account"))

    def test_matugen_runs_on_wallpaper_change(self):
        script = (ROOT / "config/hypr/scripts/rofi-hyprpaper.sh").read_text()
        self.assertIn('"$HOME/.config/matugen/wallpaper.py" "$new_wallpaper"', script)
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

    def test_airplane_follows_rfkill_events(self):
        read, write = os.pipe2(os.O_NONBLOCK)
        try:
            event = metrics.Radios.EVENT
            # The kernel announces each radio on open: index, type, operation (0 add), soft, hard.
            os.write(write, event.pack(0, 2, 0, 1, 0) + event.pack(1, 1, 0, 0, 0))
            radios = metrics.Radios(read)
            self.assertFalse(radios.airplane)
            os.write(write, event.pack(1, 1, 2, 1, 0))      # wlan soft-blocked
            radios.read()
            self.assertTrue(radios.airplane)
            os.write(write, event.pack(2, 2, 0, 0, 0))      # a new, unblocked radio
            radios.read()
            self.assertFalse(radios.airplane)
            os.write(write, event.pack(2, 2, metrics.Radios.DELETE, 0, 0))
            radios.read()
            self.assertTrue(radios.airplane)
        finally:
            os.close(read)
            os.close(write)
        self.assertIsNone(metrics.Radios.open("/nonexistent/rfkill"))

    def test_backlight_reads_the_first_usable_device(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertIsNone(metrics.Backlight.open(root))
            for name, maximum, actual in (("acpi_video0", "0", "0"), ("intel_backlight", "200", "50")):
                (root / name).mkdir()
                (root / name / "max_brightness").write_text(maximum + "\n")
                (root / name / "actual_brightness").write_text(actual + "\n")
            backlight = metrics.Backlight.open(root)
            self.assertEqual(backlight.value, 25)
            (root / "intel_backlight" / "actual_brightness").write_text("200\n")
            backlight.read()
            self.assertEqual(backlight.value, 100)
            backlight.file.close()

    def test_shell_renders_on_the_gui_thread(self):
        self.assertRegex((SHELL / "shell.qml").read_text(), r"(?m)^//@ pragma Env QSG_RENDER_LOOP = basic$")

    def test_metrics_notify_only_changed_values(self):
        metrics_qml = (SHELL / "services/Metrics.qml").read_text()
        self.assertIn("if (key in sample) root[key] = sample[key];", metrics_qml)
        # Updates between samples (brightness, airplane mode) add no history.
        self.assertIn("if (sample.sample === lastSample) return;", metrics_qml)
        self.assertIn('data["sample"] = tick', (SHELL / "scripts/metrics.py").read_text())
        self.assertIn('text: Metrics.cpuAverage + "%"', (SHELL / "bar/StatsButton.qml").read_text())
        for path in SHELL.rglob("*.qml"):
            self.assertNotIn("Metrics.data", path.read_text(), path.name)

    def test_media_position_is_polled_only_while_shown(self):
        players = (SHELL / "services/Players.qml").read_text()
        self.assertIn('readonly property bool positionShown: Panels.open === "media" || Lock.locked', players)
        self.assertIn("running: root.player !== null && root.player.isPlaying && root.positionShown", players)
        # Nothing outside the media panel and the lock screen's player reads the position.
        for path in SHELL.rglob("*.qml"):
            if path.name not in ("MediaPanel.qml", "LockMedia.qml", "Players.qml"):
                self.assertNotIn(".position", path.read_text(), path.name)

    def test_caps_lock_follows_any_keyboard_led(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertFalse(metrics.caps_lock(root))
            for name, lit in (("input3::capslock", "0"), ("input7::capslock", "0"), ("input3::numlock", "1")):
                (root / name).mkdir()
                (root / name / "brightness").write_text(lit + "\n")
            self.assertFalse(metrics.caps_lock(root))
            (root / "input7::capslock" / "brightness").write_text("1\n")
            self.assertTrue(metrics.caps_lock(root))

    def test_keyboard_layout_follows_hyprland_events(self):
        keyboard = (SHELL / "services/Keyboard.qml").read_text()
        self.assertIn('event.name === "activelayout" || event.name === "configreloaded"', keyboard)
        # The collector reads files only; it starts no processes.
        self.assertNotIn("subprocess", (SHELL / "scripts/metrics.py").read_text())
        self.assertIn("Keyboard.name", (SHELL / "bar/LayoutButton.qml").read_text())

    def test_metrics_live_sample(self):
        process = subprocess.Popen([sys.executable, "-B", str(SHELL / "scripts/metrics.py")],
                                   stdout=subprocess.PIPE, text=True)
        try:
            sample = json.loads(process.stdout.readline())
            for key in ("cpu", "cores", "memoryUsed", "memoryTotal", "diskPercent", "brightness", "temperature",
                        "airplane", "capsLock", "sample"):
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
            # Hints can neither draw the OSD nor get past DND; critical can.
            subprocess.run(["notify-send", "-h", "string:x-canonical-private-synchronous:volume_notif",
                            "-h", "int:value:42", "-h", "boolean:SWAYNC_BYPASS_DND:true", "Volume"], check=True, env=env)
            time.sleep(0.3)
            assert not json.loads(ipc("controls", "status"))["osdVisible"]
            assert state()["count"] == 3 and state()["popups"] == 1
            subprocess.run(["notify-send", "-u", "critical", "Critical", "Pops up"], check=True, env=env)
            time.sleep(0.3)
            assert state()["popups"] == 2
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
