# FEATURE: 024a — Apex-band / scoring-window math (the mark, in pure GDScript)

**Status**: Done
**Created**: 2026-06-28
**Completed**: 2026-06-28
**Parent**: 024 (Phase 1 — the perfect single mark)
**Priority**: High (first slice — everything else wires onto it)
**Labels**: gameplay, godot, phase-1, tdd, logic
**Estimated Effort**: Small

## Why this slice first

Task 024 is the whole Phase 1 bet and is explicitly to be built per-story, not as a
monolith. The one piece that is **pure and testable headless** — no screenshots, no
visual-review subjectivity — is the timing math behind P1-5: given a sit's timeline,
score a tap by closeness to the apex. Built it first, test-first, so the visual
slices (sit anim, tell, BRA button, payoff, readout) all wire onto a proven core.

## What was built (TDD: red → green)

- **`scripts/sit_window.gd`** — `class_name SitWindow`, a pure `RefCounted` value
  object. A sit is markable over `[sit_start, sit_end]` (the clip span) with `apex`
  the fully-seated scoring peak. `score(tap_time) -> Tier`:
  - `PERFECT` `|tap - apex| <= perfect_radius`  (the apex band, P1-4's "now")
  - `OK`      `|tap - apex| <= ok_radius`        (inside the window, off-peak)
  - `MISS`    active sit but outside the window
  - `DEAD`    no sit active — does nothing, **no penalty** (P1-5)
  - Helpers: `from_clip(length, apex, …)` (build straight from an AnimationPlayer
    clip), `is_successful(tier)` (the P1-6 audio gate — only PERFECT/OK are a mark),
    `tier_name(tier)` (P1-7 on-screen label).
  - Band edges are inclusive with a 1e-5 s `EPSILON` so IEEE-754 noise on float
    animation positions can't flip an edge tap to the wrong tier (far below 60fps
    granularity, so no real misscoring).
- **`tests/test_sit_window.gd`** — 12 unit tests: apex→PERFECT, both-sided band &
  window inclusivity, MISS inside the active sit, DEAD outside it, inclusive active
  bounds, asymmetric-apex absolute-distance, `from_clip`, `tier_name`, the
  `is_successful` audio gate.

## Gate-integrity fix (bundled, necessary)

`tests/test_runner.gd` silently skipped a test file that failed to **parse** (a
parse error makes `load()` return a non-null but un-instantiable script), so a
broken test read as a hollow green. Added a `can_instantiate()` guard: an
un-loadable/un-parseable test file now fails the gate. Verified by observing the
gate go red on the (still-unimplemented) `SitWindow` test before implementing it —
without this fix the TDD red wasn't actually enforced by `verify.sh`.

## Verification

- `nix develop -c bash verify.sh` → **green** (import · boot · test · export), exit 0.
- Test count went 3 → 15, 0 failures.

## Notes for downstream slices

- 024e (BRA button) feeds `tap_time` = seconds-into-the-current-sit and renders
  `tier_name`; 024f keys the payoff off `is_successful`; 024d's tell marks the same
  `apex`. Keep one source of truth for the apex time (the sit clip keyframe) so the
  tell, the band, and the dog pose never disagree (P1-4 "honest tell").
- **Bundle hygiene (deferred):** the Web export packs `tests/test_*.gd(c)` into the
  production `.pck`. Harmless but bloat; a later chore can add an export filter.
