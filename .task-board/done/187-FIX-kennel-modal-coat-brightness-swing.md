# 187 — FIX: kennel modal hero coat matches grid-cell coat (PO father-pass-61 X-6)

**Source:** PO father-pass-61 (`.docs/specs/po-review.md`, HEAD `a4d5802`). ONE buildable X-6 directive.

## What the PO saw
Tapping **Nova** (border collie) in the kennel grid opens her inspect modal, and the
hero bust reads a **distinctly lighter, warmer grey** than the near-black charcoal she is
in the grid thumbnail. Measured on the same running frame:
- grid-cell flank ≈ **(45,48,52)** — dark charcoal, cool (b>r)
- modal-hero flank ≈ **(91,88,84)** — mid dove-grey, warm (r>b)

≈2× luminance + a cool→warm hue flip for the identical dog. Most glaring on Nova (darkest
cool coat); lighter coats swing less but the same brightening applies.

## Root cause (PO-traced, confirmed)
Grid + modal share `_build_one_portrait` (same NEUTRAL_COAT, same `_band_dog_tint`, same
light rig). The **only** difference is yaw: grid uses the variety `PORTRAIT_YAW_SPREAD[i]`,
modal uses dead-front `MODAL_PORTRAIT_YAW = 0.0`. At the modal's front-on angle Nova's flank
faces straight into the −34°/−38° **key** light (energy 1.2) and blows brighter; the grid's
side-yaw keeps that flank in shadow, where the **cool** ambient (0.72,0.74,0.78) tints it.
So coat value **and** hue swing with pose angle instead of holding constant.

## Fix
In the shared `_build_one_portrait` light rig, reduce the yaw-variant term and neutralize
the hue cast — so apparent coat midtone + hue hold roughly constant across yaw:
- **Soften the key-to-fill ratio** (key 1.2→ lower, fill 0.35→ higher) so the front-lit
  flank no longer washes at the modal's front-on angle — the yaw-invariant flat illumination
  (fill + ambient) dominates the yaw-variant key.
- **Neutralize the ambient** (cool 0.72,0.74,0.78 → hue-neutral grey) so shadowed vs lit
  areas no longer flip cool→warm; lift ambient energy to hold overall brightness.
- Extract the rig params into named consts so the invariant is testable + documented.

Keep the modal's fixed front-¾ `MODAL_PORTRAIT_YAW` hero framing (140) — only the
brightness/hue swing is fixed, not the angle. Applied in the shared function so all 8 dogs
stay consistent across both views. Nova stays a dark charcoal border collie in both.

## Tests (TDD, pure const invariants)
`tests/test_kennel_portrait_light_rig.gd`:
- ambient color is hue-neutral (r==g==b) → no cool→warm flip across yaw
- key-to-fill ratio softened (≤ 2.0; was 3.43) → front-on flank no longer blows out
- key energy reduced below the old 1.2 → modal exposure comes down toward the dark grid read

## Visual Review (blocking)
Capture Nova grid cell + modal on the same running frame; measure flank RGB. Grid and modal
flank must read the same coat value + hue (both dark charcoal, cool) — |Δluma| small, no
hue flip. All 8 dogs stay consistent; the front-¾ modal framing unchanged.

## Done
- verify gate green (import/boot/test/export)
- Visual Review PASS (grid↔modal coat convergence)
- committed + pushed
