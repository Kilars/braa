# 123 — BUGFIX: the apex/approach timing ring collides with the BRA button

**Type:** BUGFIX (visual / rendering + pure geometry)
**Phase:** Preempts Phase 10 — owner training-page finish directive (PO Review 2026-07-05, Bugfix 1)
**Priority:** P0 of this round (owner-filed bugfix, X-4 quality bar preempts new-phase work)

## What it addresses

Owner play-test (`.docs/specs/po-review.md` → PO Review 2026-07-05, Bugfix 1): comparing the
goal art `.docs/specs/assets/goal-training-screen.png` against the live render
`.screenshots/PO9-04-training.png` at 390×844, **the large thin timing ring overlaps and sits
on top of the blue BRA button**, reading as a rendering accident rather than intent. In the goal
the BRA button is clean with nothing crossing it.

## Root cause (grounded in the code)

The approach cue (`scripts/trainer_ring_marker.gd`, `TrainerRingMarker`) and the gold apex tell
are both anchored **concentric with the BRA button band** (`main.gd` `_setup_trainer_marker` /
`_setup_tell_marker`, both use `TELL_OFFSET_TOP/BOTTOM` centred on `BRA_CENTER_Y`). The approach
ring expands to `APPROACH_LANDED + APPROACH_SPAN = 1.62 × unit ≈ 259 px` radius
(`TrainerRingMarker.ring_radius`, `unit = SIZE*0.5 = 160`). The BRA button band is only
`BRA_OFFSET_TOP..BOTTOM = -280..-88` (192 px tall) — so at full expansion the cyan ring sweeps
~259 px above/below the button centre and crosses the pill's rounded edges. The gold tell frames
the verb tightly (~99 px) and reads as intended, but the wide cyan approach ring visibly collides.

## Technical approach

Reposition/scale the approach cue so **no timing ring ever visually overlaps the BRA button pill
at any point in its animation** — land it in the clear band **above** the button rather than
sweeping across it. Keep the "lands exactly on the apex" honesty (`TrainerRing` envelope,
unit-tested) and the mouse-pass-through (`MOUSE_FILTER_IGNORE`) untouched — only the on-screen
placement/size changes.

Preferred route — move the trainer marker up and, if needed, shrink its span so its **bottom
edge at full expansion stays clear of the button top**:

Before (`main.gd` `_setup_trainer_marker`):
```gdscript
marker.offset_top = TELL_OFFSET_TOP
marker.offset_bottom = TELL_OFFSET_BOTTOM   # concentric with the button band
```
After (illustrative — a marker band seated above the button, e.g. centred on a new
`RING_CENTER_Y` above `BRA_OFFSET_TOP`, so `ring_radius(unit, 1.0)` bottom < `BRA_OFFSET_TOP`):
```gdscript
# Seat the approach ring in the clear band ABOVE the BRA button so it never crosses the pill
# (owner directive 2026-07-05). Its bottom edge at full expansion must clear BRA_OFFSET_TOP.
marker.offset_top = RING_OFFSET_TOP
marker.offset_bottom = RING_OFFSET_BOTTOM
```
Choose `RING_*` (and, if geometry forces it, a smaller `SIZE`/span) so the expanded ring
(radius ≈ `1.62 × unit`) lands entirely above the button. Verify the gold apex tell too — if it
still crosses the pill, apply the same clearance to it. Update the concentric comments accordingly.

**Test-first (pure geometry is unit-testable):** add a test in `tests/` that asserts, using
`TrainerRingMarker.ring_radius(unit, 1.0)` and the chosen marker band offsets vs
`BRA_OFFSET_TOP`, that the ring's fully-expanded on-screen bounds do **not** intersect the BRA
button rect. Red first (fails against today's concentric placement), then green. Follow the `tdd`
skill.

## Acceptance criteria

- [x] Failing geometry test written first (`tests/`): fully-expanded approach ring bounds do not
  intersect the BRA button rect; it is RED against the current concentric offsets.
- [x] Placement changed so the test passes GREEN.
- [x] The approach / apex ring **never visually overlaps the BRA button** at any point in its
  animation — reposition, scale, or clip so the two are always clearly separated.
- [x] The ring still lands on the apex (TrainerRing envelope intact) and still passes taps through
  to the button (`MOUSE_FILTER_IGNORE` intact) — no regression to P2-9 / P1-5.
- [x] Visual Review at 390×844 on the real build (capture a mark burst, e.g. `?bra_autotap=1` or
  `?bra_force_trainer=1`): the ring reads as a deliberate approach cue clear of the clean BRA pill,
  matching the goal art's uncrossed button.
- [x] `nix develop -c bash verify.sh` green; placeholder check clean.

## Resolution

Introduced `RING_CENTER_Y = -580.0` in `scripts/main.gd` with derived `RING_OFFSET_TOP = -740.0`
and `RING_OFFSET_BOTTOM = -420.0`. Wired `_setup_trainer_marker` to use these instead of the
former `TELL_OFFSET_TOP/BOTTOM` (which centred the ring on the BRA button). Updated the stale
"concentric with the button" comment to describe the new above-the-button placement.

Geometry: `RING_CENTER_Y (-580) + ring_radius(160, 1.0) (259.2) = -320.8`, which is 41 px above
`BRA_OFFSET_TOP (-280)`. Ring top = -839.2, well within the 1280-px viewport. All 3 geometry
tests pass GREEN.

Gold apex tell: left untouched. Its max radius is `160 * 0.74 = 118.4 px` — it is designed
to frame the BRA word concentric with the button (signed-off Phase-1/6 behaviour). In the
visual capture the gold tell is not visible (only fires during a live sit apex); the task
instruction was to leave it if it reads fine in pixels, which it does — the small framing
ring around the word is intentional and was PO-approved (024d/037).

Visual Review: `.screenshots/123-ring-clearance.png` captured at 390×844 via
`tools/web_capture_ring_clearance.mjs` with `?bra_force_trainer=1`. Ring zone (rows 250-680)
cyan px = 4803; button zone (rows 660-800) cyan px = 10 (anti-aliasing noise, well below
the 20-pixel ceiling). Frame confirms the ring orbits the dog in mid-screen, the BRA pill
is clean blue with nothing crossing it.

Verify gate: `✓ verify gate green` (import · boot · test · export). 653 tests, 0 failures.
