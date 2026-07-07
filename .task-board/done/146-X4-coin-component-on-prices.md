# 146 — X-4: draw prices with the SAME coin component as the readout

**Source:** PO Review 2026-07-07 (father pass 11), Improvement 1 — cross-cutting DS-consistency
gap (X-4 "same component rendered differently across screens" + "gold reserved to the coin").

## The defect (father, measured)

The coin **readout** (training HUD pill + kennel header) is the canonical coin component: a
white PAPER pill + a DRAWN gold coin disc + the count (`CoinReadout`). But every **price** is a
**bare number with no coin**:
- grid price tags are just «900» / «50» / «350» on a solid-**gold** pill (`_make_price_chip`,
  `C_PRICE_GOLD == DesignSystem.GOLD`), and
- the modal adopt/afford action reads «Har ikke råd · mangler 900» / «Adopter  N mynt`
  (`adopt_button_label`) — a bare number.

So the same quantity (coins) is drawn one way in the readout and another at the point of
purchase; «900» carries no unit; and a full-gold pill spends the DS's coin-gold on a plain
number (DS reserves gold to *the coin*).

## What "good" looks like (father)

Draw price using the **same coin component** as the readout — prefix every price with the gold
coin glyph so it reads «🪙 900», visually consistent across HUD / kennel header / grid tag /
modal action. No owner asset (reuses the coin disc already drawn in the readout).

## Plan (TDD where pure, Visual Review for the render glue)

1. New `_CoinPip` inner class in `kennel_screen.gd` — draws the readout's gold coin disc
   (GOLD_DARK rim + GOLD face + GOLD_DARK inner arc), the drawn-not-font route (no tofu, GL-Compat),
   mirroring `_HeartPip`/`_StarPip`/`CoinReadout`.
2. **Grid price chip** (`_make_price_chip`): a **buyable** dog (numeric price) becomes the readout
   component — a **PAPER pill + coin pip + INK number** (gold now on the coin, not the whole pill).
   Owned «Din» (green) and secret «Gratis» (coral) stay word-only status pills — they are NOT
   prices, so no coin.
3. **Modal adopt button** (`_build_adopt_button`): render `[prefix][coin pip][amount]` via the
   proven free-adopt overlay pattern (empty `btn.text` + non-interactive CenterContainer content),
   so the price shows the coin. Affordable → «Adopter» + coin + N (drop the now-redundant "mynt");
   unaffordable → «Har ikke råd · mangler» + coin + N.
4. Pure helpers, test-first:
   - `price_shows_coin(row)` → true only for a buyable numeric price (false for owned/secret).
   - `adopt_button_parts(price, balance, affordable)` → `{prefix, amount}` (amount == -1 → no coin,
     the free case). Replaces `adopt_button_label`; rewrite `test_kennel_modal_cta.gd` to pin parts.

## Definition of done
- Red→green TDD for the two pure helpers; render glue verified by a phone-portrait capture of the
  kennel grid + an unaffordable modal showing the coin pip on the price.
- `nix develop -c bash verify.sh` green (import·boot·test·export).
- Placeholder grep clean.
