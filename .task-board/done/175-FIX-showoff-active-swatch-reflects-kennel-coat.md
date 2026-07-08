# 175 — FIX: completion-menu «Raser» active-row coat swatch reflects the active KENNEL dog's coat

**Source:** PO father-pass-40 (X-4), `.docs/specs/po-review.md` 2026-07-08.

## Problem
174 re-pointed the show-off NAME + breed + 3D coat to the active kennel dog, but the
completion-menu «Raser» active-row **coat swatch** (and the showcase entry tint) still
hard-sets `"tint": bp.swatch_color()` — the stale breed-roster swatch (labrador → golden).
Training grey Border-collie Nova, the row reads «Nova» / «Border collie» but the little
round chip beside it is a **golden Labrador** disc — the last fragment of the "chip ≠ dog"
cohesion break the 173/174 arc closed.

## Fix (mirror 174's name re-point, for the swatch)
New pure `KennelDog.showoff_swatch(breed_swatch, is_active, active_from_kennel, active_kennel_id)`
returning `by_id(active_kennel_id).portrait_tint()` for the active kennel-driven entry, else
the passed breed swatch unchanged. `portrait_tint()` (not `coat_tint()`) — it yields Nova's
grey **and** the starter Bella's warm cream (coat_tint returns identity-white for Bella).
Repoint the `"tint":` in `main._render_showcase` + `main._breed_rows` through it. Non-active
rows keep `bp.swatch_color()` byte-identical.

## DoD
- TDD: failing tests first on `showoff_swatch` (active-kennel→grey Nova, active-starter→cream,
  non-active→breed swatch, kennel-not-driving→breed swatch).
- verify gate green.
- No economy / kennel-render / core-mark change. 172/173/174/087/163 intact.
