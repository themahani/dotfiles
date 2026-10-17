"""No changes to the real home, package database, or submodule revisions."""

import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
TEST_TMP = "/tmp/opencode" if os.access("/tmp/opencode", os.W_OK) else None
loader = importlib.util.spec_from_file_location("bootstrap", ROOT / "bootstrap.py")
bootstrap = importlib.util.module_from_spec(loader)
loader.loader.exec_module(bootstrap)


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-test-", dir=TEST_TMP)
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name) / "home"
        self.home.mkdir()
        self.state = self.home / ".local/state/dotfiles"
        self.spec = bootstrap.build_spec("minimal", [], self.home, self.home / ".config")
        self.output = io.StringIO()
        self.redirect = contextlib.redirect_stdout(self.output)
        self.redirect.__enter__()
        self.addCleanup(self.redirect.__exit__, None, None, None)

    def apply(self, backup=False):
        # Use the real Dotbot but do not initialize/update any repository data.
        with patch.object(bootstrap, "ensure_submodules"), patch.dict(os.environ, {"HOME": str(self.home)}):
            bootstrap.apply(self.spec, self.state, backup)

    def journal(self):
        return next((self.state / "transactions").glob("*/journal.json"))

    def test_plan_is_read_only(self):
        before = sorted(self.home.rglob("*"))
        result = bootstrap.main(["plan", "--profile", "minimal", "--home", str(self.home)])
        self.assertEqual(result, 0)
        self.assertEqual(before, sorted(self.home.rglob("*")))

    def test_modules_accepts_multiple_names(self):
        result = bootstrap.main(["plan", "--profile", "minimal", "--modules", "neovim", "tmux",
                                 "--home", str(self.home)])
        self.assertEqual(result, 0)
        expected = list(dict.fromkeys(self.spec["modules"] + ["neovim", "tmux"]))
        self.assertIn("Modules: " + ", ".join(expected), self.output.getvalue())
        self.assertEqual(list(self.home.iterdir()), [])

    def test_modules_accepts_one_name(self):
        result = bootstrap.main(["plan", "--profile", "minimal", "--modules", "tmux",
                                 "--home", str(self.home)])
        self.assertEqual(result, 0)
        expected = list(dict.fromkeys(self.spec["modules"] + ["tmux"]))
        self.assertIn("Modules: " + ", ".join(expected), self.output.getvalue())

    def test_modules_can_be_repeated(self):
        result = bootstrap.main(["plan", "--profile", "minimal", "--modules", "neovim", "tmux",
                                 "--modules", "music", "--home", str(self.home)])
        self.assertEqual(result, 0)
        expected = list(dict.fromkeys(self.spec["modules"] + ["neovim", "tmux", "music"]))
        self.assertIn("Modules: " + ", ".join(expected), self.output.getvalue())

    def test_modules_requires_at_least_one_name(self):
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as error:
            bootstrap.main(["plan", "--modules"])
        self.assertEqual(error.exception.code, 2)

    def test_modules_rejects_unknown_names(self):
        errors = io.StringIO()
        with contextlib.redirect_stderr(errors):
            result = bootstrap.main(["plan", "--profile", "minimal", "--modules", "not-a-module",
                                     "--home", str(self.home)])
        self.assertEqual(result, 1)
        self.assertIn("Unknown module: not-a-module", errors.getvalue())
        self.assertEqual(list(self.home.iterdir()), [])

    def test_apply_and_restore(self):
        self.apply()
        for entry in self.spec["links"]:
            self.assertTrue(bootstrap.same_link(Path(entry["destination"]), Path(entry["source"])))
        self.assertTrue(bootstrap.restore_journal(self.journal()))
        self.assertFalse(os.path.lexists(self.home / ".bashrc"))
        self.assertTrue(bootstrap.restore_journal(self.journal()))

    def test_apply_is_idempotent(self):
        self.apply()
        journals = list((self.state / "transactions").iterdir())
        self.apply()
        self.assertEqual(journals, list((self.state / "transactions").iterdir()))

    def test_regular_file_conflict_makes_no_changes(self):
        target = self.home / ".bashrc"
        target.write_text("user data\n")
        with self.assertRaises(ValueError):
            self.apply()
        self.assertEqual(target.read_text(), "user data\n")
        self.assertFalse(os.path.lexists(self.home / ".dotfiles"))
        self.assertFalse(self.state.exists())

    def test_backup_and_restore_regular_file(self):
        target = self.home / ".bashrc"
        target.write_text("user data\n")
        self.apply(backup=True)
        self.assertTrue(target.is_symlink())
        self.assertTrue(bootstrap.restore_journal(self.journal()))
        self.assertFalse(target.is_symlink())
        self.assertEqual(target.read_text(), "user data\n")

    def test_backup_directory(self):
        target = self.home / ".config/git"
        target.mkdir(parents=True)
        (target / "user.txt").write_text("keep me")
        self.apply(backup=True)
        self.assertTrue(bootstrap.restore_journal(self.journal()))
        self.assertEqual((target / "user.txt").read_text(), "keep me")

    def test_unrelated_broken_symlink_is_a_conflict(self):
        target = self.home / ".bashrc"
        target.symlink_to(self.home / "nonexistent")
        with self.assertRaises(ValueError):
            self.apply()
        self.apply(backup=True)
        self.assertTrue(bootstrap.restore_journal(self.journal()))
        self.assertEqual(os.readlink(target), str(self.home / "nonexistent"))

    def test_restore_does_not_remove_modified_destination(self):
        target = self.home / ".bashrc"
        target.write_text("original")
        self.apply(backup=True)
        target.unlink()
        target.write_text("new user work")
        self.assertFalse(bootstrap.restore_journal(self.journal()))
        self.assertEqual(target.read_text(), "new user work")
        backup = next((self.journal().parent).glob("backup-*"))
        self.assertEqual(backup.read_text(), "original")

    def test_existing_matching_links_are_not_removed_by_restore(self):
        target = self.home / ".bashrc"
        target.symlink_to(ROOT / "bash/.bashrc")
        self.apply()
        self.assertTrue(bootstrap.restore_journal(self.journal()))
        self.assertTrue(target.is_symlink())

    def test_symlinked_parent_is_never_written_through(self):
        elsewhere = Path(self.temporary.name) / "elsewhere"
        elsewhere.mkdir()
        (self.home / ".config").symlink_to(elsewhere)
        with self.assertRaises(ValueError):
            self.apply(backup=True)
        self.assertEqual(list(elsewhere.iterdir()), [])

    def test_dotbot_failure_restores_conflicts(self):
        target = self.home / ".bashrc"
        target.write_text("original")
        with patch.object(bootstrap.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "dotbot")):
            with self.assertRaises(subprocess.CalledProcessError):
                self.apply(backup=True)
        self.assertEqual(target.read_text(), "original")
        self.assertFalse(os.path.lexists(self.home / ".dotfiles"))

    def test_restore_refuses_changed_parent_symlink(self):
        self.apply()
        git = self.home / ".config/git"
        git.unlink()
        (self.home / ".config").rename(self.home / ".config-before-change")
        outside = Path(self.temporary.name) / "outside"
        outside.mkdir()
        (outside / "git").symlink_to(ROOT / "config/git")
        (self.home / ".config").symlink_to(outside)
        self.assertFalse(bootstrap.restore_journal(self.journal()))
        self.assertTrue((outside / "git").is_symlink())

    def test_submodule_selection_is_scoped(self):
        with patch.object(bootstrap.subprocess, "run") as run:
            bootstrap.ensure_submodules(self.spec)
        args = run.call_args.args[0]
        self.assertEqual(args[args.index("--") + 1:], ["dotbot"])
        self.assertNotIn("--remote", args)

    def test_profile_selection(self):
        developer = bootstrap.build_spec("developer", [], self.home, self.home / ".config")
        self.assertNotIn("hyprland", developer["packages"])
        self.assertNotIn("texlive-latexextra", developer["packages"])
        desktop = bootstrap.build_spec("desktop", [], self.home, self.home / ".config")
        self.assertIn("kitty", desktop["modules"])
        self.assertIn("blueberry", desktop["aur"])
        self.assertNotIn("blueberry", desktop["packages"])
        self.assertNotIn("wlogout", desktop["aur"] + desktop["packages"])
        personal = bootstrap.build_spec("personal", [], self.home, self.home / ".config")
        git = next(link for link in personal["links"] if link["destination"].endswith("/.config/git"))
        self.assertEqual(git["source"], str(ROOT / "config/git"))

    def test_every_profile_can_apply_and_restore_in_an_isolated_home(self):
        for name in ("minimal", "developer", "desktop", "personal"):
            with self.subTest(profile=name):
                home = Path(self.temporary.name) / name
                home.mkdir()
                state = home / ".local/state/dotfiles"
                extra = ["music"] if name == "developer" else []
                spec = bootstrap.build_spec(name, extra, home, home / ".config")
                with patch.object(bootstrap, "ensure_submodules"), patch.dict(os.environ, {"HOME": str(home)}):
                    bootstrap.apply(spec, state, False)
                journal = next((state / "transactions").glob("*/journal.json"))
                self.assertTrue(bootstrap.restore_journal(journal))
                for entry in spec["links"]:
                    self.assertFalse(os.path.lexists(entry["destination"]))

    def test_profile_path_traversal_is_rejected(self):
        with self.assertRaises(ValueError):
            bootstrap.load_profile("../anything")
        with self.assertRaises(ValueError):
            bootstrap.expand_target("~/../../etc/file", self.home, self.home / ".config")

    def test_profile_cycle_is_rejected(self):
        root = Path(self.temporary.name) / "repo"
        (root / "profiles").mkdir(parents=True)
        (root / "profiles/a.json").write_text(json.dumps({"extends": "b"}))
        (root / "profiles/b.json").write_text(json.dumps({"extends": "a"}))
        with self.assertRaisesRegex(ValueError, "inheritance cycle"):
            bootstrap.load_profile("a", root)

    def test_missing_source_is_not_applied(self):
        self.spec["links"].append({"destination": str(self.home / ".missing"),
                                   "source": str(ROOT / "not-a-real-source")})
        with self.assertRaises(ValueError):
            self.apply()
        self.assertFalse(os.path.lexists(self.home / ".dotfiles"))
        self.assertFalse(self.state.exists())

    def test_checkout_destination_is_protected(self):
        with self.assertRaisesRegex(ValueError, "inside the source checkout"):
            bootstrap.build_spec("minimal", [], ROOT, ROOT / ".config")

    def test_package_command_previews_by_default(self):
        with patch.object(Path, "read_text", return_value="ID=arch\n"), \
                patch.object(bootstrap.shutil, "which", return_value="/test/ansible-playbook"), \
                patch.object(bootstrap.subprocess, "run") as run:
            bootstrap.arch_packages(self.spec, install=False)
        args = run.call_args.args[0]
        self.assertIn("--check", args)
        self.assertNotIn("--ask-become-pass", args)

    def test_package_install_requires_explicit_opt_in(self):
        with patch.object(Path, "read_text", return_value="ID=arch\n"), \
                patch.object(bootstrap.shutil, "which", return_value="/test/ansible-playbook"), \
                patch.object(bootstrap.subprocess, "run") as run:
            bootstrap.arch_packages(self.spec, install=True)
        args = run.call_args.args[0]
        self.assertNotIn("--check", args)
        self.assertIn("--ask-become-pass", args)

    def test_unsupported_package_platform_is_rejected(self):
        with patch.object(Path, "read_text", return_value="ID=debian\n"), \
                patch.object(bootstrap.subprocess, "run") as run:
            with self.assertRaisesRegex(ValueError, "Arch Linux only"):
                bootstrap.arch_packages(self.spec, install=True)
        run.assert_not_called()

    def test_xdg_config_destination(self):
        config = self.home / "custom-config"
        spec = bootstrap.build_spec("minimal", [], self.home, config)
        self.assertIn(str(config / "git"), [entry["destination"] for entry in spec["links"]])

    def test_checkout_already_at_dotfiles_is_kept(self):
        entry = {"destination": str(ROOT), "source": str(ROOT)}
        self.assertEqual(bootstrap.inspect_spec({"links": [entry]})[0]["action"], "keep")

    def test_base_git_and_local_override(self):
        self.apply()
        result = subprocess.run(["git", "config", "--global", "--includes", "--get", "credential.helper"],
                                env={**os.environ, "HOME": str(self.home), "XDG_CONFIG_HOME": str(self.home / ".config")},
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), "store")
        (self.home / ".gitconfig_local").write_text("[credential]\n    helper = cache\n")
        result = subprocess.run(["git", "config", "--global", "--includes", "--get", "credential.helper"],
                                env={**os.environ, "HOME": str(self.home), "XDG_CONFIG_HOME": str(self.home / ".config")},
                                text=True, capture_output=True, check=True)
        self.assertEqual(result.stdout.strip(), "cache")
        result = subprocess.run(["git", "config", "--global", "--includes", "--get", "alias.mnf"],
                                env={**os.environ, "HOME": str(self.home), "XDG_CONFIG_HOME": str(self.home / ".config")},
                                text=True, capture_output=True, check=True)
        self.assertEqual(result.stdout.strip(), "merge --no-ff")


if __name__ == "__main__":
    unittest.main()
