# 155 — TUNE: narrow kennel grid portrait yaw into a consistent front-¾ band

**Phase:** 8 (kennel) · **Lens:** X-4 layout/cohesion · **Source:** PO father-pass-19 (`.docs/specs/po-review.md`, HEAD `1f5e899`)

## Problem (PO pass-19, Improvement 1)
The kennel grid renders the 8 dog portraits at wildly inconsistent orientations —
from a stiff dead-front mugshot (Nova/Trulte, ~1–5° off dead-on) to a full side-profile
(Pontus/Bella/Balder/Sniff, ~31–50° off), because the per-cell yaw resolves to
`PORTRAIT_THREE_QUARTER (0.42) + PORTRAIT_YAW_SPREAD[i]` where the spread runs
`[0.12,-0.40,0.34,-0.22,0.46,-0.14,0.26,-0.34]` → total spread ~0.02..0.88 rad (~1°..50°).
This violates the code's own invariant (`:106` "kept within ±0.5 rad so every dog still
reads front-¾ face-on, never a rear/side profile"; `:101` "face clearly to camera") and
disagrees with the modal's consistent front-¾ hero framing of the SAME dog.

## Fix
Re-centre + NARROW `PORTRAIT_YAW_SPREAD` so every cell's effective yaw
(`PORTRAIT_THREE_QUARTER + spread[i]`) stays inside a tight flattering front-¾ band
(~15°–38° off face-on, i.e. ~0.26–0.66 rad) — never the ~1° dead-front end, never the
~50° side-profile end — while PRESERVING the per-cell angle variety 131 added (both signs,
non-monotonic, no two adjacent equal). Pure tuning of the two existing yaw constants; no
owner asset (distinct per-breed MODELS stay owner-gated, BUST-068).

## TDD
- New `tests/test_kennel_grid_portrait_yaw.gd`: assert every effective per-cell yaw is in
  the flattering band (no dead-front, no side-profile) + variety preserved.
- Update `test_kennel_modal_portrait.gd::test_modal_yaw_differs_from_side_facing_cells`:
  the widest cell delta shrinks below the old 0.3 threshold, so re-assert the decoupling
  as "modal (0.0) is strictly more face-on than the widest — still non-trivial — cell".

## Done
- verify gate green; capture the 8-cell grid → no dead-front mugshot, no side-profile,
  face reads toward viewer in every cell; modal front-¾ framing untouched.
