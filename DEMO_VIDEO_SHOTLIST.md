# Demo Video Shot List — Sporewick

For the Shipaton submission's required demo video (<2 min, real
gameplay, no third-party trademarks/music). This is a ready shot list a
human can record from in a few minutes on-device or via a Godot editor
run — not a substitute for the recording itself, which needs a human
(screen capture, voice or on-screen text, export/trim to a video file).

**Total target length: ~90 seconds.** Every beat below is something the
headless verification autopilot already exercises and has a matching
reference screenshot in `game/sporewick/verification_output/` — use
those to confirm what each moment should look like before recording.

| # | Time | Shot | Reference screenshot |
|---|------|------|----------------------|
| 1 | 0:00–0:08 | Cold open on the empty garden — 4 plots, currency 0, compendium 0. Let it breathe for a couple seconds so it reads as a real app, not a jump-cut. | `00_start.png` |
| 2 | 0:08–0:18 | Tap two empty plots to plant. Show the growing state (icon dimmed, "growing" status). | `01_planted.png` |
| 3 | 0:18–0:28 | Time-skip or fast-forward (video edit cut, or just wait — 60s real growth, consider spending an IAP here instead, see beat 6) to plots turning Ready. | `02_grown.png` |
| 4 | 0:28–0:36 | Harvest both plots — show inventory count go from 0 to 2, currency tick up. | `03_harvested.png` |
| 5 | 0:36–0:48 | Combine at the Wick — show the compendium gain a new hybrid entry and currency jump (the bigger first-discovery bonus). This is the core "aha" moment of the loop — hold on it a beat longer than the others. | `04_combined.png` |
| 6 | 0:48–1:00 | Plant two of the *same* spore type, harvest, combine at the Wick — show it resolve to a distinct "refined" result, not a generic fallback. This is worth calling out on-screen/voice as a deliberate design choice. | `05_same_type_combined.png` |
| 7 | 1:00–1:15 | Open the shop, buy the Spore Pack IAP — show inventory jump by 3 instantly (real RevenueCat purchase flow, not a mock). | `08_spore_pack_purchased.png` |
| 8 | 1:15–1:30 | Buy the Wick's Blessing subscription — show the "✨ Wick's Blessing active (2x growth)" indicator appear, then plant a plot and show it reaching Ready noticeably faster than the earlier unboosted plants. | `09_boosted_growth.png` |
| 9 | 1:30–1:40 | Close the app (or background it), reopen — show a plot that was mid-grow when closed now sitting at Ready, demonstrating offline-progress catch-up rather than the timer having silently reset or stalled. | `07_offline_catchup.png` |
| 10 | 1:40–1:50 | End on the compendium view / count, currency total — a "here's what you've built so far" closing beat. | — |

## Notes for whoever records this
- **No third-party music or trademarks.** Either record silent and add
  narration/captions, or use an original/CC0-licensed track logged in
  `ASSET_LOG.md` first — don't grab something off YouTube's audio
  library without checking the actual license text (same rule the whole
  project follows for art).
- Real device or Godot editor capture both work; either way it should be
  the actual app running, matching the "real output, not a mockup"
  standard the rest of this project holds to.
- Fastest path to beats 3 and 8 without sitting through 60-second real
  timers: temporarily lower `GROW_SECONDS` in `main.gd` for the
  recording session only, or just accept the wait and cut it in editing
  — don't ship a permanently-changed timer just to make the video faster.
- If the on-screen UI text is hard to read at video resolution, consider
  a brief captioned callout for beats 5, 6, and 9 specifically — those
  are the three moments that differentiate this from a generic idle
  game (real crossbreeding payoff, a deliberate same-type design choice,
  and working offline progress) and are worth making sure land clearly.
