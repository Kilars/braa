# 201 — X-6 (Bugfix / AA): LearnedBar «Sitt» / «%» readout clears AA in the SHIPPED render

**Source:** PO father-pass-78 X-6 (`.docs/specs/po-review.md`). With task 200's nav pills now
crisp-dark (17:1), the eye goes straight to the LearnedBar «Sitt» readout directly below, which
renders a faint pale-grey — the weakest primary text on the whole page. Sampled darkest
stroke-core vs the bar fill `[251,251,247]` (= PAPER): **`[119,127,135]` → 3.92:1**, under the
4.5:1 AA floor. Same thin-stroke render-wash task 200 fixed on the nav pills, never applied here.

## Root cause (same as 200, measured)

The «Sitt» label = `DesignSystem.INK` #1e2a3a drawn via `draw_string` at `T_HEAD` (18px) Baloo 2
bold. At 18px the thin bold strokes reach only ~`NAV_STROKE_COVERAGE` (0.60) sub-pixel coverage,
so the darkest core is a 0.60/0.40 blend of INK over the PAPER panel:
`render_floor_contrast(INK, PAPER, 0.60)` = `[118,126,134]` ≈ 3.92:1 — exactly the PO's measured
[119,127,135]. INK is analytically ~12:1 on PAPER, but the 0.60-coverage wash caps it under AA.
A deeper ink ALONE tops out ~4.0:1 at that coverage (task 200 proved this) — the stroke-thickening
**outline** is the decisive lever. The «%» readout uses `BLUE_INK` #2a66b3 (analytic ~4.84 on
PAPER) which washes even lighter, so it shares the defect.

## Fix — stroke-thickening outline (the proven 200 lever), keep the tokens

The LearnedBar labels are drawn with `draw_string` on the canvas (not Button theme overrides like
the nav pills), so the outline lever is `draw_string_outline` — a same-ink outline drawn under each
label, raising effective stroke coverage to ~full WITHOUT changing text advance/geometry:

- New `LearnedBar.LABEL_OUTLINE = 4` (matches nav's `HUD_NAV_LABEL_OUTLINE`). `_draw()` calls
  `draw_string_outline(..., LABEL_OUTLINE, <same colour>)` before each `draw_string` for BOTH the
  «Sitt» name (INK) and the «%» readout (BLUE_INK).
- With coverage restored to ~full, both labels render their true tokens: INK ≈ 12:1 (as solid as
  the nav pills' 17:1), BLUE_INK ≈ 4.84:1 (clears AA, keeps the 180 goal-art blue «%»).
- **Kept unchanged:** the INK / BLUE_INK token intent, the 145/159/179 opaque cream track + scrim
  panel + drop shadow, the «%» blue (180), the bar geometry. An ink/render fix, not layout.

## Guards (mirror 200's render-floor pins)

`test_learned_bar_readout_contrast.gd`:
- `render_floor_contrast(INK, PAPER, 0.60) < 4.5` — regression pin: WITHOUT the outline the «Sitt»
  label washes (3.92:1), proving the outline is necessary (mirrors nav's BLUE_INK-fails pin).
- `LABEL_OUTLINE > 0` — the decisive stroke-thickening lever is wired.
- `wcag_contrast(INK, PAPER) ≥ 4.5` AND `wcag_contrast(BLUE_INK, PAPER) ≥ 4.5` — at the
  outline-restored ~full coverage both readout labels clear AA.
- LABEL_COLOR is INK and PCT_COLOR stays BLUE_INK (tokens/intent unchanged).

## Verify

- `nix develop -c bash verify.sh` green (import·boot·test·export).
- Placeholder grep clean on the diff.
