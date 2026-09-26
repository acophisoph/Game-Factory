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
| `PurchaseManager` GDScript wrapper (`game/sporewick/scripts/purchase_manager.gd`) | Original — hand-authored, written against the documented public API of `godot-x/revenuecat` (see next row) so it's a drop-in match, but no code copied from that repo | N/A — original work | Yes | Runs in "stub mode" in this sandbox (see notes below); no native plugin code included. |
| Spore icon set — `ember_cap`, `moss_puff`, `glimmer_truffle`, `cindermoss_bloom`, `suncap_ember`, `duskmoss_lantern`, `radiant_ember_cap`, `plush_moss_puff`, `gilded_truffle`, `mystery_spore` (10 icons, `game/sporewick/assets/spores/*.svg` + rasterized `.png`) | Original — hand-authored SVG template (cap/stem/spot shapes, parameterized colors), generated via `tools/gen_spore_icons.py`. No external art, photos, or icon packs. | N/A — original work | Yes | Replaces the run #1–4 text-only plot buttons with real per-species art. Regenerate by re-running the script if colors/species change. |
| App icon (`game/sporewick/icon.svg`, `icon.png`, `store_listing/icon_1024.png`) | Original — hand-authored SVG, same visual language as the spore icon set, generated via `tools/gen_app_icon.py`. Not reused from any external source. | N/A — original work | Yes | Redesigned this run to match the in-game mushroom-icon style instead of the run #1 placeholder. 1024x1024 store-listing size rendered alongside the small in-engine icon. |
| `librsvg2-bin` (`rsvg-convert`, used only as a build-time tool to rasterize the hand-authored SVGs above — ships in no build output) | Ubuntu package repository (`apt-get install librsvg2-bin`) | LGPL-2.1 (librsvg) — a build tool, not a shipped asset or linked library in the game itself | Yes | Installed via `tools/setup_env.sh` (idempotent, ephemeral sandbox). |

## Referenced but NOT vendored
| Asset | Source | License | Verified? | Notes |
|-------|--------|---------|-----------|-------|
| GodotxRevenueCat plugin (native RevenueCat SDK wrapper for Godot, iOS .xcframework + Android .aar) | https://github.com/godot-x/revenuecat (also listed on the official Godot Asset Library, https://godotengine.org/asset-library/asset/4493) | MIT License (confirmed on the GitHub repo) | License confirmed, but the plugin itself is **not added to this repo** this run | The plugin's own docs state it "functions exclusively on iOS and Android exports" and cannot run on desktop/Linux — this sandbox has no way to load, run, or verify its native binaries. Rather than vendor untested binary GDExtensions, `purchase_manager.gd` was written against this plugin's real documented GDScript API (method/singleton names match exactly) so a human can install the real addon before an iOS/Android export with no game-code changes needed. Installing it (via AssetLib or the GitHub Releases zip) and wiring real RevenueCat API keys + store product IDs is flagged in STATE.md as a human-required step this automated routine cannot complete itself. |

## Pending / not yet sourced
- Music and SFX: none yet. Do not add any until a track/clip has a confirmed CC0 or explicit royalty-free license logged here.
- Background/environment art (garden scene behind the UI), and any further visual polish beyond plot icons + palette: not started. The current store screenshot is honest (real gameplay, correct resolution) but the lower two-thirds of the screen is empty background color — flagged in STATE.md for a future Design/Asset pass.
- Real GodotxRevenueCat plugin binaries: not vendored yet, see "Referenced but NOT vendored" above — needs human install + store/API-key setup before an actual mobile export/submission.
