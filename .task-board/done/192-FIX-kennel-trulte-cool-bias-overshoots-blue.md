# 192 — FIX: kennel Trulte cool bias overshoots into icy blue (PO father-pass-66 X-6/X-4)

## Source
`.docs/specs/po-review.md` — PO father-pass-66 (2026-07-08, HEAD `4ffbfb5`/191).
Re-verified 191's per-breed light-coat hue fix resolved (Sol golden, Bella cream, Trulte
coolest) and pruned it. Filed ONE new buildable X-6/X-4 directive.

## Directive
191's cool bias for Trulte overshot past neutral-white into an unnatural **icy blue** — the
Malchi renders a distinctly blue coat, not the warm ivory/silver-white a Maltese has.
- PO in-pixel grid sample: Trulte ≈ `rgb(191,202,215)` — **blue dominant** (B−R = +24,
  B−G = +13), i.e. B > G > R; the shaded torso reads icy blue-grey.
- Root: `KennelDog.PORTRAIT_BIAS["trulte"] = Color(0.84, 0.98, 1.24)` — a heavy blue boost +
  red cut that, stacked on the already-cool `LIGHT_COAT_WB (0.945, 1.0, 1.065)` and
  `LIGHT_COAT_GAIN 2.34`, swings the coat well past neutral into blue.

## What "good" looks like
Ease the blue bias so Trulte lands at a clean **neutral-to-barely-cool white** (roughly
R≈G≈B, or B only marginally above R — no channel dominating by ~24), **still clearly the
coolest and whitest** of the three light dogs (distinct from Bella's warm cream and Sol's
gold), reading as a natural white/silver coat, not blue.
- Same `portrait_bias` / shared `_band_dog_tint` knob so grid and modal move together (187).
- Do NOT re-warm Trulte into cream (that undoes 191). Do NOT touch Bella, Sol, or dark coats.

## Plan (TDD)
1. RED: add a guard in `tests/test_kennel_dog.gd` that Trulte's cool bias is **gentle**
   (bounded b−r spread), not the icy 0.40 that produced blue. Keep the existing `b.b > b.r`
   (still coolest) + the `_band_dog_tint` warm→cool ladder (Sol > Bella > Trulte).
2. GREEN: ease `PORTRAIT_BIAS["trulte"]` toward neutral (reduce blue boost + red cut).
3. Verify in real 390×844 pixels (capture tool) that rendered Trulte B−R is small (well
   under the ~24 that flagged blue) and Trulte is still the whitest/coolest of the three.

## Done when
verify gate green; rendered Trulte reads a natural neutral/silver-white; grid↔modal parity;
Sol/Bella/dark coats byte-identical.
