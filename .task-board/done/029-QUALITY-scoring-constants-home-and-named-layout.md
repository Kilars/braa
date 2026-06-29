# QUALITY: 029 — Put the scoring bands in the scoring class; name the magic layout numbers

**Status**: Done — 2026-06-28. Pure refactor, no behavior change; full gate green
(import · boot · test · export), **98 tests** (96 + 2 new pinning the canonical radii).
- `SitWindow.DEFAULT_PERFECT_RADIUS := 0.08` / `DEFAULT_OK_RADIUS := 0.20` now live next
  to the scoring math; `DogDirector.sit_window()` references them and no longer declares
  its own `PERFECT_RADIUS`/`OK_RADIUS` (no test referenced the old consts → none to update).
- `main.gd` now names the portrait layout literals: `VIEWPORT_W/H` feed `_viewport_aspect`;
  `BRA_OFFSET_*`, `TELL_*` (derived from the button band via `TELL_RING_MARGIN` so the pulse
  follows the verb across a resize), and `READOUT_OFFSET_*` replace the bare floats. Offsets
  resolve to identical pixels (TELL top = BRA top − 4 = −284; bottom = BRA bottom + 4 = −84),
  so no visual change — boot leg confirms a clean load.
**Created**: 2026-06-28
**Priority**: Medium (discoverability / single-source-of-truth; small, safe)
**Labels**: quality, godot, phase-1, readability
**Estimated Effort**: Small

## Why now

Two small but real source-of-truth issues, both safe to fix without behavior change:

1. **Scoring bands live in the animation driver, not the scoring class.**
   `scripts/dog_director.gd:11-12` owns `PERFECT_RADIUS := 0.08` and `OK_RADIUS := 0.20`
   — the apex±80 ms / ±200 ms gameplay rule. But `SitWindow` (`scripts/sit_window.gd`) is
   the scoring class; it receives these as constructor args and has no idea they have a
   canonical value. A designer tuning the PERFECT band would reasonably look in the
   scoring class and not find it. The radii are a scoring rule, not an AnimationPlayer
   concern — a responsibility leak that will bite when difficulty tuning arrives.

2. **Unnamed, coupled layout literals in `main.gd`.** `_setup_bra_button` /
   `_setup_tell_marker` / `_setup_readout` (`scripts/main.gd:260-313`) carry ~14 bare
   float offsets. The tell marker's `offset_top = -284.0` is deliberately 4 px above the
   button's `-280.0` so the pulse rings the verb — an invisible coupling that breaks
   silently if the button band moves and the marker isn't moved with it. The pinned
   `720×1280` logical viewport is also a bare computed literal in `_viewport_aspect`
   (`main.gd:166,169`).

## Technical Approach (refactor only — values unchanged)

**Scoring bands → `SitWindow`:**

```gdscript
# scripts/sit_window.gd — add the canonical defaults next to the math that uses them
const DEFAULT_PERFECT_RADIUS := 0.08  ## specs2.md: PERFECT band is apex ±80 ms
const DEFAULT_OK_RADIUS := 0.20       ## specs2.md: OK window is apex ±200 ms

# scripts/dog_director.gd::sit_window — reference the scoring class, drop the local consts
return SitWindow.from_sit_clips(start_len, loop_len,
    SitWindow.DEFAULT_PERFECT_RADIUS, SitWindow.DEFAULT_OK_RADIUS)
```

Keep `from_sit_clips` taking explicit radii (so difficulty can override later) — only the
**home of the default** moves. Update any test that referenced `DogDirector.PERFECT_RADIUS`
to `SitWindow.DEFAULT_PERFECT_RADIUS`.

**Name the layout constants** at the top of `main.gd`, grouped so the button/marker
coupling is explicit and greppable:

```gdscript
# scripts/main.gd — near the existing FRAME_FILL const
const VIEWPORT_W := 720.0   # the project's pinned logical viewport
const VIEWPORT_H := 1280.0
const BRA_OFFSET_TOP := -280.0
const BRA_OFFSET_BOTTOM := -88.0
const TELL_OFFSET_TOP := BRA_OFFSET_TOP - 4.0    # 4 px above the button → rings the verb
const TELL_OFFSET_BOTTOM := BRA_OFFSET_BOTTOM + 4.0
# _viewport_aspect uses VIEWPORT_W / VIEWPORT_H; the setup fns use the named offsets.
```

Expressing `TELL_OFFSET_TOP` in terms of `BRA_OFFSET_TOP` makes the coupling survive a
resize. Don't rename behavior, don't move widgets — same pixels, named.

## Acceptance Criteria

- [x] `DEFAULT_PERFECT_RADIUS` / `DEFAULT_OK_RADIUS` live on `SitWindow`; `DogDirector`
      references them and no longer declares its own scoring radii.
- [x] No test referenced the old `DogDirector` radii (grep-confirmed), so none needed
      updating; the scored tiers are numerically identical (existing scoring tests stay
      green; 2 new tests pin the canonical defaults + spec bands).
- [x] The BRA button / tell marker / readout offsets and the `720×1280` viewport are named
      constants; the tell-marker offset is expressed relative to the button band
      (`TELL_OFFSET_TOP = BRA_OFFSET_TOP - TELL_RING_MARGIN`).
- [x] No visual change (offsets resolve to the same pixels); boot + export stay clean.
- [x] Full gate green: `nix develop -c bash verify.sh`; 98 tests (was 96 + 2 new), 0 failures.
