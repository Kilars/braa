# 089 — FIX: showcase ◀ ▶ cycle controls + hint line render as tofu boxes

**Type:** FIX (visual) · **Phase:** 3 (current) · **Source:** PO Review 2026-07-03 (HEAD `455f554`), Bugfix 1.

## What the PO saw
On the "Mine hunder" showcase (087) the bottom-left/right cycle **buttons** and the hint line
**"Bla med ◀ ▶ eller trykk en hund"** draw the arrow glyphs as broken missing-glyph boxes
(`po-crop-showcase-bottom.png`). `◀`/`▶` (U+25C0/U+25B6) aren't in the project font — the exact
tofu-box class as the old coin emoji, which 069 fixed by **drawing** the coin. On the one screen whose
whole job is to make the roster "feel like collected units I'm proud of", broken boxes cheapen it
(X-4 "looks the part").

## Definition of done (PO "Good")
The prev/next affordance renders as a clean, legible control on the deployed GL build — a **drawn**
triangle/chevron (like the drawn `CoinReadout`), and the hint line reworded so **no tofu box appears
anywhere**, the hint line included.

## Plan
- `scripts/breed_showcase_view.gd`: replace the `"◀"`/`"▶"` Button glyph text with a **drawn** chevron
  (a small mouse-ignoring child Control that fills the button and draws a filled triangle via
  `draw_colored_polygon`) — keeps the buttons real + tappable (the capture reads their centres).
- Reword the hint to `"Bla med pilene eller trykk en hund"` (no U+25C0/U+25B6).
- Regression test (`tests/test_breed_showcase_view.gd`): the built view carries **no** U+25C0/U+25B6 in
  any Label/Button text (hint reworded, glyph buttons carry no glyph text — the chevron is drawn).
- Visual Review: re-run `tools/web_capture_showcase.mjs` on the exported bundle → the cycle controls +
  hint render clean, no tofu, on the real GL/SwiftShader build (`087-01`, `087-02`).

## Placeholder check
Chevron is the real affordance (drawn, like the 069 coin), not a stub. No allowlist needed.
