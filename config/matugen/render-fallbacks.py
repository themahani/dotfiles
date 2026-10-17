#!/usr/bin/env python3
"""Render the matugen templates with Mocha blue into the committed fallbacks.

Each app reads its fallback first and the wallpaper colors from
~/.local/state/matugen over it, so without matugen output everything still
shares one Material 3 scheme. Run after changing a template or the seed:

    config/matugen/render-fallbacks.py [--out DIR]
"""

import argparse
from pathlib import Path
import subprocess
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[2]
SEED = "89b4fa"
OUTPUTS = {
    "quickshell": "config/quickshell/theme/fallback.json",
    "hyprland": "config/hypr/matugen-fallback.lua",
    "hyprlock": "config/hypr/matugen-fallback.conf",
    "kitty": "config/kitty/matugen-fallback.conf",
    "rofi": "config/rofi/matugen-fallback.rasi",
}


def render(out=ROOT):
    config = tomllib.loads((ROOT / "config/matugen/config.toml").read_text())
    lines = ["[config]", "", "[config.custom_colors]"]
    for name, color in config["config"]["custom_colors"].items():
        lines.append(f'{name} = {{ color = "{color["color"]}", blend = {str(color["blend"]).lower()} }}')
    for name, template in config["templates"].items():
        target = Path(out) / OUTPUTS[name]
        target.parent.mkdir(parents=True, exist_ok=True)
        lines += ["", f"[templates.{name}]",
                  f'input_path = "{ROOT / "config/matugen/templates" / Path(template["input_path"]).name}"',
                  f'output_path = "{target}"']
    with tempfile.NamedTemporaryFile("w", suffix=".toml") as file:
        file.write("\n".join(lines) + "\n")
        file.flush()
        subprocess.run(["matugen", "-c", file.name, "--quiet", "--mode", "dark", "color", "hex", SEED],
                       check=True, timeout=60)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=Path, default=ROOT, help="write under this directory instead of the repo")
    render(parser.parse_args().out)
