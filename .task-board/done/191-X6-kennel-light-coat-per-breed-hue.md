# 191 — Kennel light-coat per-breed hue (PO father-pass-65 X-6/X-4)

**Source:** `.docs/specs/po-review.md` — PO father-pass-65 directive (re-verified 190's
cross-surface cream fix, then filed ONE new buildable X-6/X-4).

## Directive

190 fixed Bella's cross-surface value (cream in kennel == cream on training), but its
single warm-cream light-branch applied **uniformly** flattened the per-breed hue of the
three light-coat dogs: Sol (Golden retriever), Trulte (Maltese) and Bella (Labrador) now
read as the same warm cream, differing only in brightness — and perversely the Golden
retriever reads *less golden* than the cream Labrador.

Fix = give each light-coat dog a **distinct hue target within the light branch**:
- **Sol** — clearly **golden-amber** (warmer + more saturated than Bella; must out-gold the lab).
- **Trulte** — **cooler near-white / silver** (Maltese).
- **Bella** — stays the **neutral cream reference she is now** (do NOT move Bella — her
  training-page match is correct and must be preserved).

Keep it in the **shared** `_band_dog_tint` / portrait pipeline so grid and modal move
together (187 parity). Do NOT re-darken the dark coats or undo 190's Bella cream.

## Approach (chosen)

Keep 190's cream anchor (`desat → cool-WB → gain`) **byte-identical** — that is Bella's
preserved result. Add a **per-breed light-coat hue bias**: a Color multiplier applied
ONLY inside the light branch, defaulting to `Color(1,1,1)` so Bella / dark / tan / the
passthrough are all untouched.

- `KennelDog.portrait_bias()` → `WHITE` for every dog except Sol (warm/golden) and Trulte
  (cool/white). Carried in the `classify_kennel_dogs` rows and `detail_for` detail dict.
- `KennelScreen._band_dog_tint(coat_hue, bias := Color(1,1,1))` multiplies the cream
  anchor by `bias` in the light branch only. Threaded from `row.portrait_bias` (grid) and
  `detail["portrait_bias"]` (modal) → grid + modal move together (187 parity).

Bella's bias is WHITE → her modulate is provably identical to 190. Sol's warm bias makes
his cream-anchor warm/golden (r−b clearly positive, out-golding Bella). Trulte's cool bias
makes her cream anchor cool near-white (b−r clearly positive), and she stays the brightest.

## TDD

- `tests/test_band_dog_tint.gd`: Bella unchanged (bias default white); Sol out-golds Bella
  (warm r−b, greater than Bella's); Trulte cooler than Bella (cool b−r); the three light
  dogs are tellable apart by HUE (distinct r−b), not just brightness; dark coats untouched.
- `tests/test_kennel_dog.gd` (if present) / band test: `portrait_bias()` per-dog values.

## Done when

verify gate green, placeholder grep clean, committed + pushed, po-review.md recorded.
