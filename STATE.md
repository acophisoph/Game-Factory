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
- Last worked: 2026-09-13 (run #3 — persistence + offline-progress catch-up)
- Days remaining in submission window: **17 days** (from 2026-09-13 to
  2026-09-30 11:45pm PDT)

## Pipeline checklist for current game
- [x] Idea locked (one-paragraph pitch, genre, core loop) — see above
- [x] Name checked against known works (see NAME_CHECK.md) — "Sporewick" locked after 3 prior candidates collided
- [x] Minimal playable vertical slice (core verbs wired end to end) — plant → grow → harvest → combine at Wick → compendium/currency update, all wired and verified headlessly (see Testing note below)
- [x] Gameplay pass (feels functional, not just wired) — growth timing rebalanced (3s → 60s real, with a fast 1s override for the headless autopilot only), the same-type-combo design question resolved (see Known Issues), recipe table expanded from 3 to 6 recipes (all 6 possible pairs of the 3 base spores now covered — Mystery Spore fallback is unreachable with the current spore set but kept as a safety net for when more base spores are added). Plot count (4) left as-is — not a "feels bare" issue at this stage, revisit alongside monetization design (extra plots as IAP) later.
- [ ] Design pass (UI/UX coherent) — current UI is default-theme Buttons/Labels only, no visual identity yet
- [ ] Asset pass (see ASSET_LOG.md — every asset verified) — no real art/audio yet; only a placeholder icon and primitive-colored UI, both original
- [ ] Testing pass (headless verification, save/load, perf) — save/load with offline-progress catch-up implemented and headlessly verified this run (see below); perf (frame time under real scene load) still not measured
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
- Run #2 also fixed a latent bug in `tools/run_headless_verify.sh`: when
  called with a *relative* project path, Godot resolves a relative
  `--outdir` against the project root (`res://`), not the caller's cwd,
  silently nesting output into `<project>/<project>/verification_output`
  instead of `<project>/verification_output`. The script now resolves
  both the project dir and outdir to absolute paths before invoking
  Godot, fixed for all future games that reuse this tool.
- Run #2's autopilot (`_run_autopilot`) was extended: it now plants
  deterministic spore types (via a new optional `forced_type` param on
  `plant_at`, real game logic path, not a mock — only the RNG pick is
  bypassed for reproducible testing) to exercise both a cross-type
  combo (asserts the exact expected hybrid) and the new same-type combo
  path (asserts it reaches the refined spore, never "Mystery Spore").
  17 assertions, all passing. New screenshot:
  `05_same_type_combined.png`.
- Run #3 added persistence: every state-changing action (`plant_at`,
  `harvest_at`, `combine_at_wick`) now autosaves full game state
  (currency, inventory, compendium, per-plot state/spore/timer, plus a
  `saved_at` unix timestamp) to `user://savegame.json` as JSON —
  autosave-on-action rather than a timer or an on-quit hook, since a
  mobile OS can kill a backgrounded app without a clean exit. On launch,
  `_load_game()` restores state and calls `_apply_offline_elapsed()`,
  which advances any still-growing plot's timer by the real elapsed time
  since the last save — so a plot that would have finished growing while
  the app was closed is caught up to ready on the next launch instead of
  silently losing that progress. The headless autopilot uses an isolated
  `user://verify_savegame.json` path (deleted at the start of every
  verify run) so verification never reads or clobbers a real save.

## Known issues (debugging log — triaged, non-blocking for now)
- ~~Combining two harvested spores of the *same* base type falls back to
  "Mystery Spore".~~ **Resolved run #2**: same-type combos now discover a
  dedicated "refined" spore (Radiant Ember Cap / Plush Moss Puff / Gilded
  Truffle) instead — a deliberate reward for focusing on one spore type,
  as an alternate strategy to cross-breeding variety, not a fallback.
- ~~Growth timer (3 seconds) is a prototyping-speed placeholder.~~
  **Partially addressed run #2**: real gameplay timing is now 60 seconds
  (a first balance pass). Offline-progress catch-up was the remaining
  piece and is **resolved run #3** — see below.
- ~~No persistence yet (nothing saved between sessions).~~ **Resolved
  run #3**: autosave-on-action to `user://savegame.json`, restored and
  offline-caught-up on launch. See the persistence note above.
- Perf (target frame time under real scene load) still not measured —
  needed before the Testing pass can be considered fully complete. Low
  risk at this scene complexity (a handful of Buttons/Labels, no
  particle/physics load) but not yet verified against a number.
- No RevenueCat integration yet — needed before Testing pass.
- Save data has no version field and no corruption handling: a malformed
  or future-schema save file would currently fail `_load_game()`'s type
  check and silently start fresh (safe, but silent). Fine for a solo
  prototype; flag for revisit once the save schema needs to change after
  players have real saves (i.e., post-launch), not before.

## Pipeline checklist progress note
Run #2 completed the Gameplay pass flagged by run #1. Run #3 picked up
the more urgent of the two items run #2 flagged next (persistence, over
the Design pass) since losing in-progress growth on app close was a
real functional gap, not just a visual one — implemented autosave-on-
action and offline-progress catch-up, headlessly verified with a
save/reload round-trip and a back-dated-timestamp offline-catchup test
(24/24 autopilot assertions passing). Per the "cap at 4 rounds" rule,
this run's scope stayed to persistence; it did not start the Design
pass, perf measurement, or RevenueCat integration. **Next run should do
the Design pass** (UI is still default-theme Buttons/Labels, no visual
identity — the most visible remaining gap) and/or a quick perf check
now that persistence is done and Testing pass is nearly closed out.

## Note on branch/PR history (run #3)
This run's designated branch (`claude/upbeat-ritchie-gxyo11`) had been
created from the same point as run #1, before run #2's work (open PR
#1, branch `claude/upbeat-ritchie-3ivydg`) was merged into the default
branch. Fast-forward-merged PR #1's commit into this branch before
starting run #3's own work, so this run continues from run #2's actual
progress instead of redoing it. **PR #1 is still open/unmerged as of
this run** — since this run's branch now contains its commit, either
merge order will resolve cleanly, but a human should merge or close PR
#1 to avoid two open PRs describing overlapping history.

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
- 2026-09-10: Run #2 (gameplay pass). No new SOCIAL_FEEDBACK.md entries
  to incorporate (nothing posted publicly yet). Did the Gameplay pass
  flagged by run #1: rebalanced growth timer from a 3s prototyping
  placeholder to 60s real gameplay time (with a separate 1s override
  used only by the headless autopilot, so verification stays fast without
  changing real game feel); expanded the recipe table from 3 to 6
  recipes by deciding the same-type-combo design question — same-type
  pairs now discover a "refined" spore (Radiant Ember Cap / Plush Moss
  Puff / Gilded Truffle) instead of falling through to Mystery Spore,
  rewarding a focus-on-one-type strategy as a deliberate alternative to
  cross-breeding variety. Logged the 3 new spore names in NAME_CHECK.md
  (same low-collision-risk reasoning as the earlier hybrid names).
  Extended the headless autopilot to exercise both the cross-type and
  same-type combo paths deterministically (added an optional
  `forced_type` arg to `plant_at` so the autopilot can control which
  spore lands in a plot while still exercising the real game logic, not
  a mock) — 17/17 assertions pass, verified with real rendered
  screenshots including a new `05_same_type_combined.png`. While
  re-running verification, found and fixed a real bug in the shared
  `tools/run_headless_verify.sh`: a relative project-dir argument caused
  Godot to resolve the output path against the project root instead of
  the caller's cwd, silently nesting screenshots into
  `<project>/<project>/verification_output`; script now resolves both
  paths to absolute before invoking Godot, fixed for all future games
  reusing this tool. Not shipped snippet Y/N: not shipped, see
  /SOCIAL_SNIPPETS/2026-09-10.md.
- 2026-09-13: Run #3 (persistence + offline-progress catch-up). No new
  SOCIAL_FEEDBACK.md entries to incorporate (still empty). Found that
  this run's designated branch predated run #2's merge (PR #1 was still
  open) — fast-forward-merged that branch's commit in first so this run
  builds on run #2's actual state rather than redoing it; flagged PR #1
  for human cleanup, see note above. Implemented save/load: every
  state-changing action now autosaves full game state (currency,
  inventory, compendium, per-plot state/spore/timer, `saved_at` unix
  timestamp) to `user://savegame.json` as JSON; `_load_game()` on launch
  restores it and applies offline-progress catch-up (`_apply_offline_
  elapsed`), advancing any still-growing plot by the real time elapsed
  since the last save so growth completed while the app was closed isn't
  lost. Headless autopilot uses an isolated, always-cleared
  `user://verify_savegame.json` so verification can't touch a real save.
  Extended the autopilot with a save/reload round-trip check (wipe
  in-memory state, reload, assert currency/compendium/inventory match)
  and an offline-catchup check (plant, back-date the save file's
  `saved_at` past a full growth cycle, reload, assert the plot reached
  ready) — 24/24 assertions pass, verified with real rendered
  screenshots (`06_reloaded.png`, `07_offline_catchup.png`; the latter
  visibly shows "Moss Puff ready!" immediately after the simulated
  reload, confirming the catch-up logic actually ran, not just that the
  assertion string matched). No new assets or names introduced. Not
  shipped snippet Y/N: not shipped, see /SOCIAL_SNIPPETS/2026-09-13.md.
