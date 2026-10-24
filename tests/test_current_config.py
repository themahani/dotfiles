"""Profiles cover the maintained apps and every declared link has a source."""

import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class CurrentConfigTests(unittest.TestCase):
    def test_obsolete_apps_and_installers_are_removed(self):
        catalog = json.loads((ROOT / "manifests/modules.json").read_text())
        self.assertNotIn("vim-legacy", catalog)
        self.assertNotIn("alacritty", catalog)
        for relative in ("install-legacy", "install.conf.yaml", "vim/.vimrc"):
            self.assertFalse((ROOT / relative).exists(), relative)
        # nwg-displays writes these next to the Lua config whenever it applies
        # a layout, so they may exist; they must stay out of git.
        ignored = (ROOT / "config/hypr/.gitignore").read_text().split()
        for name in ("monitors.conf", "workspaces.conf", "monitors.lua", "workspaces.lua"):
            self.assertIn(name, ignored)
        self.assertNotIn("alacritty", (ROOT / ".gitmodules").read_text())

    def test_all_module_and_profile_links_have_sources(self):
        catalog = json.loads((ROOT / "manifests/modules.json").read_text())
        for name, module in catalog.items():
            for source in module.get("links", {}).values():
                self.assertTrue((ROOT / source).exists(), f"{name}: {source}")
        for path in (ROOT / "profiles").glob("*.json"):
            for source in json.loads(path.read_text()).get("links", {}).values():
                self.assertTrue((ROOT / source).exists(), f"{path.name}: {source}")

    def test_claude_settings_use_linked_files(self):
        links = json.loads((ROOT / "manifests/modules.json").read_text())["claude"]["links"]
        settings = json.loads((ROOT / "config/claude/settings.json").read_text())
        script = settings["statusLine"]["command"].split()[-1]
        self.assertIn(script, links)
        # claude.ai writes its synced skills into the linked directory.
        self.assertIn("config/claude/skills/synced/", (ROOT / ".gitignore").read_text().split())

    def test_claude_mods_load_from_the_checkout(self):
        settings = json.loads((ROOT / "config/claude/settings.json").read_text())
        for folder in settings["env"]["CLAUDE_CODE_PLUGIN_DIRS"].split(":"):
            self.assertTrue(folder.startswith("~/.dotfiles/config/claude/mods/"), folder)
            mod = ROOT / folder.removeprefix("~/.dotfiles/")
            self.assertTrue((mod / ".claude-plugin/plugin.json").is_file(), folder)

    def test_no_inactive_editor_backups_remain(self):
        self.assertEqual(list((ROOT / "config/nvim").rglob("*.bak")), [])
        self.assertFalse((ROOT / "config/kitty/kitty.conf.bak").exists())

    def test_profiles_use_the_same_base_configuration(self):
        catalog = json.loads((ROOT / "manifests/modules.json").read_text())
        for module in catalog.values():
            for source in module.get("links", {}).values():
                self.assertFalse(source.startswith("defaults/"), source)
        for path in (ROOT / "profiles").glob("*.json"):
            self.assertFalse(json.loads(path.read_text()).get("links"), path.name)
        self.assertFalse(any((ROOT / "defaults").rglob("*.*")))


if __name__ == "__main__":
    unittest.main()
