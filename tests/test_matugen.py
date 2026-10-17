"""Wallpaper colors: matugen templates, the configs that read them, and their fallbacks."""

import importlib.util
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1]
MATUGEN = ROOT / "config/matugen"
TEMPLATES = MATUGEN / "templates"


class MatugenTests(unittest.TestCase):
    def setUp(self):
        self.config = tomllib.loads((MATUGEN / "config.toml").read_text())

    def test_every_template_exists_and_writes_to_state(self):
        for name, template in self.config["templates"].items():
            source = TEMPLATES / Path(template["input_path"]).name
            self.assertTrue(source.is_file(), name)
            self.assertTrue(template["output_path"].startswith("~/.local/state/matugen/"), name)

    def test_custom_colors_cover_terminal_palette(self):
        kitty = (TEMPLATES / "kitty.conf").read_text()
        used = set(re.findall(r"colors\.(?:on_)?(\w+?)(?:_container)?\.default", kitty))
        for hue in ("red", "green", "yellow", "blue", "magenta", "cyan"):
            self.assertIn(hue, used)
            self.assertTrue(self.config["config"]["custom_colors"][hue]["blend"], hue)
        for index in range(16):
            self.assertRegex(kitty, rf"(?m)^color{index}\s+\{{\{{colors\.\w+\.default\.hex\}}\}}$")

    def test_apps_read_fallback_then_wallpaper_colors(self):
        configs = {
            "config/kitty/kitty.conf": ("include matugen-fallback.conf", "include ~/.local/state/matugen/kitty.conf"),
            "config/rofi/config.rasi": ('@import "matugen-fallback.rasi"', '@import "~/.local/state/matugen/rofi.rasi"'),
            "config/rofi/config-wallpaper.rasi": ('@import "matugen-fallback.rasi"', '@import "~/.local/state/matugen/rofi.rasi"'),
            "config/hypr/hyprlock.conf": ("source = $HOME/.config/hypr/matugen-fallback.conf",
                                          "source = $HOME/.local/state/matugen/hyprlock.conf"),
            "config/hypr/hyprland.lua": ('"/hypr/matugen-fallback.lua"', '"/.local/state/matugen/hyprland.lua"'),
        }
        for path, (fallback, generated) in configs.items():
            text = (ROOT / path).read_text()
            self.assertLess(text.index(fallback), text.index(generated), path)
        self.assertFalse((ROOT / "config/kitty/no-preference-theme.auto.conf").exists(),
                         "kitty auto themes load last and would override the wallpaper colors")

    def test_slots_match_between_templates_and_users(self):
        rofi = set(re.findall(r"(?m)^    ([\w-]+):", (TEMPLATES / "rofi.rasi").read_text()))
        # rofi properties of the same name would restyle every widget.
        self.assertFalse(rofi & {"highlight", "border", "background-color", "text-color"})
        for name in ("config.rasi", "config-wallpaper.rasi"):
            used = set(re.findall(r"@([\w-]+);", (ROOT / "config/rofi" / name).read_text()))
            self.assertLessEqual(used, rofi, name)
        lock = (ROOT / "config/hypr/hyprlock.conf").read_text()
        variables = set(re.findall(r"(?m)^\$(\w+) =", (TEMPLATES / "hyprlock.conf").read_text()))
        used = set(re.findall(r"\$(\w+)", lock)) - {"HOME", "LAYOUT", "DESC", "TIME", "FPRINTPROMPT"}
        self.assertLessEqual(used, variables)
        # Only the transparent input fill stays literal.
        literals = [line for line in lock.splitlines()
                    if re.search(r"rgba?\(", line) and not line.lstrip().startswith("#")]
        self.assertEqual(literals, ["    inner_color = rgba(0, 0, 0, 0.0) # no fill"])

    @unittest.skipUnless(shutil.which("matugen"), "matugen is required to render templates")
    def test_committed_fallbacks_match_templates(self):
        spec = importlib.util.spec_from_file_location("render", MATUGEN / "render-fallbacks.py")
        render = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(render)
        self.assertEqual(set(render.OUTPUTS), set(self.config["templates"]))
        with tempfile.TemporaryDirectory() as directory:
            render.render(Path(directory))
            for relative in render.OUTPUTS.values():
                rendered = (Path(directory) / relative).read_text()
                self.assertNotIn("{{", rendered)
                self.assertEqual(rendered, (ROOT / relative).read_text(),
                                 f"{relative} is stale; run config/matugen/render-fallbacks.py")


if __name__ == "__main__":
    unittest.main()
