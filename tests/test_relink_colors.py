"""Broken-link repair is opt-in and reversible; ANSI logging is controllable."""

import contextlib
import importlib.util
import io
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
loader = importlib.util.spec_from_file_location("bootstrap", ROOT / "bootstrap.py")
bootstrap = importlib.util.module_from_spec(loader)
loader.loader.exec_module(bootstrap)
TEST_TMP = "/tmp/opencode" if os.access("/tmp/opencode", os.W_OK) else None


class RelinkTests(unittest.TestCase):
    def test_broken_link_repair_and_restore(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as temporary:
            home = Path(temporary)
            target = home / ".bashrc"
            original = home / "old-checkout/bash/.bashrc"
            target.symlink_to(original)
            spec = {"profile": "repair-test", "links": [
                {"destination": str(target), "source": str(ROOT / "bash/.bashrc")}
            ], "directories": []}
            self.assertEqual(bootstrap.inspect_spec(spec)[0]["action"], "conflict")
            self.assertEqual(bootstrap.inspect_spec(spec, relink=True)[0]["action"], "relink")
            state = home / "state"
            with patch.object(bootstrap, "ensure_submodules"), contextlib.redirect_stdout(io.StringIO()):
                bootstrap.apply(spec, state, False, relink=True)
                self.assertTrue(bootstrap.same_link(target, ROOT / "bash/.bashrc"))
                journals = list((state / "transactions").glob("*/journal.json"))
                bootstrap.apply(spec, state, False, relink=True)
                self.assertEqual(journals, list((state / "transactions").glob("*/journal.json")))
                self.assertTrue(bootstrap.restore_journal(journals[0]))
            self.assertEqual(os.readlink(target), str(original))

    def test_relink_does_not_replace_files_valid_links_or_missing_sources(self):
        with tempfile.TemporaryDirectory(dir=TEST_TMP) as temporary:
            home = Path(temporary)
            file = home / "file"
            file.write_text("user data")
            valid = home / "valid"
            valid.symlink_to(file)
            broken = home / "broken"
            broken.symlink_to(home / "old")
            spec = {"links": [
                {"destination": str(file), "source": str(ROOT / "bash/.bashrc")},
                {"destination": str(valid), "source": str(ROOT / "bash/.bashrc")},
                {"destination": str(broken), "source": str(home / "missing")},
            ]}
            self.assertEqual([entry["action"] for entry in bootstrap.inspect_spec(spec, True)],
                             ["conflict", "conflict", "conflict"])


class ColorTests(unittest.TestCase):
    def test_forced_color_uses_ansi_escape_and_reset(self):
        output = io.StringIO()
        with patch.object(bootstrap, "COLOR_MODE", "always"):
            bootstrap.log("Done", "success", file=output)
        self.assertEqual(output.getvalue(), "\033[32mDone\033[0m\n")

    def test_non_terminal_auto_and_never_are_plain(self):
        for mode in ("auto", "never"):
            output = io.StringIO()
            with patch.object(bootstrap, "COLOR_MODE", mode):
                bootstrap.log("Warning", "warning", file=output)
            self.assertEqual(output.getvalue(), "Warning\n")

    def test_no_color_disables_auto_in_a_terminal(self):
        output = io.StringIO()
        with patch.object(bootstrap, "COLOR_MODE", "auto"), patch.object(output, "isatty", return_value=True), \
                patch.dict(os.environ, {"NO_COLOR": "1"}):
            bootstrap.log("Error", "error", file=output)
        self.assertEqual(output.getvalue(), "Error\n")


if __name__ == "__main__":
    unittest.main()
