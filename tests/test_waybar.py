"""Validate the single-file module config without starting another live bar."""

import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
LAYOUT_KEYS = ("modules-left", "modules-center", "modules-right")
BAR_KEYS = {"layer", "position", "height", "spacing", *LAYOUT_KEYS}
LEGACY_BANKS = ("Modules", "ModulesCustom", "ModulesGroups", "ModulesVertical", "ModulesWorkspaces", "UserModules")


def load_jsonc(path):
    # Match string literals first so URLs, shell commands, and escapes survive.
    text = re.sub(r'("(?:\\.|[^"\\])*")|/\*.*?\*/|//[^\n]*',
                  lambda match: match[1] or "", path.read_text(), flags=re.S)
    text = re.sub(r'("(?:\\.|[^"\\])*")|,(\s*[}\]])',
                  lambda match: match[1] or match[2], text)

    def unique_keys(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"Duplicate configuration key: {key}")
            result[key] = value
        return result

    return json.loads(text, object_pairs_hook=unique_keys)


def active_modules(config):
    used = set()

    def add(name):
        if name in used:
            return
        used.add(name)
        for child in config.get(name, {}).get("modules", []):
            add(child)

    for key in LAYOUT_KEYS:
        for name in config[key]:
            add(name)
    return used


class WaybarTests(unittest.TestCase):
    def setUp(self):
        self.config = load_jsonc(ROOT / "config/waybar/config.jsonc")

    def test_main_config_is_self_contained(self):
        self.assertNotIn("include", self.config)
        for name in LEGACY_BANKS:
            self.assertFalse((ROOT / "config/waybar" / name).exists())

    def test_all_active_modules_are_defined_and_no_unused_definitions_remain(self):
        self.assertEqual(set(self.config) - BAR_KEYS, active_modules(self.config))

    def test_laptop_group_keeps_battery_and_backlight(self):
        self.assertIn("group/laptop", self.config["modules-right"])
        self.assertEqual(self.config["group/laptop"]["modules"], ["backlight", "battery"])

    def test_active_module_scripts_exist(self):
        for module in self.config.values():
            if not isinstance(module, dict):
                continue
            for value in module.values():
                if not isinstance(value, str):
                    continue
                for relative in re.findall(r'\$HOME/\.config/([\w/.-]+\.sh)', value):
                    self.assertTrue((ROOT / "config" / relative).is_file(), relative)

    def test_local_overrides_use_the_single_module_source(self):
        for relative in ("examples/waybar.local.jsonc",):
            with self.subTest(config=relative):
                overlay = load_jsonc(ROOT / relative)
                self.assertEqual(overlay["include"], ["$HOME/.config/waybar/config.jsonc"])
                merged = {**self.config, **overlay}
                self.assertTrue(active_modules(merged).issubset(self.config))
                self.assertTrue((set(overlay) - BAR_KEYS - {"include"}).issubset(self.config))


if __name__ == "__main__":
    unittest.main()
