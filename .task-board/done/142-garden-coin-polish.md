# 142 — Training-page garden coins: shrink, space, ground, two-tone (X-4 polish)

**Source:** PO father-pass-7 (`.docs/specs/po-review.md`, 2026-07-07) — the sole buildable
directive. X-4 cross-cutting polish on the signed Phase-6 training surface (the polish lens
explicitly permits these on signed surfaces). No owner asset needed.

## What the PO measured (evidence: `.screenshots/PO7b-03-training-c.png`, 390×844)
- Right garden coin = **70×69 px** (~18 % of screen width) — ~4.5× too big.
- Left cluster = **63×51 px** disc with a **second coin overlapping directly below it**.
- All coins the **same flat gold**, floating at the dog's chest height.

## Goal art (`assets/goal-training-screen.png`)
- Garden coins are **small** (~14 px, ~4 % width), clearly **spaced**, sitting **low/grounded**
  near a bush, in **two tones** (a gold coin *and* a red/pink coin).

## Fix (PO guidance)
1. Shrink garden coins to ~**20–26 px** (from 70×69 / 63×51). Current `GARDEN_COIN_R=0.12`
   (0.24 m disc) measured 70 px → ~292 px/m at coin depth → target 23 px ⇒ diameter ~0.08 m ⇒
   **`GARDEN_COIN_R` → ~0.04**.
2. **Space** the scatter so no two coins overlap (the two left coins currently sit ~0.05 m apart
   in x / 0.40 m in z → collide at 70 px). Re-spread into a loose 4-coin scatter.
3. Seat them **lower / nearer the grass** — smaller R lowers the billboard centre too.
4. **Two-tone** — add at least one red/pink accent coin alongside the gold (goal art variety).
   New DS tokens `ROSE` / `ROSE_DARK` (decorative accent, distinct from the `DANGER` miss token).
5. Keep them in-world (grounded, subtle) and distinct from the gold coin-count HUD pill.

## Constraints (from prior garden lessons — memory + test comments)
- Camera sits ~1.2 m behind the dog → narrow portrait FOV shows only |x| < ~0.5 m at dog depth.
  Keep every coin |dx| ≤ ~0.5 m or it goes off-screen (the 101 zero-gold cause).
- `billboard_keep_scale = true` stays (GL-Compat billboard collapses edge-on without it);
  smallness comes from the radius, not keep_scale.
- Verify sizing with an ANALYTIC 390×844 projection, not headless `unproject`.

## Definition of done
- TDD: garden-wiring tests updated to pin small radius (~≤0.06), no-overlap spacing, ≥1 rose
  accent coin, on-screen |dx|. Red→green.
- verify.sh green (import·boot·test·export).
- Visual Review: re-capture training frame, coins read as a small, spaced, grounded, two-tone
  scatter framing (not crowding) the dog.
- Placeholder grep clean.

## Done (2026-07-07)
- `GARDEN_COIN_R` 0.12 → 0.04 (0.24 m → 0.08 m disc ≈ 23 px, in the goal's 20–26 px band).
- Scatter re-spaced to 4 coins, two per flank at staggered z (>=0.35 m apart) → no overlap.
- Two-tone: new DS `ROSE`/`ROSE_DARK` tokens + parametrized `_coin_texture(face, rim)` +
  shared `_coin_material()`; one right-flank coin is the rose accent, rest gold.
- TDD: rewrote `test_the_coins_read_as_gold_discs_grounded_in_the_foreground` (small-radius band
  [0.06,0.12] m, |dx| [0.32,0.5]) + added `test_the_coins_are_a_loose_non_overlapping_scatter`
  and `test_at_least_one_coin_is_a_rose_accent_two_tone`. Red → green.
- verify.sh GREEN (import·boot·test·export). Visual Review PASS (`.screenshots/099-scored.png`):
  small, spaced, two-tone (gold + rose) scatter framing the dog, no orbs, no overlap.
- Placeholder grep on scripts/ diff: CLEAN.
