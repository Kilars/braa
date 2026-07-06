# 137 — VISUAL — Mark word-pop «Bra!»: high-contrast treatment over bright grass

**Source:** PO Review 2026-07-06 (father pass 2), directive **#3 [LOW]** (training).
**Phase:** current-phase X-4 quality (preempts the Phase-10 owner-gate).

## What it addresses

`.screenshots/MARK-frame-08.png` (word over grass) vs `MARK-frame-13.png` (over the BRA button).
«PERFECT» renders in amber Baloo 2 with a legible outline (good); the floating «Bra!» word-pop is
amber and **reads legibly over the dark BRA button but washes out over the bright green grass**
along its float. (Note: `word_pop.gd` *does* set a near-black outline size 10 — but at 64px over
green it still reads soft; it needs the firmer, PERFECT-grade treatment.)

**Acceptance (PO):** give the «Bra!» word-pop the **same high-contrast treatment as «PERFECT»** —
amber `#F5B841` (or white) Baloo 2 with a **solid drop-shadow OR dark outline** — so it stays
crisply legible over *any* garden frame along its whole float.

## Technical approach

All in `scripts/word_pop.gd` `_init()`. Reference the working `TierReadout` (`scripts/tier_readout.gd`)
which reads well: outline_size **12** at font_size 88 (ratio ~0.136).

- **Strengthen the outline** to match PERFECT's ratio: WordPop is 64px, so bump `OUTLINE_SIZE`
  10 → ~12–14 (keep `OUTLINE_COLOR` near-black `Color(0.07,0.07,0.10,1)`), so the stroke is as firm
  relative to glyph size as PERFECT's.
- **Add a solid drop-shadow** on top of the outline (PERFECT sits over the lighter sky; «Bra!»
  crosses the bright grass, so belt-and-braces): set
  `add_theme_color_override("font_shadow_color", Color(0,0,0,0.55))`,
  `add_theme_constant_override("shadow_offset_x", 2)`,
  `add_theme_constant_override("shadow_offset_y", 3)`, and
  `add_theme_constant_override("shadow_outline_size", …)` if needed so the shadow reads as a solid
  drop, not a blur.
- Keep the amber fill `COLOR_WORD` (already agrees with PERFECT/mastery) and the whole float/fade
  mechanic **unchanged** — this is purely the legibility treatment. Do NOT change `HOLD`/`FADE`/
  `RISE_PX`/`pop`/`advance`/`rise_offset` (the WordPop tests assert those and must stay green).

Additive theme overrides only → pure render, **Visual Review**. The existing `word_pop` unit tests
must stay green (they assert alpha/rise, not theme constants).

## Definition of done
- `nix develop -c bash verify.sh` green (existing word_pop tests still pass).
- Visual Review at 390×844: capture a mark burst and confirm the «Bra!» word stays crisply legible
  over the **grass** frame (~MARK-frame-08 equivalent), matching «PERFECT»'s contrast — not just
  over the dark BRA button.
- Placeholder-grep clean on the diff.
