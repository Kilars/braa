# 200 — X-6 (Bugfix / AA): nav-pill «Triks»/«Kennel» labels clear AA in the SHIPPED render

**Source:** PO father-pass-77 X-6 (`.docs/specs/po-review.md`). The training-page top-left
HUD nav-pill labels «Triks» + «Kennel» render a washed-out light-periwinkle at ~2.4:1 on the
PAPER pill, failing WCAG AA — despite the analytic 5.55:1 of their `BLUE_INK` token. Same
analytic-vs-render trap the 145/196/197 arc fixed by measuring shipped pixels, NOT the "safe
artifact" a build-loop self-audit dismissed it as.

## Root cause (measured, not asserted)

Both the nav labels AND the «Sitt» learned-bar label use the SAME font (`font_body_bold` =
Baloo 2 bold) at the SAME size (`T_HEAD` = 18). The only difference is the ink:
- «Sitt» = `DesignSystem.INK` #1e2a3a (dark) → renders darkest-core `[117,125,133]` ≈ 4.03:1
- nav   = `DesignSystem.BLUE_INK` #2a66b3 (lighter) → renders `[126,166,215]` ≈ **2.43:1**

Recalibrated capture (`tools/po_pass77.mjs`, clean «Kennel» text region) reproduces the PO's
number exactly: `[126,166,215]` = 2.43:1. Back-solving `cov·ink + (1-cov)·PAPER = seen` gives
sub-pixel **stroke coverage ≈ 0.60** — at 18px the thin bold strokes never reach full coverage,
so the darkest core is a 60/40 blend of ink over paper. BLUE_INK is intrinsically too light to
survive that wash; the darker INK barely clears. The hamburger glyph is fine (baked
full-coverage bars, not thin strokes) — confirming the defect is thin-stroke under-coverage.

Task 176 already swapped these labels SLATE→BLUE_INK trusting BLUE_INK's darker *analytic*
5.55:1 — but it renders even lighter than the SLATE «Sitt» control. Recolouring did not defeat
the wash; the fix must go DARKER than INK so the 0.60-coverage blend still clears AA.

## Fix — TWO levers (deeper ink + thicker strokes), verified in-pixel

In-pixel measurement (recalibrated `tools/po_pass77.mjs`, glyph-isolating sampler on a high-res
clip) proved a subtlety: at ~0.55 real stroke coverage the darkest core caps at ~4.68:1 **even for
pure black** — so a deeper ink ALONE tops out ≈4.0:1 (NAV_INK #0a1628 measured [118,125,134]@4.01,
matching «Sitt»'s 3.92 but under the 4.5 bar). The PO's second lever was required.

- **Deeper ink:** new DS token `NAV_INK = #0a1628` (deep blue-slate, blue-dominant), pointing
  `HUD_NAV_INK` (main.gd) — darkens «Triks»/«Kennel» labels + the hamburger bars, one source.
- **Stroke-thickening outline (decisive):** `HUD_NAV_LABEL_OUTLINE = 4`, a same-ink
  `font_outline_color` + `outline_size` on both nav buttons. Outlining raises effective stroke
  coverage to ~full WITHOUT changing text advance (so «Kennel» stays un-truncated / geometry
  unchanged). Result: the glyph cores now render the TRUE NAV_INK [10,22,40] → **17.4:1 / 17.3:1**
  in-pixel (pass-77 harness), far clearing AA and the strongest primary text on the HUD.
- **Guards** (mirrors 196/197's MEASURED_* render-headroom guards, inverted for dark-on-light):
  new `DesignSystem.render_floor_contrast(ink, fill, coverage)` + `NAV_STROKE_COVERAGE = 0.60`.
  Tests pin NAV_INK clears the render-floor model AND that BLUE_INK would FAIL it (so an
  analytic-only value can't re-mask this), plus a pin that the stroke-thickening outline is wired.

**Gotcha logged:** verify.sh's export reuses `.godot/exported`, which held a stale pre-edit
compiled bundle — the local "change won't render" ghost. `rm -rf .godot/exported` before an export
when validating a colour/pixel change locally. CI is unaffected (fresh checkout = empty cache).

## Kept (not touched)

PAPER pill + deepened HUD shadow (100/125), full un-truncated «Kennel» (185), pill geometry,
the hamburger glyph. Ink/render fix only — no layout change. `test_hud_nav_ink.gd` updated:
HUD_NAV_INK == NAV_INK, still blue-dominant, still not the old SLATE.

## Verify

- `nix develop -c bash verify.sh` green (import·boot·test·export).
- In-pixel re-capture (`tools/po_pass77.mjs`): «Kennel»/«Triks» darkest-core ≥4.5:1.
