#!/usr/bin/env python3
"""Generates Sporewick's spore/mushroom icon set.

Every icon here is an original, hand-authored SVG (a parameterized cap +
stem + spots template drawn with basic shape primitives) — no external art,
photos, or third-party icon packs are used. Source SVGs are written to
assets/spores/*.svg and rasterized to assets/spores/*.png via rsvg-convert
so the game can load plain textures without depending on Godot's SVG
import pipeline.

Re-run any time the icon set or a species's colors change:
    python3 tools/gen_spore_icons.py
"""
import subprocess
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent.parent / "game" / "sporewick" / "assets" / "spores"
PNG_SIZE = 256

# Each species: cap fill, cap rim, spot color, stem color, glow ring color
# (None = no glow ring — the base spores are plain; hybrids and refined
# tiers get a ring so they read as "upgraded" at a glance in the shop and
# compendium, distinct from a plain base spore).
SPECIES = {
    "ember_cap":            dict(cap="#e8563c", rim="#b8371f", spot="#ffd9a0", stem="#f2e2c9", glow=None),
    "moss_puff":            dict(cap="#5fae5a", rim="#3d7a3a", spot="#eafccb", stem="#e6ddc0", glow=None),
    "glimmer_truffle":      dict(cap="#6e6bd6", rim="#4a47a8", spot="#d9d6ff", stem="#e6ddc0", glow=None),
    "cindermoss_bloom":     dict(cap="#c97a3a", rim="#8f4f21", spot="#bfe89a", stem="#e6ddc0", glow="#8fce6b"),
    "suncap_ember":         dict(cap="#f0954a", rim="#c1631f", spot="#f4d1ff", stem="#f2e2c9", glow="#7d6be0"),
    "duskmoss_lantern":     dict(cap="#4a8f8a", rim="#2c615d", spot="#cfeee9", stem="#e6ddc0", glow="#8f7bd6"),
    "radiant_ember_cap":    dict(cap="#ff7a4d", rim="#d94e22", spot="#fff0c9", stem="#f7ecd6", glow="#ffcf6b"),
    "plush_moss_puff":      dict(cap="#7ecf6f", rim="#4f9a49", spot="#f2ffe0", stem="#eee6cc", glow="#bff29c"),
    "gilded_truffle":       dict(cap="#8a86f0", rim="#5f5bc9", spot="#f4f0ff", stem="#eee6cc", glow="#f0cf6b"),
    "mystery_spore":        dict(cap="#7a7a7a", rim="#4d4d4d", spot="#c9c9c9", stem="#bdbdbd", glow=None),
}


def build_svg(cap: str, rim: str, spot: str, stem: str, glow: str | None) -> str:
    glow_ring = (
        f'<circle cx="64" cy="60" r="56" fill="none" stroke="{glow}" '
        f'stroke-width="4" opacity="0.55"/>'
        if glow else ""
    )
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
  {glow_ring}
  <rect x="56" y="70" width="16" height="32" rx="7" fill="{stem}"/>
  <path d="M20 66c0-26 18-44 44-44s44 18 44 44c-12 8-28 12-44 12s-32-4-44-12z" fill="{cap}" stroke="{rim}" stroke-width="3"/>
  <circle cx="46" cy="46" r="6" fill="{spot}"/>
  <circle cx="74" cy="38" r="5" fill="{spot}"/>
  <circle cx="88" cy="58" r="6" fill="{spot}"/>
  <circle cx="58" cy="60" r="4" fill="{spot}"/>
</svg>'''


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, params in SPECIES.items():
        svg_path = OUT_DIR / f"{name}.svg"
        png_path = OUT_DIR / f"{name}.png"
        svg_path.write_text(build_svg(**params))
        subprocess.run(
            ["rsvg-convert", "-w", str(PNG_SIZE), "-h", str(PNG_SIZE),
             str(svg_path), "-o", str(png_path)],
            check=True,
        )
        print(f"wrote {svg_path.name} -> {png_path.name}")


if __name__ == "__main__":
    main()
