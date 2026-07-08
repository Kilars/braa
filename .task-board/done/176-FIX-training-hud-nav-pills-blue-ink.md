# 176 — FIX: training-page «Triks»/«Kennel» HUD nav pills + hamburger glyph → AA-safe BLUE_INK

**Source:** PO Review father-pass-41 (`.docs/specs/po-review.md`, 2026-07-08), X-6 directive.
**Label:** X-6 (polish / AA-legibility).

## What the PO saw
On the training page the two primary top-left HUD nav pills — **«Triks»** and **«Kennel»**
(plus the «Triks» hamburger glyph) — render in muted `DesignSystem.SLATE` grey and read
faint/washed against the bright sky: effective on-screen contrast only **~3.7:1 («Triks»)** /
**~2.9:1 («Kennel»)** at the small bold `T_HEAD` size (thin strokes anti-alias toward the pale
PAPER pill). The **goal art** (`.docs/specs/assets/goal-training-screen.png`) shows a crisp,
**saturated BLUE** label + matching blue glyph. The 149→156 AA sweep measured kennel badges,
menu blue-on-light text, the BRA CTA and kennel secondary text but **never these HUD nav pills**,
so they slipped.

## Fix (colour-token re-point only — no layout/economy/asset change)
Repoint the «Triks» + «Kennel» pill `font_color` / `font_pressed_color` / `font_hover_color`
**and** the hamburger glyph bars from `DesignSystem.SLATE` to the AA-safe `DesignSystem.BLUE_INK`
token (`#2a66b3`, ~5.5:1 on PAPER — BLUE/BLUE_DARK both fail <4.5 on light; BLUE_INK exists for
exactly this, added in 154). Keep the near-opaque PAPER pill + deepened `HUD_PILL_SHADOW` (100)
and the pill geometry exactly as they are.

Locations: `main.gd` «Triks» font colours (~1964–1966), «Kennel» font colours (~2166–2168),
`_hamburger_texture()` baked bars (~2014).

## Approach
- Introduce `const HUD_NAV_INK := DesignSystem.BLUE_INK` in `main.gd` and use it for both pills'
  three font-colour states + the hamburger bars — one named source so the two labels and the
  glyph can never drift apart again.
- TDD (headless-safe, preload constants — no scene boot): assert `HUD_NAV_INK == BLUE_INK`, that
  it clears AA on PAPER (`wcag_contrast >= 4.5`), and that it is **not** the old faint `SLATE`.
- Visual Review of the training page confirms the pills read as crisp blue matching the goal.

## Guardrails (per memory — do NOT revert)
Keep BLUE_INK the blue-on-light ink token; keep the PAPER pill + HUD_PILL_SHADOW (100); no
geometry/economy/asset change; 100/149→156 intact.
