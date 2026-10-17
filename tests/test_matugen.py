"""Wallpaper colors: matugen templates, the configs that read them, and their fallbacks."""

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

    def test_kitty_includes_generated_colors_after_its_theme(self):
        kitty = (ROOT / "config/kitty/kitty.conf").read_text()
        theme = kitty.index("include current-theme.conf")
        generated = kitty.index("include ~/.local/state/matugen/kitty.conf")
        self.assertLess(theme, generated)

    def test_rofi_fallbacks_match_generated_slots(self):
        slots = lambda text: set(re.findall(r"(?m)^    ([\w-]+):", re.search(r"(?s)^\* \{(.*?)^\}", text, re.M).group(1)))
        generated = slots((TEMPLATES / "rofi.rasi").read_text())
        for name in ("config.rasi", "config-wallpaper.rasi"):
            theme = (ROOT / "config/rofi" / name).read_text()
            self.assertEqual(slots(theme), generated, name)
            self.assertIn('@import "~/.local/state/matugen/rofi.rasi"', theme)
            # rofi properties of the same name would restyle every widget.
            self.assertFalse(generated & {"highlight", "border", "background-color", "text-color"})

    def test_hyprlock_uses_variables_with_fallbacks(self):
        lock = (ROOT / "config/hypr/hyprlock.conf").read_text()
        generated = set(re.findall(r"(?m)^\$(\w+) =", (TEMPLATES / "hyprlock.conf").read_text()))
        defaults = lock[:lock.index("source = $HOME/.local/state/matugen/hyprlock.conf")]
        self.assertEqual(set(re.findall(r"(?m)^\$(\w+) =", defaults)), generated)
        body = lock[lock.index("source ="):]
        used = set(re.findall(r"\$(\w+)", body)) - {"HOME", "LAYOUT", "DESC", "TIME", "FPRINTPROMPT"}
        self.assertLessEqual(used, generated)
        # Only the transparent input fill stays literal.
        literals = [line for line in body.splitlines()
                    if re.search(r"rgba?\(", line) and not line.lstrip().startswith("#")]
        self.assertEqual(literals, ["    inner_color = rgba(0, 0, 0, 0.0) # no fill"])

    @unittest.skipUnless(shutil.which("matugen"), "matugen is required to render templates")
    def test_templates_render(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            config = (MATUGEN / "config.toml").read_text()
            config = config.replace("~/.config/matugen/templates", str(TEMPLATES)).replace("~/.local/state/matugen", str(out))
            config = re.sub(r"(?m)^post_hook = .*$", "", config)
            (out / "config.toml").write_text(config)
            subprocess.run(["matugen", "-c", str(out / "config.toml"), "--quiet", "color", "hex", "89b4fa"], check=True, timeout=30)
            for template in self.config["templates"].values():
                rendered = (out / Path(template["output_path"]).name).read_text()
                self.assertNotIn("{{", rendered)
            self.assertRegex((out / "kitty.conf").read_text(), r"(?m)^color1\s+#[0-9a-f]{6}$")


if __name__ == "__main__":
    unittest.main()
