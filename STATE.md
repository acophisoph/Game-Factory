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
- Last worked: 2026-09-27 (run #2 — gameplay pass)
- Days remaining in submission window: **3 days** (from 2026-09-27 to
  2026-09-30 11:45pm PDT)

## ⚠️ CRITICAL TIMELINE FLAG (read this first, every run until resolved)
This routine is scheduled for Thursday/Sunday, but the previous run was
2026-09-06 and this one is 2026-09-27 — **three weeks of runs did not
happen** (schedule gap, not a project decision). The result: only 3 days
remain in the Shipaton window, and the checklist below still has 9 of 12
items untouched, including every item that requires the *human* (Emily),
not just more agent work:
- **Store developer accounts.** If an Apple Developer Program account,
  Google Play Console account, and/or Samsung Galaxy Store seller
  account are not *already* set up and verified, this cannot ship in
  time — Apple ID verification and Google Play's mandatory closed
  testing period for new personal developer accounts (20 testers / 14
  days) are both human-gated processes an agent cannot shortcut or do
  on your behalf.
- **RevenueCat account + API keys** — needed before SDK integration can
  be tested end to end; agent can wire the SDK calls but needs real
  keys from your RevenueCat dashboard to verify a sandbox purchase.
- **Actual submission to the store** — requires your login/credentials;
  no agent action can publish a listing on your behalf.
Recommendation given 3 days: pick whichever store you already have a
verified, review-ready account on (Samsung Galaxy Store has historically
had the fastest/simplest first-review path with no mandatory testing
period; this needs re-confirming against current Samsung policy before
relying on it) and tell the next run which store to target, so remaining
agent effort goes toward that store's specific requirements instead of
generic pipeline work. If no store account is ready today, the realistic
outcome is missing this Shipaton window — flagging now rather than
after more polish work, per the routine's own point (Section 9): the
human should see this before more time is spent.

## Pipeline checklist for current game
- [x] Idea locked (one-paragraph pitch, genre, core loop) — see above
- [x] Name checked against known works (see NAME_CHECK.md) — "Sporewick" locked after 3 prior candidates collided
- [x] Minimal playable vertical slice (core verbs wired end to end) — plant → grow → harvest → combine at Wick → compendium/currency update, all wired and verified headlessly (see Testing note below)
- [x] Gameplay pass (feels functional, not just wired) — growth timing raised from 3s prototyping placeholder to 45s (real-verify path still uses 3s via a separate constant so headless autopilot stays fast); resolved the same-type-combo open question as a deliberate "Twin Bloom" result instead of silent "Mystery Spore" fallback. Plot count (4) and 3-recipe table are still not balance-tuned — acceptable per "good enough for now," flagged below, not a blocker given the timeline.
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
- ~~Same-base-type combine had no defined behavior~~ — **resolved this
  run**: now a deliberate "Twin Bloom: <type>" result (see main.gd).
- Growth timer raised from 3s to 45s this run — still tuned for a fast,
  demoable pace rather than a deep idle-game timescale (minutes-to-hours
  with offline-progress catch-up), which is the "real" version of this
  system. Given the 3-day timeline (see CRITICAL TIMELINE FLAG above),
  45s is being treated as "good enough for now" — it's also short enough
  to show real plant→grow→harvest loops on camera for the demo video
  without heavy edits.
- No persistence yet (nothing saved between sessions) — needed before
  the Testing pass can be considered complete. Given the timeline, this
  is now higher-priority than further balance work since a persisted
  save is closer to store-readiness than gameplay polish is.
- No RevenueCat integration yet — needs real API keys from the human's
  RevenueCat dashboard (see CRITICAL TIMELINE FLAG); agent can wire the
  SDK call shapes without them but can't verify a real sandbox purchase.

## Pipeline checklist progress note
Run #1 spent its budget on inception per Section 2. This run (#2) did the
planned Gameplay pass (growth timing, same-type-combo decision) and fixed
a real bug found along the way in the shared headless-verify tool (see
changelog). Given only 3 days remain, the next run's priority should NOT
be further gameplay/design polish — it should be, in order: (1) get an
answer from the human on which store to target (see CRITICAL TIMELINE
FLAG), (2) minimal persistence (save/load) since Testing needs it, (3)
RevenueCat SDK wiring using whatever keys are available, (4) store
listing assets (icon/screenshot) since those are pure agent-doable work
that doesn't block on anything.

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
- 2026-09-27: Run #2 (gameplay pass). **Flagging a schedule gap**: this
  routine is meant to run Thu/Sun, but the prior run was 2026-09-06 — 21
  days and roughly 6 missed firings, not a deliberate pause. That leaves
  only 3 days to the Sep 30 11:45pm PDT deadline with 9 of 12 checklist
  items untouched. Added a top-of-file CRITICAL TIMELINE FLAG for the
  human and for future runs. Did the planned gameplay pass anyway: raised
  the growth timer from a 3s prototyping placeholder to 45s (kept 3s for
  the `--verify` autopilot path via a new `VERIFY_GROW_SECONDS` constant
  so headless checks stay fast), and resolved the open same-type-combine
  question as a deliberate "Twin Bloom: <type>" result instead of an
  undecided silent fallback. While re-running the headless verifier to
  confirm the change, found and fixed a real bug in the shared
  `tools/run_headless_verify.sh`: passing a relative project dir caused
  Godot's internal chdir-on `--path` to double the default screenshot
  output path (`game/sporewick/game/sporewick/verification_output/...`
  instead of `game/sporewick/verification_output/...`) — fixed by
  resolving `PROJECT_DIR` to an absolute path up front. This affects
  every future game that uses this tool, not just Sporewick. Re-ran
  verification after the fix: all 9 autopilot assertions pass with fresh
  real rendered screenshots (one of which happened to exercise the new
  Twin Bloom path, since the autopilot's random spore picks landed on
  the same type both times). Not shipped snippet Y/N: no, see
  /SOCIAL_SNIPPETS/2026-09-27.md.
