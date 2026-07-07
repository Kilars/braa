# 159 — X-4: training HUD learned-progress bar backing panel is fully opaque

**Source:** PO father-pass-23 (`.docs/specs/po-review.md`, HEAD `0659850`). The training-page
HUD **learned-progress bar** («Sitt … 0%») is a *translucent* backing panel — the sun and sky
bleed straight through it — while the nav (Triks/Kennel) + coin pills on the same HUD are crisp
opaque white. It reads as a see-through tinted film next to solid chips, and it leaves a residual
warm sun-glow through the bar's middle exactly where task 145 set out to kill that bleed.

Measured (PO, near-native deviceScaleFactor-3 crops): the panel read `(173,192,212)`/`(202,222,243)`
over blue sky but warm `(251,238,195)`/`(253,243,210)` over the sun — proof it is translucent, not
opaque. The nav pill reads `(251,251,247)` neutral white everywhere. Goal art
(`goal-training-screen.png`) confirms the intended read: a solid pale track, no see-through film.

Root cause: `learned_bar.gd` `SCRIM_COLOR` was `PAPER @ alpha 0.55` (task 145 made the panel light
but left it translucent — 145 only scrimmed the text layer, never raised the whole panel to opaque).

## Fix (alpha/colour on the learned-bar's own backing panel — no owner asset)

- `SCRIM_COLOR` `PAPER @ 0.55` → **`DesignSystem.PAPER`** (fully opaque) — the exact surface the
  nav/coin pills use, so the whole HUD reads as one set of solid floating chips and nothing behind
  the bar (sky or sun) shows through.
- Draw the panel via `DesignSystem.panel()` (was a flat shadowless `pill()`) with the deepened HUD
  pill shadow `PANEL_SHADOW = INK @ 0.20` (matches CoinReadout's 100 shadow), lifting the opaque
  chip off the scene.
- **Extends** task 145's opacity work from the text scrim to the whole panel; does NOT revert 145 —
  dark `INK` «Sitt»/«%» labels, the opaque inner progress track, and the backing behind the text
  are all kept.

## TDD (red → green)

New asserts in `tests/test_learned_bar.gd`:
- `test_backing_panel_is_fully_opaque_like_the_nav_and_coin_pills` — `SCRIM_COLOR.a == 1.0`.
- `test_backing_panel_is_the_same_paper_surface_as_the_pills` — `SCRIM_COLOR == DesignSystem.PAPER`.

Both RED before (alpha 0.55), GREEN after. 745 tests, 0 failures; verify gate green.

## Verified in-pixel

`tools/po_pass24_hud.mjs` captures the training HUD at deviceScaleFactor 3. Sampling the panel
across its full width (`.screenshots/159-training.png`) reads a uniform **`(251,251,247)` = PAPER**
at every x — including the mid-section over the sun — where the old translucent panel bled warm
`(251,238,195)`. Crop `/tmp/159_hud_top.png`: the «Sitt … 0%» panel is a crisp opaque white chip,
the sun glows behind/below it but never through it, and it reads as one system with the nav/coin
pills. Zero console errors.
