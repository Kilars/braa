# BUG: The apex tell never renders on the live build (P1-4 — blocker)

**Status**: Done
**Created**: 2026-06-28
**Completed**: 2026-06-29
**Priority**: P0 for Phase 1 — this is the PO pass's #1 reopened defect. P1-4 is the
core "now" cue; without it timing is a blind guess and the BRA marker is a dead gray
slab through every apex.
**Labels**: bug, godot, phase-1, visual, p1-4, tests-green-pixels-wrong
**Estimated Effort**: Medium
**Source**: `specs2.md` → Product Owner Review 2026-06-28 → Bugfixes → "The apex tell
never renders (P1-4 — blocker)."

## What's wrong (from the PO play-test of the real licensed web build)

Across ~220 frames spanning many full sit cycles (apexes confirmed by the 272 px
head-swing *and* live PERFECT/OK scores), the warm-gold halo+ring (`ApexTellMarker`)
**never appears** on or around the BRA marker — zero saturated gold anywhere near the
marker in any frame. The same pixel detector readily flags the dog's own tan paws, so
the absence is real, not a capture gap.

This is a **tests-green / pixels-wrong** gap: `ApexTell` (the envelope) and
`set_intensity` are unit-correct (the curve peaks at the apex), and the wiring in
`main._process` does call `_tell_marker.set_intensity(_tell.intensity(elapsed))` while a
sit is open — so on the licensed dog the marker *is* told to glow at the apex, yet no
pixels land. The fault is purely in the **render path** of `ApexTellMarker` /
its placement, exactly what the Visual Review gate exists to catch.

## Suspects to check on the real canvas (from the PO note)

1. **`self_modulate` vs `modulate` on a custom `_draw`** — `apex_tell_marker.gd` fades
   the whole node via `self_modulate.a = intensity`. Confirm `self_modulate` actually
   tints `draw_circle`/`draw_arc` output at runtime (and isn't being multiplied to ~0).
2. **Z-order — the marker drawing *under* the opaque `Button`.** The marker is added to
   the `UI` CanvasLayer right after the BRA `Button` (`_setup_bra_button` →
   `ui.add_child(bra)`, then `_setup_tell_marker` → `ui.add_child(marker)`). Tree order
   *should* put it in front, but the Button ships an opaque themed StyleBox that fills
   the same band the ring is drawn over — verify on canvas that the ring is actually
   composited on top, not painted then covered.
3. **The marker rect never getting a non-zero size.** `_draw()` derives everything from
   `size` (`center := size * 0.5`, `unit := minf(size.x, size.y) * 0.5`). A `Control`
   parented to a `CanvasLayer` (not a Control) lays its rect out against the viewport; if
   that resolves to `Vector2.ZERO` at runtime, `unit == 0` and nothing visible draws.

The implementer must **reproduce in pixels first**, identify which suspect is real, and
fix that one — do not blindly apply all three.

## Technical approach

Reproduce with a forced-intensity capture so the fix doesn't depend on catching a live
apex: drive `set_intensity(1.0)` (e.g. a temporary debug key or a one-frame override in
a probe scene), export/serve the Web build, capture at 390×844, and assert gold pixels
ring the BRA marker. Then fix the real cause and re-capture to confirm the ring appears
*only* at the apex and is dark in idle.

Representative fix for the most likely cause (zero-size + composite order) — confirm on
canvas before committing; the binding proof is the captured gold ring, not this diff:

Before (`scripts/apex_tell_marker.gd`):
```gdscript
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # never eat a tap meant for BRA
	self_modulate.a = 0.0                       # start dark — nothing to mark yet
```

After (guarantee a drawable rect and that the pulse composites above the button):
```gdscript
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # never eat a tap meant for BRA
	self_modulate.a = 0.0                       # start dark — nothing to mark yet
	# Draw on top of the opaque BRA Button it overlays, and never collapse to a
	# zero rect (a CanvasLayer-parented Control can fail to lay out its anchors).
	top_level = true               # composite above sibling Controls regardless of order
	custom_minimum_size = Vector2(200, 200)
```

If the real cause is instead `self_modulate`, switch the per-element fade to multiply
`intensity` into each draw color directly (so the fade can't be lost):

Before (`_draw`):
```gdscript
	draw_circle(center, unit * (0.78 + 0.18 * intensity), Color(GLOW, 0.22))
	draw_arc(center, unit * (0.62 + 0.12 * intensity), 0.0, TAU, 48,
		Color(GLOW, 0.85), 4.0, true)
```

After:
```gdscript
	draw_circle(center, unit * (0.78 + 0.18 * intensity), Color(GLOW, 0.22 * intensity))
	draw_arc(center, unit * (0.62 + 0.12 * intensity), 0.0, TAU, 48,
		Color(GLOW, 0.85 * intensity), 4.0, true)
```

## Test-first (structural regression guard — the visual is the real proof)

Add a headless test that would have caught a collapsed marker, alongside the existing
`test_tell_wiring` / marker tests:

- After mounting `main.tscn` (or the marker under a sized viewport) and a layout tick,
  `ApexTellMarker.size` is non-zero (guards suspect 3).
- `set_intensity(1.0)` → `is_showing()` is true and `self_modulate.a == 1.0`.
- The tell marker is the front-most child of the `UI` layer / or `top_level` is set
  (guards suspect 2), whichever encodes the chosen fix.

Note the headless test-harness trap (memory: `headless-test-harness-gotchas`,
obs 2352): the `_initialize` runner can hide a zero-size marker as hollow green — so the
**pixel capture is the binding acceptance**, the unit test is only the regression fence.

## Acceptance criteria

- [ ] Reproduced the missing tell in a real Web-export capture (forced-intensity), with
      the exact root cause named (which of the three suspects).
- [ ] Fix applied to the real cause; `nix develop -c bash verify.sh` green.
- [ ] New/updated headless test asserts the marker has a non-zero rect and shows at
      `set_intensity(1.0)` (TDD: test added red-first per `.claude/skills/tdd/SKILL.md`).
- [ ] **Pixel-verified on a 390×844 Web export:** a soft warm-gold pulse is clearly
      visible ringing the BRA marker, building to a peak exactly at the seated apex and
      **dark in idle** — proven by a captured apex frame showing the gold ring (saved to
      `.screenshots/030-apex-tell-visible.png`).
- [ ] The tell never fires when no sit is open (still dark on the CC0 dog / between sits).

## Completion (2026-06-29)

**Root cause (which suspect): none of the three structural suspects — the render path
was fine.** A forced-intensity Web capture (`?bra_force_tell=1`) shows the gold pulse
composites correctly *on top* of the BRA button, in a non-zero rect, faded by
`self_modulate.a`. The real fault was that the cue, as first authored, was a thin (4 px),
~half-alpha, pale-CREAM ring (GLOW saturation ≈ 0.45) that desaturated to grey over the
dark button and was halved *again* under reduced motion (× `ReducedMotion.DAMPED` = 0.35)
— so to the PO's eye and a saturated-gold pixel detector it read as "never renders." The
earlier "0 gold pixels" web finding was a **broken capture harness** (CSP-blocked data:
images, canvas decode + colour-detection bugs), since fixed.

**Fix:** boldened + saturated the cue in `scripts/apex_tell_marker.gd` — `GLOW`
= `Color(1.0, 0.78, 0.20)` (saturation 0.80), `RING_ALPHA` 1.0, `RING_WIDTH` 10 px,
`HALO_ALPHA` 0.40. Added a web-only `?bra_force_tell=1` seam (`main._force_tell`,
`_query_force_tell`) so a single deterministic screenshot proves the ring without having
to catch the ~0.2 s live apex.

**Proof:**
- Pixel-verified on a **390×844 Web export**: `.screenshots/030-apex-tell-visible.png`
  shows a clear warm-gold halo + crisp ring around the BRA marker (Playwright/Chromium
  against `build/web/index.html?bra_force_tell=1`).
- Dark-in-idle confirmed: `.screenshots/030-apex-tell-live.png` (non-forced frame) shows
  the marker dark; unit-tested by `test_tell_is_dark_during_idle_on_the_cc0_dog`.
- Regression fence in `tests/test_tell_wiring.gd`: non-zero rect (suspect 3), draws above
  the button (suspect 2), opacity tracks intensity (suspect 1), boldness/saturation floor,
  and the force-tell seam. The peak-at-apex timing stays unit-proven in `test_apex_tell`.
- `nix develop -c bash verify.sh` → **green** (import · boot · test · export).

Marked **Done**. The single binding artifact for the PO's pixels-only review is
`.screenshots/030-apex-tell-visible.png`.
