# 198 — FIX: unify the breed-showcase «Trener nå» status-pill tint to the kennel active wash

**Source:** PO father-pass-72 (`.docs/specs/po-review.md`), one buildable X-6 directive.
Board was empty; this task was surfaced by the `po-review.md` diff (PO review can surface
buildable work on a byte-identical tree).

## Directive (X-6, DS consistency)

The non-tappable «Trener nå» active-training-dog **status pill** rendered two different tints
across surfaces:
- breed showcase — `commit_disabled_fill() = Color("eef1f5")` (cool pale slate, rgb 238,241,245, blue-biased), set by task 197.
- kennel modal — `active_state_fill() = C_MODAL_SURFACE.lerp(C_STATUS_OWNED, 0.14)` ≈ `#e4f2e1` (green-mint, green-biased).

197's commit claimed to match the kennel «Trener nå» precedent, but the colours didn't actually
match — the same component carrying the same word read cool-slate in one surface and green-mint in
the other, weakening the ownership-green (`C_STATUS_OWNED #57b85c`) colour language. The lone
cross-surface component inconsistency left after the AA sweep.

## Fix

`scripts/breed_showcase_view.gd` — `commit_disabled_fill()` now **delegates to
`KennelScreen.active_state_fill()`** (rather than hardcoding an "equivalent" `#e4f2e1`). Sourcing
the fill from the kennel's own active wash ties the showcase pill to the ownership-green language
**and guarantees the two can never drift again** (the actual point of the DS-unify directive).

`active_state_fill()` computes exactly `#e4f2e1` (verified: `fbfbf7`.lerp(`57b85c`, 0.14) →
rgb 228,242,225). Its luminance ~0.854 (≥ 0.82) and dark-`INK`-on-fill ~13:1 analytic (≥ 7:1), so
the existing AA render-headroom test still holds and the dark-ink label keeps clearing AA in-pixel
— the identical dark-on-near-white situation the kennel «Trener nå» (151) already renders AA-clear
(pass-71/72 measured 5.24:1 on the near-white fill; the opaque fill blocks the spotlit-band bleed).

Label word «Trener nå», pill shape, and the 197 AA win are all intact — this only aligns the tint.

## TDD

`tests/test_breed_showcase_contrast.gd` — new `test_active_status_fill_matches_kennel_active_wash`
pins `BreedShowcaseView.commit_disabled_fill() == KennelScreen.active_state_fill()` (one colour, one
source). The prior `test_disabled_fill_is_a_near_white_pale_slate_with_render_headroom` (fill lum ≥
0.82, INK ≥ 7:1) still passes on the green-mint fill, so the render-robust AA guard is preserved.

## Verify

`nix develop -c bash verify.sh` → green (import · boot · test · export). Test runner: **869 tests,
0 failures** (was 868 at task 197; +1 new). Placeholder grep of the scripts diff: clean.

## Not done here (intentional / owner-gated — per pass-72 "Considered but NOT filed")

- The four warm-brown breeds reading similar — distinct per-breed **models** (BUST-068, standing owner flag).
- The active-state badge *word* differing across sections (trick «Trener nå» / breed·word «Aktiv» /
  difficulty «Valgt») — each reads correctly in context (pass-68 kept «Valgt»); this task is the
  *colour* unify only.
