# 147 — X-6: keep cool coats cool across grid ↔ modal (hue-preserving lighten)

**Source:** PO Review 2026-07-07 (father pass 11), Improvement 2 — Nova's coat reads cool
grey in the grid but warm cream in her inspect modal; warm dogs (Balder/Sol) carry through fine.

## Root cause (verified in code, refines the father's hypothesis)

The father hypothesised the modal "isn't applying the same `portrait_tint` the grid cell uses."
It **is** — grid `kennel_screen.gd:582` and modal `:1094` both call
`_band_dog_tint(portrait_tint)` with the identical `d.portrait_tint()`. The real bug is inside
`_band_dog_tint`:

```
if coat_hue.get_luminance() < DARK_BAND_LUM:   # 0.42
    return coat_hue.lerp(Color.WHITE, 0.7)     # ← lerp toward PURE WHITE desaturates
```

Only **dark** coats hit this branch — Nova `Color(0.298,0.322,0.357)` lum≈0.32 and Pontus
lum≈0.37 — and lerping 70% toward pure white collapses their hue to near-neutral (final b−r bias
≈0.02). Warm dogs (Balder lum≈0.52, Sol high) skip the branch and keep full chroma. Because the
lightened tint is nearly hue-less, whether it *reads* cool or warm is then decided by framing/
lighting: the small shadowed grid cell reads it grey, the big brightly-lit modal hero bust reads
it cream. Same modulate, opposite perception → the "breed flip".

## Fix

Lighten dark coats while **preserving hue/chroma** — brighten toward a readable target luminance
by scaling the RGB channels (keeps r:g:b ratios) instead of lerping toward white. Nova then stays
visibly cool and Pontus visibly warm in **both** views, so framing can no longer flip the read.
Single-function change → both surfaces fixed by construction (they already share the function).

## Definition of done (TDD — pure, render-free)
- Red→green in a new `test_band_dog_tint.gd`:
  - a dark COOL coat (Nova) keeps cool channel ordering (b > r by a clear margin) after tinting,
    i.e. it is NOT collapsed to near-neutral;
  - a dark WARM coat (Pontus) stays warm (r > b);
  - both dark coats are lightened to a readable luminance (≥ DARK_BAND_LUM);
  - a light coat (Trulte) is returned unchanged.
- `_band_dog_tint` made a pure `static` helper if needed for the test seam.
- `nix develop -c bash verify.sh` green; capture Nova's grid cell + modal side-by-side to confirm
  the coat now matches (cool in both).
