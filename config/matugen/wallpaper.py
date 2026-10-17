#!/usr/bin/env python3
"""Generate the Material colors for a wallpaper with matugen.

matugen offers up to five source colors, most dominant first. The most
saturated one usually reads best, but on these wallpapers that is often a
small pink or red accent, and the tonal-spot scheme then tints every surface
rose. A red or pink color wins only when it is the dominant one.

    config/matugen/wallpaper.py <image>
"""

import math
import subprocess
import sys


def chroma_and_hue(color):
    """OKLCH chroma and hue in degrees of a #rrggbb color."""
    def linear(channel):
        channel /= 255
        return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4
    r, g, b = (linear(int(color[i:i + 2], 16)) for i in (1, 3, 5))
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360


def is_red(hue):
    """Pink through red to orange-red, in OKLCH hue."""
    return hue >= 320 or hue < 45


def pick(colors):
    """Index of the most saturated color, skipping red ones after the first."""
    candidates = [(index, *chroma_and_hue(color)) for index, color in enumerate(colors)]
    allowed = [c for c in candidates if c[0] == 0 or not is_red(c[2])]
    return max(allowed, key=lambda c: c[1])[0]


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: wallpaper.py <image>")
    image = sys.argv[1]
    sources = subprocess.run(["matugen", "image", "--show-source-colors", image],
                             capture_output=True, text=True, check=True).stdout.split()
    colors = [color for color in sources if len(color) == 7 and color.startswith("#")]
    choice = ["--source-color-index", str(pick(colors))] if colors else ["--prefer", "saturation"]
    subprocess.run(["matugen", "image", *choice, "--quiet", image], check=True)


if __name__ == "__main__":
    main()
