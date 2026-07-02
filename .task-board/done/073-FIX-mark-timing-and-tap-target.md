# 073 — FIX: the mark is hard to time — clearer tap target + easier (late-biased) PERFECT

**Type:** FIX (game-logic TDD + Visual Review) · **Phase:** 3 (current) · **Source:** PO Review
2026-07-02 `po-review.md` **Actionable note 5** ("The trick is hard to time, the circle apex
makes users wanna swipe not tap. it needs to be a button, also users are typically late … perhaps
dog slower or a bit later tap for perfect") · **Priority:** **P1 for this phase — core-loop feel.**
This is the single most-used interaction in the whole game (tap BRA the instant the dog sits); the
PO says it plays "a bit too hard," so a mistuned mark undercuts every other Phase-3 feature.

## What it addresses

Two coupled halves of one felt problem — *the mark is hard to land*:

1. **Tap target reads as a swipe, not a tap.** The approach-cue **trainer ring** (058, P2-9,
   `scripts/trainer_ring.gd` + `trainer_ring_marker.gd`) is a circle that *shrinks onto* the BRA
   button and lands at the apex. A shrinking circle converging on a point is the visual grammar of
   a *trace/swipe-into-the-target* gesture (rhythm-game muscle memory), so players try to swipe the
   ring instead of tapping the button. The BRA button already spans the bottom band
   (`BRA_OFFSET_*` in `main.gd`) — the fix is to make the tap affordance **unambiguously a tap**:
   the ring should read as "tap when the ring lands," and a tap anywhere on the ring/button target
   must register the mark (never require a drag/swipe).
2. **PERFECT is too tight and too early for real players.** `SitWindow` scores PERFECT only within
   a **symmetric** ±0.08 s of the apex (`DEFAULT_PERFECT_RADIUS`), OK ±0.20 s. The PO observes
   players are *typically late* — they tap just after the fully-seated peak. A symmetric band
   punishes the natural human reaction delay. Good = a slightly-late tap still lands PERFECT.

## Technical approach

### Half 1 — timing (TDD, pure logic in `scripts/sit_window.gd`)

Make the scoring bands **late-biased**: keep the early edge where it is (tapping *before* the dog
is seated should stay strict — that is genuinely too early) but **extend the late edge** so the
natural reaction-delay tap still scores PERFECT. This targets the PO's exact diagnosis ("users are
typically late") without desyncing the honest visual apex — the tell/ring still peak at `apex`; we
only forgive lateness more. Introduce an explicit `late_bias` so the asymmetry is a named, tunable
design decision, not a magic tweak.

**Before** (`scripts/sit_window.gd`):
```gdscript
const DEFAULT_PERFECT_RADIUS := 0.08  ## the PERFECT band is apex ±80 ms
const DEFAULT_OK_RADIUS := 0.20       ## the OK window is apex ±200 ms
...
func score(tap_time: float) -> Tier:
	if tap_time < sit_start - EPSILON or tap_time > sit_end + EPSILON:
		return Tier.DEAD
	var dist := absf(tap_time - apex)
	if dist <= perfect_radius + EPSILON:
		return Tier.PERFECT
	if dist <= ok_radius + EPSILON:
		return Tier.OK
	return Tier.MISS
```

**After** (`scripts/sit_window.gd`) — a `late_bias` widens both bands *after* the apex only:
```gdscript
const DEFAULT_PERFECT_RADIUS := 0.08  ## PERFECT reaches apex−80 ms … apex+(80+late_bias) ms
const DEFAULT_OK_RADIUS := 0.20       ## OK reaches apex−200 ms … apex+(200+late_bias) ms
const DEFAULT_LATE_BIAS := 0.09       ## extra grace AFTER the apex (PO note 5 — players tap late)
...
## `late` (>=0) is added to the after-apex edge of each band; before-apex stays strict.
func score(tap_time: float) -> Tier:
	if tap_time < sit_start - EPSILON or tap_time > sit_end + EPSILON:
		return Tier.DEAD
	var signed := tap_time - apex                       # >0 = late (after seated peak)
	var perfect_late := perfect_radius + late_bias
	var ok_late := ok_radius + late_bias
	if signed >= -perfect_radius - EPSILON and signed <= perfect_late + EPSILON:
		return Tier.PERFECT
	if signed >= -ok_radius - EPSILON and signed <= ok_late + EPSILON:
		return Tier.OK
	return Tier.MISS
```

Thread `late_bias` through `_init` / `from_sit_clips` / `from_clip` with `DEFAULT_LATE_BIAS` as the
default so existing call sites keep working. Keep the early edge exactly as today (before-apex is
unchanged), so this can only *help* a late tap and never re-scores an early tap more leniently.

Tune the number against feel: `late_bias = 0.09` roughly doubles the after-apex PERFECT reach
(80 → 170 ms late) — a comfortable human reaction window — while a 90 ms-early tap is still MISS.
The implementing agent may adjust within reason; the acceptance test asserts the *asymmetry
property*, not one magic constant.

#### TDD (follow `.claude/skills/tdd/SKILL.md`) — extend `tests/test_sit_window.gd`

Write these FIRST and watch them go RED on the symmetric band, then GREEN after the change:

```gdscript
func test_slightly_late_tap_is_still_perfect() -> void:
	# A tap 120 ms AFTER the apex — a natural reaction delay — now lands PERFECT (was MISS at ±80).
	var w := SitWindow.from_sit_clips(0.6, 0.5, SitWindow.DEFAULT_PERFECT_RADIUS,
		SitWindow.DEFAULT_OK_RADIUS)   # apex = 0.6
	assert_eq(w.score(0.6 + 0.12), SitWindow.Tier.PERFECT,
		"a 120 ms-late tap should be forgiven as PERFECT (PO note 5)")

func test_early_tap_stays_strict() -> void:
	# The before-apex edge is UNCHANGED — tapping 120 ms early is not PERFECT (dog not yet seated).
	var w := SitWindow.from_sit_clips(0.6, 0.5, SitWindow.DEFAULT_PERFECT_RADIUS,
		SitWindow.DEFAULT_OK_RADIUS)
	assert_ne(w.score(0.6 - 0.12), SitWindow.Tier.PERFECT,
		"an early tap must stay strict — late bias must not loosen the early edge")

func test_band_is_late_biased_not_symmetric() -> void:
	# The PERFECT band reaches further after the apex than before it.
	var w := SitWindow.from_sit_clips(0.6, 0.5, SitWindow.DEFAULT_PERFECT_RADIUS,
		SitWindow.DEFAULT_OK_RADIUS)
	var reach_early := 0.6 - 0.6            # symmetric edge would be perfect_radius each side
	assert_eq(w.score(0.6 + SitWindow.DEFAULT_PERFECT_RADIUS + SitWindow.DEFAULT_LATE_BIAS - 0.005),
		SitWindow.Tier.PERFECT, "late edge = perfect_radius + late_bias")
```

Keep every existing `test_sit_window.gd` assertion green (the before-apex and DEAD cases are
unchanged). If any existing test asserted a symmetric *late* MISS just past ±0.08, update it to the
new late edge with a comment pointing at PO note 5 (that is a real design change, not a hollow fix).

### Half 2 — tap affordance (Visual Review, `scripts/trainer_ring*.gd` + the BRA button)

Make the target read as *tap*, not *swipe*. Concretely (implementing agent picks the cleanest that
reviews well on a 390×844 phone-portrait viewport):
- The trainer ring lands **concentric on the BRA button** and the button reads as the thing you
  press — e.g. give the button a subtle filled/raised circular hit-target look so the shrinking
  ring reads as "press when it lands here," not "drag along this path."
- Ensure a **tap** (press+release in place) anywhere on the button/ring target registers the mark;
  never require a drag. (The existing `Button.pressed` path is already tap-based — confirm the ring
  is not intercepting input or drawing over the button in a way that invites a swipe.)
- No new placeholder art — reuse the existing ring/button rendering; this is a legibility tweak.

Spawn a Visual-Review subagent per the mother-prompt visual protocol (screenshots on phone-portrait,
mid-approach + at-apex frames); its findings are blocking. Reuse `tools/web_capture_*.mjs` /
`tools/po_*.mjs` on the local licensed bundle (`env -u LD_LIBRARY_PATH` for local Chromium).

## Acceptance criteria

- [x] TDD: `test_slightly_late_tap_is_still_perfect`, `test_early_tap_stays_strict`, and
      `test_band_is_late_biased_not_symmetric` written first, RED on the symmetric band → GREEN after
      the `late_bias` change.
- [x] `SitWindow` scores a slightly-late tap (natural reaction delay, ~120 ms after apex) as PERFECT;
      an equally-early tap is NOT upgraded (early edge unchanged); `late_bias` is a named tunable
      threaded through `_init`/`from_sit_clips`/`from_clip` with a documented default.
- [x] All pre-existing `test_sit_window.gd` cases still pass (any that asserted the old symmetric
      late edge are updated with a PO-note-5 rationale, not deleted to hide a regression).
- [x] Visual Review (phone-portrait): the apex target reads as a **tap** button, not a swipe path;
      a tap registers the mark; ring lands concentric/legible over the button. Reviewer sign-off is
      blocking; capture mid-approach + at-apex frames. **PASS** (`.screenshots/058-trainer-ring.png`,
      cyan ring drew 4958 px; orchestrator confirmed the frame by eye — see completion note).
- [x] Placeholder check clean on the diff (no stub/placeholder art introduced).
- [x] `nix develop -c bash verify.sh` green (import·boot·test·export).

## Notes

Deliberately does NOT change animation playback speed (slowing the dog) — that risks desyncing the
SitWindow (built from clip length at 1×) with the tell/ring. The late-biased window is the honest,
low-risk lever that directly matches "users are typically late." If the owner still finds it hard
after this, a follow-up can revisit dog speed. The scored apex stays where the tell/ring peak, so
the on-screen feedback remains truthful.

## Completion note

Two halves shipped for PO note 5.

**Timing (TDD, `scripts/sit_window.gd`):** added `const DEFAULT_LATE_BIAS := 0.09` + a `late_bias`
field threaded through `_init`/`from_clip`/`from_sit_clips` (defaults preserve every call site).
`score()` went from a symmetric `|tap-apex| <= radius` to a signed, late-biased band: the
before-apex (early) edge is byte-identical to before, the after-apex edge is extended by
`late_bias`, so PERFECT now reaches apex−80 ms … apex+170 ms and OK apex−200 ms … apex+290 ms. A
natural-reaction-delay tap (~120 ms late) lands PERFECT; an equally-early tap stays strict. Three
new tests written first (RED on the symmetric band → GREEN). Two pre-existing `test_sit_window.gd`
cases + one `test_sit_session.gd` case that had asserted the old symmetric late edge were updated
with a PO-note-5 rationale (real design change, not a hollow edit).

**Tap affordance (Visual Review, `scripts/main.gd`):** the BRA button background went from a fully
transparent `StyleBoxEmpty` to a rounded pill `StyleBoxFlat` (soft warm-white fill, more opaque
when pressed). The shrinking P2-9 trainer ring (already `MOUSE_FILTER_IGNORE`, non-interactive)
now reads as landing *on* a bounded, pressable button — "tap when the ring meets the button", not
a swipe path. Visual-Review subagent PASS on the real GL web bundle at 390×844
(`web_capture_trainer.mjs build/web`, cyan ring 4958 px, concentric on the pill); orchestrator
confirmed by eye (`.screenshots/058-trainer-ring.png`): bounded pill under a centred licensed
Labrador, ring concentric over "BRA", Tricks top-left + coins top-right clear, no letterbox.

No animation-speed change (would desync the window from the tell/ring). Verify gate green
(import·boot·test·export); placeholder check clean.
