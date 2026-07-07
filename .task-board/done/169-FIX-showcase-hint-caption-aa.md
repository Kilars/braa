# 169 — FIX: breed-showcase hint caption fails WCAG AA over the bright-grass band

**Label:** X-6 (PO father-pass-34 directive)
**Source:** `.docs/specs/po-review.md` — PO Review 2026-07-07 (father pass 34)

## Directive (verbatim intent)

The breed-showcase instructional hint «Bla med pilene eller trykk en hund»
(`breed_showcase_view.gd` `_hint`, `SUBTLE` ink) fails WCAG AA (~4.1–4.3:1) over the
default bright-grass view: the stage band is translucent (`BAND_BG := INK @ 0.72`) so
bright grass bleeds through, lightening the composited band to ~(91,102,103), and the
caption ink `SUBTLE := Color(1,1,1,0.78)` is only 78%-opacity white — not opaque enough
to stay legible. The father measured the composited band under the hint at (91,102,103)
in-pixel at dsf3 and the glyph strokes at ~4.1–4.3:1.

Same translucent-bleed → sub-AA class as 145/156/158/159/162.

## Fix

- Raise `SUBTLE` toward opaque white so the caption clears ≥4.5:1 on the worst-case
  (bright-grass) composited band. Reuse the secondary-white level `BTN_SECONDARY_TEXT`
  already uses (`Color(1,1,1,0.92)` → ~5.3:1 on the measured band) so the hint keeps a
  hair of "secondary" vs a full-white title, per the PO's own suggestion.
- Keep the dark translucent stage band (do NOT make the band opaque — that kills the
  spotlight glow). Keep the 13px size + centered placement; change only the caption ink.
- Add a pure static `hint_ink_over(band)` composite helper so the alpha is testable, plus
  a TDD assert (in `test_breed_showcase_contrast.gd`) that the effective hint ink clears
  4.5:1 on the father's measured worst-case band `Color8(91,102,103)`.

## Done when

- New assert red under `SUBTLE@0.78`, green after the bump.
- `verify.sh` green; in-pixel re-check at dsf3 the caption reads crisply over grass.
