# Asset Log

Append-only audit trail. Every non-originally-generated asset (art,
music, SFX, fonts, code libraries) must be logged here before use, with
source URL and license type. "Free to download" is not "royalty-free" —
license text gets checked, not page framing. If a license is unclear,
the asset does not get used.

| Asset | Source | License | Verified? | Notes |
|-------|--------|---------|-----------|-------|
| icon.svg (Sporewick app icon, placeholder) | Original — hand-authored SVG (flat mushroom shape, solid-color shapes, no external source) | N/A — original work | Yes | Placeholder only; will likely get a real design pass before store submission. |
| All in-game visuals (plot buttons, labels, colors) in the current vertical slice | Original — built from Godot's built-in `Button`/`Label`/`Control` nodes and solid-color `modulate` tints, no external art files | N/A — original work | Yes | No textures, sprites, or external art used yet. This keeps the prototyping stage license-risk-free by construction; a real art pass (Section 2, "Assets" stage) will need its own logged entries. |
| Godot Engine 4.3-stable (game engine) | https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip | MIT License | Yes — Godot is MIT-licensed, free for commercial use including selling games with no royalties | Downloaded fresh each run via `tools/setup_env.sh` since the sandbox container is ephemeral; not committed to the repo. |

## Pending / not yet sourced
- Music and SFX: none yet. Do not add any until a track/clip has a confirmed CC0 or explicit royalty-free license logged here.
- Real (non-placeholder) art pass: not started. Flagged for a future run's "Assets" stage.
