"""Verify first-start status modules without modifying the user's tmux server."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
TEST_TMP = "/tmp/opencode" if os.access("/tmp/opencode", os.W_OK) else None
PLUGINS = Path.home() / ".tmux/plugins"
REQUIRED = ("tpm/tpm", "tmux/catppuccin.tmux", "tmux-cpu/cpu.tmux", "tmux-battery/battery.tmux")


@unittest.skipUnless(shutil.which("tmux"), "tmux is required for startup validation")
@unittest.skipUnless(all((PLUGINS / name).is_file() for name in REQUIRED),
                     "Install TPM, Catppuccin, CPU, and battery plugins for startup validation")
class TmuxTests(unittest.TestCase):
    def test_cpu_and_battery_load_on_first_start_and_survive_reload(self):
        with tempfile.TemporaryDirectory(prefix="dotfiles-tmux-", dir=TEST_TMP) as temporary:
            # Every command targets this socket; plugin subprocesses inherit its
            # TMUX environment from run-shell, never the user's active server.
            command = ["tmux", "-S", str(Path(temporary) / "server.sock")]
            env = {key: value for key, value in os.environ.items() if key not in ("TMUX", "TMUX_PANE")}
            env["SHELL"] = "/bin/sh"  # Do not start interactive shells/plugin managers.
            env.setdefault("TERM", "xterm-256color")
            config = str(ROOT / "tmux/tmux.conf")

            def run(*args):
                return subprocess.run(command + list(args), env=env, text=True,
                                      capture_output=True, check=True, timeout=30).stdout.strip()

            try:
                run("-f", config, "new-session", "-d", "-s", "startup-test", "sleep 120")
                initial = run("show-options", "-gqv", "status-right")
                self.assertIn("/tmux-cpu/scripts/cpu_percentage.sh", initial)
                self.assertIn("/tmux-battery/scripts/battery_percentage.sh", initial)
                self.assertIn("/tmux-battery/scripts/battery_icon.sh", initial)
                self.assertNotIn("#{cpu_percentage}", initial)
                self.assertNotIn("#{battery_percentage}", initial)

                run("source-file", config)
                reloaded = run("show-options", "-gqv", "status-right")
                self.assertEqual(initial, reloaded, "Reload changed/duplicated startup status modules")
            finally:
                subprocess.run(command + ["kill-server"], env=env, capture_output=True, timeout=10)


if __name__ == "__main__":
    unittest.main()
