#!/usr/bin/env python3
"""Generates Sporewick's app icon (original, hand-authored SVG — same
mushroom-cap visual language as tools/gen_spore_icons.py, not reused art
from elsewhere) and rasterizes it to the sizes the routine's checklist and
common store requirements need.

Re-run any time the icon design changes:
    python3 tools/gen_app_icon.py
"""
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME_ICON_SVG = ROOT / "game" / "sporewick" / "icon.svg"
STORE_DIR = ROOT / "game" / "sporewick" / "store_listing"

SVG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">
  <rect x="0" y="0" width="128" height="128" rx="28" fill="#1b2a23"/>
  <circle cx="64" cy="60" r="50" fill="none" stroke="#f2b155" stroke-width="3" opacity="0.5"/>
  <rect x="56" y="76" width="16" height="26" rx="7" fill="#f2e2c9"/>
  <path d="M22 62c0-24 18-40 42-40s42 16 42 40c-11 7-27 11-42 11s-31-4-42-11z"
        fill="#e8563c" stroke="#b8371f" stroke-width="3"/>
  <circle cx="46" cy="44" r="6" fill="#ffd9a0"/>
  <circle cx="74" cy="36" r="5" fill="#ffd9a0"/>
  <circle cx="88" cy="56" r="6" fill="#ffd9a0"/>
  <circle cx="58" cy="58" r="4" fill="#ffd9a0"/>
</svg>'''


def main() -> None:
    GAME_ICON_SVG.write_text(SVG)
    STORE_DIR.mkdir(parents=True, exist_ok=True)

    # In-engine icon (project.godot config/icon target — small, used by the
    # OS/editor, not the store listing).
    subprocess.run(
        ["rsvg-convert", "-w", "128", "-h", "128", str(GAME_ICON_SVG),
         "-o", str(GAME_ICON_SVG.with_suffix(".png"))],
        check=True,
    )

    # Store listing icon: 1024x1024 per the routine's checklist.
    out_1024 = STORE_DIR / "icon_1024.png"
    subprocess.run(
        ["rsvg-convert", "-w", "1024", "-h", "1024", str(GAME_ICON_SVG),
         "-o", str(out_1024)],
        check=True,
    )
    print(f"wrote {GAME_ICON_SVG.name}, {GAME_ICON_SVG.stem}.png, {out_1024.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
