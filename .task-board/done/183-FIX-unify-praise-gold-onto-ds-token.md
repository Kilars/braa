# 183 — FIX: unify the reward-beat praise gold onto the DS GOLD token (PO father-pass-56, X-6)

**Source:** `.docs/specs/po-review.md` — PO Review 2026-07-08 (father pass 56), New Change (X-6).

## Directive
The reward-beat praise gold is an off-token literal. Both `TierReadout.COLOR_PERFECT`
(`tier_readout.gd:29`) and `WordPop.COLOR_WORD` (`word_pop.gd:15`) use a raw literal
`Color(1.0, 0.86, 0.30)` = (255, 219, 77) — a brighter, more lemon gold. But the coin
readout (`coin_readout.gd:69`) and the mastery-bar latch (`learned_bar.gd:155`) both use
`DesignSystem.GOLD` = `f5b841` = (245, 184, 65) — a deeper amber. So two different golds
land in the same frame at the payoff (PERFECT + word-pop vs coin pill + mastery bar),
fracturing the game's single reserved GOLD accent at the most-watched moment, and leaving
two hard-coded colour literals outside the DS.

## What "good" looks like
Repoint BOTH praise-gold usages onto `DesignSystem.GOLD` so every gold in the game —
coin, mastery bar, PERFECT verdict, fired-word pop — is one hue. Keep the near-black
outline + drop shadow (they carry legibility, not the hue). Colour-token unification
only — no behaviour or motion change. OK/MISS tiers stay distinct green/grey.

Chose `DesignSystem.GOLD` (not `GOLD_LIGHT`) because the PO's stated goal is that every
gold be **one hue** — GOLD_LIGHT would keep the praise gold at a different hue from the
coin/mastery GOLD, still two hues.

## Invariant to preserve
`COLOR_PERFECT.v >= COLOR_OK.v` (PERFECT at least as bright as OK). GOLD.v = 0.96,
OK.v = 0.85 → holds.

## Done
- TDD: assert both consts == `DesignSystem.GOLD` and equal each other; PERFECT≥OK kept.
- verify gate green.
