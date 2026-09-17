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
- Last worked: 2026-09-17 (run #4 — RevenueCat purchase-manager scaffolding + perf sanity check)
- Days remaining in submission window: **13 days** (from 2026-09-17 to
  2026-09-30 11:45pm PDT)

## Pipeline checklist for current game
- [x] Idea locked (one-paragraph pitch, genre, core loop) — see above
- [x] Name checked against known works (see NAME_CHECK.md) — "Sporewick" locked after 3 prior candidates collided
- [x] Minimal playable vertical slice (core verbs wired end to end) — plant → grow → harvest → combine at Wick → compendium/currency update, all wired and verified headlessly (see Testing note below)
- [x] Gameplay pass (feels functional, not just wired) — growth timing rebalanced (3s → 60s real, with a fast 1s override for the headless autopilot only), the same-type-combo design question resolved (see Known Issues), recipe table expanded from 3 to 6 recipes (all 6 possible pairs of the 3 base spores now covered — Mystery Spore fallback is unreachable with the current spore set but kept as a safety net for when more base spores are added). Plot count (4) left as-is — not a "feels bare" issue at this stage, revisit alongside monetization design (extra plots as IAP) later.
- [x] Design pass (UI/UX coherent) — replaced default-theme Buttons/Labels with a small cozy-fungal-garden palette (deep forest background, rounded StyleBoxFlat cards, distinct colors per plot state — muted empty, moss-green growing, warm amber ready — and a violet Wick button so the combine action reads as a distinct kind of interaction). No new assets: palette is applied entirely through code-generated `StyleBoxFlat`/color overrides, same license-free-by-construction approach as before.
- [ ] Asset pass (see ASSET_LOG.md — every asset verified) — no real art/audio yet; only a placeholder icon and primitive-colored UI, both original
- [x] Testing pass (headless verification, save/load, perf) — save/load with offline-progress catch-up (run #3) plus a perf sanity check (run #4, see below) are all headlessly verified now. Marking this checked with one honest caveat: the perf number is a software-rendered llvmpipe number in a Linux container, not a real mobile device measurement (see Known Issues) — there's no on-device perf data yet, only a "not obviously broken" sanity floor.
- [ ] Debugging pass (known-issues list empty or triaged) — see Known Issues below
- [~] RevenueCat SDK integrated, at least one real IAP wired — code-side integration done this run (a `PurchaseManager` autoload wrapping the documented `godot-x/revenuecat` API, wired into two real gameplay effects — see below), but **not a real, on-device-tested IAP**: the native plugin only runs on iOS/Android exports, which this sandbox cannot produce or test. See "RevenueCat: what's real vs. what needs a human" below before treating this as done.
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
- Run #4 extended the autopilot with a perf sanity check: samples
  `Performance.TIME_PROCESS` after the full loop has run and asserts it's
  under 500ms/frame — a "not hung or looping" floor, not a real perf
  target (see Known Issues: the number itself, ~92ms/frame under
  software-rendered llvmpipe in this container, isn't representative of a
  real device). Also extended it to drive the new RevenueCat purchase
  flow (see below) end to end in stub mode: buy the spore pack, assert
  inventory grew by exactly 3; buy the subscription, assert the
  entitlement flips on and a newly-planted plot reaches ready in half the
  normal grow time. 35/35 assertions pass, two new screenshots
  (`08_spore_pack_purchased.png`, `09_boosted_growth.png`) confirm both
  the shop UI and the "✨ Wick's Blessing active" indicator actually
  render, not just that the assertions matched.

## RevenueCat: what's real vs. what needs a human (run #4)
Added `game/sporewick/scripts/purchase_manager.gd`, an autoload singleton
(`Purchases`) wrapping the community `godot-x/revenuecat` plugin's
documented public API (MIT license — see ASSET_LOG.md). It exposes
`initialize()`, `fetch_offerings()`, `purchase_package()`,
`has_entitlement()`, `restore_purchases()`, and the signals
`offerings_ready`/`purchase_result`/`customer_info_changed`, matching the
real plugin's names exactly. Wired into two real gameplay effects,
matching the pitch's original monetization design:
- **Spore Pack** (one-off, `$1.99`): grants 3 spores directly to
  inventory, no growing required.
- **Wick's Blessing** (subscription, `$2.99/mo`): while the entitlement
  is active, all plot growth takes half as long (`_effective_grow_seconds()`
  in `main.gd`), shown in the UI with a "✨ Wick's Blessing active (2x
  growth)" label.

**What's real:** the game-logic side — entitlement gating, the currency/
inventory effects of each purchase, the shop UI, the signal-based async
API shape. All of it is exercised by the real code path in headless
verification (see above), not mocked out.

**What is NOT real, and needs a human, before this can ship:**
1. The actual `godot-x/revenuecat` native plugin (iOS `.xcframework` +
   Android `.aar`) is **not installed in this repo**. It only runs on
   iOS/Android exports — this sandbox can only build/run desktop Linux,
   so it has no way to install, load, or test those binaries. Install it
   from the Godot Asset Library or https://github.com/godot-x/revenuecat
   Releases before an actual mobile export.
2. A real RevenueCat project + API keys (`appl_...` / `goog_...`) —
   `Purchases.initialize("")` currently runs with an empty placeholder key
   that's a safe no-op in stub mode. This needs a human to create the
   RevenueCat project and supply real keys (a secret, not something to
   invent or store in this repo).
3. Matching product IDs configured in App Store Connect / Google Play
   Console: `wicks_blessing_monthly` (subscription) and
   `spore_pack_small` (consumable) — the code assumes these IDs exist in
   an offering named `default`; nothing will actually be purchasable
   until a human sets those up on both sides (RevenueCat dashboard +
   store consoles) to match.
4. Real on-device purchase testing (sandbox/test-flight purchase or a
   promo code) — the routine's own Testing-pass bar ("RevenueCat IAP flow
   actually unlockable with a test purchase or promo code") can only be
   met on a real device once 1–3 above are done. Stub-mode verification
   in this sandbox exercises the game-logic side only, not a real store
   transaction — flagging this explicitly rather than claiming the
   checklist item is fully done.

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
- ~~Perf (target frame time under real scene load) still not measured.~~
  **Partially addressed run #4**: headless autopilot now samples
  `Performance.TIME_PROCESS` (~92ms/frame under this container's
  software-rendered llvmpipe) and asserts it's sane. Caveat: this is a
  software-rendering number in a Linux container, not a real mobile
  device measurement — there's no evidence yet that a real phone/tablet
  runs this comfortably at 60fps, only that nothing here is pathologically
  broken. Real on-device perf testing still needs a human with real
  hardware (or at minimum a mobile emulator this sandbox doesn't have).
- ~~No RevenueCat integration yet.~~ **Code-side integration done run
  #4** (see "RevenueCat: what's real vs. what needs a human" above) —
  but real store/API-key setup and on-device purchase testing are human
  follow-ups this sandbox cannot do itself. Do not treat the checklist
  item as fully done until those happen.
- RevenueCat purchase failure paths (declined payment, cancelled sheet,
  network error) are untested — the stub always "succeeds," since there's
  no real store to reject a purchase in this sandbox. `_on_purchase_result`
  in `main.gd` does have a failure branch (shows "Purchase failed —
  please try again."), but it's only been exercised by an
  unknown-package-id stub case, not a real store decline. Flag for
  on-device testing alongside item 4 above.
- Save data has no version field and no corruption handling: a malformed
  or future-schema save file would currently fail `_load_game()`'s type
  check and silently start fresh (safe, but silent). Fine for a solo
  prototype; flag for revisit once the save schema needs to change after
  players have real saves (i.e., post-launch), not before.

## Pipeline checklist progress note
Run #2 completed the Gameplay pass flagged by run #1. Run #3 did
persistence (autosave-on-action + offline-progress catch-up),
headlessly verified with a save/reload round-trip and a back-dated-
timestamp offline-catchup test (24/24 autopilot assertions passing).
Later the same day, prompted by a live follow-up rather than the next
scheduled run, the Design pass got done too: replaced the default-
theme Buttons/Labels with a small cozy-fungal-garden palette (rounded
StyleBoxFlat cards, distinct colors per plot state, a violet Wick
button) — see changelog entry below. Run #4 (this run) picked up the
next-run note's three options — perf measurement, RevenueCat
integration, or the Asset pass — and did the first two: a perf sanity
check, and RevenueCat purchase-manager scaffolding wired into two real
gameplay effects (spore pack, growth-boost subscription). Real
store/API-key setup and on-device testing are explicitly flagged as
human follow-ups (see "RevenueCat: what's real vs. what needs a human"
above) — this was a deliberate scope call given the routine's own
"cap each piece at 4 rounds" rule and the fact that a genuine RevenueCat
purchase requires an app store account and a real device, neither of
which this sandbox has. The **next scheduled run** should either start
the real (non-placeholder) Asset pass, or — if a human has done the
RevenueCat dashboard/store setup in the meantime — pick up on-device
testing and check off that pipeline item for real.

## Note on branch/PR history (run #4)
Same situation run #3 flagged and handled for run #2's work: this run's
designated branch (`claude/upbeat-ritchie-b33g2a`) was created from the
same point as run #1 (before run #2 or run #3's work was merged into the
default branch, `claude/upbeat-ritchie-2qm97h`). Two PRs were already
open and unmerged at the start of this run — **PR #1** (run #2's
gameplay pass, branch `3ivydg`) and **PR #2** (run #3's persistence work
plus the same-day Design pass, branch `gxyo11`, which itself already
contained PR #1's commit). Fast-forward-merged `gxyo11` into this run's
branch before starting any new work, so this run builds on the actual
latest progress instead of redoing it — same approach run #3 used.

**This run's new PR will make PR #1 and PR #2 fully redundant** (it's a
strict superset of both, plus this run's own work), so I'm closing both
with a comment pointing at the new PR rather than leaving three
overlapping open PRs for a human to untangle. If that turns out to be
unwanted, the closed PRs' branches (`3ivydg`, `gxyo11`) still exist and
can be reopened/recovered from.

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
- 2026-09-13 (same day, live follow-up — not a new scheduled run):
  Design pass. Replaced the default-theme gray Buttons/Labels with a
  small cozy-fungal-garden palette: deep forest-green background, a
  rounded semi-opaque "card" (`PanelContainer` + `StyleBoxFlat`) for the
  info readout, and per-plot-state colors — muted slate for empty,
  moss green for growing, warm amber for ready — plus a distinct violet
  style for the Wick button so combining reads as a different kind of
  action from tending a plot. Implemented via a `_panel_style()` helper
  building `StyleBoxFlat` resources (rounded corners, borders, content
  margins) applied through `add_theme_stylebox_override`, replacing the
  old flat `modulate` tinting. Also fixed a small pre-existing UX rough
  edge found while touching this code: the Wick's "need 2 spores"
  status message used to persist on screen indefinitely since nothing
  ever cleared it; `_refresh_ui()` now clears it on every successful
  action. No new assets or names (palette is code-generated colors, not
  external files). Re-ran the full headless autopilot after the change
  — still 24/24 assertions pass — and visually inspected several
  screenshots to confirm the new styling actually renders as intended
  (not just that the game logic still works).
- 2026-09-17: Run #4 (perf sanity check + RevenueCat purchase-manager
  scaffolding). No new SOCIAL_FEEDBACK.md entries to incorporate (still
  empty). Found two open, unmerged PRs at the start of this run (#1 —
  run #2's gameplay pass; #2 — run #3's persistence work + design pass,
  which already contained #1's commit) — fast-forward-merged PR #2's
  branch (`gxyo11`) into this run's branch first, same approach run #3
  used, so this run continues from the actual latest progress rather
  than redoing it. Baseline-verified the merged state (24/24 assertions
  pass) before making changes. Then: (1) added a perf sanity check to
  the headless autopilot — samples `Performance.TIME_PROCESS`, asserts
  it's sane (not hung/looping); logs ~92ms/frame under this container's
  software-rendered llvmpipe, explicitly caveated in STATE.md as not
  representative of real mobile hardware. (2) Added RevenueCat
  integration: `game/sporewick/scripts/purchase_manager.gd`, an autoload
  singleton wrapping the documented public API of the MIT-licensed
  `godot-x/revenuecat` community plugin (logged in ASSET_LOG.md) behind
  a stub that resolves purchases locally, since that plugin's native
  binaries only run on iOS/Android exports and can't be loaded or tested
  in this Linux sandbox. Wired into two real gameplay effects matching
  the game's original monetization pitch: a one-off "Spore Pack" ($1.99,
  grants 3 spores to inventory) and a "Wick's Blessing" subscription
  ($2.99/mo, halves plot growth time while active, shown with a "✨
  Wick's Blessing active" UI indicator). Logged both names in
  NAME_CHECK.md. Extended the headless autopilot to buy both products
  through the real purchase_package() code path and assert their real
  gameplay effects (inventory +3; a newly-planted plot reaching ready in
  half the normal time) — 35/35 assertions pass, two new screenshots
  (`08_spore_pack_purchased.png`, `09_boosted_growth.png`) confirm the
  shop UI and blessing indicator actually render. Hit and fixed a real
  bug while wiring the autopilot's purchase-await helper: GDScript does
  not support unpacking multiple signal-emitted values via comma-
  separated assignment outside a `var` declaration (`a, b, c = await
  sig`) — that's a parse error, not valid syntax; fixed by connecting a
  one-shot listener before calling `purchase_package()` and polling a
  flag across frames instead, which is also more robust against emission
  timing than relying on `await` registering before a signal fires.
  Documented explicitly in STATE.md (see "RevenueCat: what's real vs.
  what needs a human") that real store/API-key setup and on-device
  purchase testing remain human follow-ups this sandbox cannot do
  itself — not marking the RevenueCat checklist item as fully done.
  Snippet: see /SOCIAL_SNIPPETS/2026-09-17.md.
