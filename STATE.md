# Project State

## Current game
- Name: **Sporewick** (working title, cleared name-collision check — see NAME_CHECK.md)
- Genre: cozy idle/collection game. Tend a mystical fungal garden, harvest
  spores, crossbreed them at "the Wick" to discover hybrid species, fill
  out a compendium.
- Pitch (one paragraph): Sporewick is a cozy mobile idle game where you
  plant glowing spores in garden plots, wait for them to grow, harvest
  them, and combine pairs at a crossbreeding altar (the Wick) to discover
  new hybrid mushroom species for your compendium. The loop scales from a
  few plots and three base spores early on to a large garden and dozens of
  discoverable hybrids, with currency earned from harvesting and — more
  — from first-time discoveries. It's built for idle-game monetization:
  a subscription that speeds growth / grants bonus daily spores, plus
  one-off "spore pack" purchases for guaranteed rare species, both wired
  through RevenueCat.
- Engine: **Godot 4** (4.3-stable). Using the routine's stated default;
  nothing about this game's mechanics needs a different engine.
- Repo: this repo, `game/sporewick/` subfolder.
- Last worked: 2026-09-06 (run #1 — project inception)
- Days remaining in submission window: **24 days** (from 2026-09-06 to
  2026-09-30 11:45pm PDT)

## Pipeline checklist for current game
- [x] Idea locked (one-paragraph pitch, genre, core loop) — see above
- [x] Name checked against known works (see NAME_CHECK.md) — "Sporewick" locked after 3 prior candidates collided
- [x] Minimal playable vertical slice (core verbs wired end to end) — plant → grow → harvest → combine at Wick → compendium/currency update, all wired and verified headlessly (see Testing note below)
- [ ] Gameplay pass (feels functional, not just wired) — currently functional but bare; growth timing (3s), plot count (4), and recipe table (3 recipes) are all placeholder-tuned, not balanced
- [ ] Design pass (UI/UX coherent) — current UI is default-theme Buttons/Labels only, no visual identity yet
- [ ] Asset pass (see ASSET_LOG.md — every asset verified) — no real art/audio yet; only a placeholder icon and primitive-colored UI, both original
- [ ] Testing pass (headless verification, save/load, perf) — headless verification tool built and passing (see below); save/load and perf not yet addressed (nothing persists between runs yet)
- [ ] Debugging pass (known-issues list empty or triaged) — see Known Issues below
- [ ] RevenueCat SDK integrated, at least one real IAP wired — not started
- [ ] Store listing assets ready (1024x1024 icon, 1179x2556 screenshot, no device frame) — not started
- [ ] Demo video (<2 min, shows real gameplay, no third-party trademarks/music) — not started
- [ ] Published live on App Store / Google Play / Samsung Galaxy Store — not started
- [ ] Devpost submission drafted — not started

## Headless verification tool (built this run, reusable across all future games)
- `tools/setup_env.sh` — provisions the sandbox: downloads Godot 4.3-stable
  (MIT license, official GitHub release) to `/opt/godot`, installs Xvfb +
  Mesa software rendering (llvmpipe). Idempotent, re-run at the start of
  every future session since the container is ephemeral.
- `tools/run_headless_verify.sh <project_dir> [outdir]` — launches the
  Godot project under Xvfb with software OpenGL and passes `--verify` on
  the command line.
- Each game's `scripts/main.gd` (or equivalent) checks for `--verify` in
  `OS.get_cmdline_user_args()` and, if present, runs an in-process
  autopilot that calls the *real* game-logic functions (not mocks),
  asserts on real state, and saves *real* rendered `get_viewport().get_texture()`
  screenshots to disk at each key step — this is genuine rendered output
  under software OpenGL, not a description of expected behavior.
- Verified this actually renders correctly (not blank/black, which is a
  real risk with plain `--headless` since that mode has no display driver
  at all): confirmed with a throwaway red-rectangle test before relying on
  it for the real game.
- Sporewick's current autopilot (`game/sporewick/scripts/main.gd`,
  `_run_autopilot`) covers: start state → plant two plots → wait for
  growth → harvest both → combine at the Wick → assert the compendium
  grew and currency increased. All 9 assertions pass. Screenshots saved
  to `game/sporewick/verification_output/*.png` (committed as evidence).

## Known issues (debugging log — triaged, non-blocking for now)
- Combining two harvested spores of the *same* base type isn't in the
  recipe table, so it silently falls back to a generic "Mystery Spore"
  result. This might be fine as an intentional design choice (rewards
  harvesting *different* spore types together), but it hasn't been
  decided on purpose yet — flagging for the Gameplay pass rather than
  fixing blind.
- Growth timer (3 seconds) is a prototyping-speed placeholder, not a
  real idle-game timescale. Needs a real balance pass (likely minutes-to-
  hours with offline-progress catch-up) before this reads as an "idle
  game" rather than a fast arcade loop.
- No persistence yet (nothing saved between sessions) — needed before
  the Testing pass can be considered complete.
- No RevenueCat integration yet — needed before Testing pass.

## Pipeline checklist progress note
Per the routine's own "cap each piece at 4 rounds" rule: this run spent
its budget on inception (idea, name-check, engine verification, headless
tooling, vertical slice) rather than polish, which is the correct order
per Section 2 ("build ONE minimal playable vertical slice first"). Next
run should do a Gameplay pass: tune growth timing, expand the recipe
table, and decide the same-type-combo question above — not jump ahead to
art or RevenueCat yet.

## Backlog (next games, if current one finishes or gets shelved)
1. (none yet — this is the first game; backlog will fill in as ideas come up or if Sporewick gets shelved per the 3-stalled-runs rule)

## Changelog (append, never rewrite history)
- 2026-09-06: Run #1 (project inception). Repo was completely empty (no
  commits, no branches) — this is the true first run. Chose Godot 4.3 as
  engine per the routine's default. Verified real headless rendering is
  possible in this sandbox via Xvfb + Mesa software OpenGL (plain
  `--headless` alone cannot produce real screenshots — no display driver
  — so built `tools/setup_env.sh` + `tools/run_headless_verify.sh` around
  Xvfb instead). Iterated through 4 game concepts before landing on one
  that cleared the name/concept collision check: "Orbital Snap" and "Snap
  Orbit" both collided with live shipped apps; "Arc Guard" was name-clean
  but the shield-defense mechanic space is saturated with near-identical
  titles; the constellation-untangle concept collided at the theme level
  (multiple existing "Stars Untangler"/"Constellations" apps); "Bloomkeeper"
  collided with an actively-marketed Steam title. Landed on **Sporewick**,
  a cozy idle garden/crossbreeding collector game — clean name check, and
  distinct combination of theme + mechanic from what the searches turned
  up. Built and headlessly verified the vertical slice (plant → grow →
  harvest → combine → compendium), all 9 autopilot assertions passing
  with real rendered screenshots as evidence. Not shipped snippet Y/N:
  first-ever snippet, see /SOCIAL_SNIPPETS/2026-09-06.md.
