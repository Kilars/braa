# 082 — FEATURE: pain pays — higher difficulty scales the reward (dormant)

**Type:** FEATURE (game-logic TDD) · **Phase:** 4 — Difficulty · **Label:** `work-ahead` (PROVISIONAL —
Phase 3 is still the current, un-signed-off phase) · **Source:** `.docs/specs/phase4.md` **P4-3** ("Pain
pays — higher difficulty raises rewards, so each mode is the rational choice at a different skill level") ·
**Priority:** completes the core Phase-4 difficulty loop after **080** (setting) and **081** (the read).

## Why this is work-ahead (and how it stays dormant)

Same standing as 080/081: Phase 3 exhausted, blocked purely on owner assets + PO sign-off. **Dormancy:** the
reward is `× _difficulty.reward_scale`, and **Normal's reward_scale = 1.0**, so the default Normal run earns
exactly today's `COIN_REWARD_MASTERY` per mastery — the Phase-3 economy is unregressed and the play-test is
byte-identical. Only the dormant `?bra_difficulty=` seam (080) activates a higher payout. Independent of the
owner-gated block; preempted by any reopened current-phase work.

## What it addresses

P4-3: higher difficulty must **reward more**, so opting into a harder mode is worth it (each mode the
rational pick at a different skill level). Today mastery pays a flat `COIN_REWARD_MASTERY` regardless of
difficulty; this scales it by the active mode's `reward_scale` (already defined on the 080 `Difficulty`
bundle).

## Technical approach

Scale the mastery coin reward at the single earn site (`main.gd` `_apply_progress`, where a just-mastered
trick calls `_purse.earn(COIN_REWARD_MASTERY)`), using the 080 bundle. Home the scaling in a tiny resolved
accessor on `Difficulty` so the arithmetic lives with the model (same discipline as `BreedPersonality`'s
resolved levers), and round to a whole coin.

```gdscript
# scripts/difficulty.gd — resolved accessor (arithmetic lives on the model):
func mastery_reward(base: int) -> int:
    return int(round(base * reward_scale))   # Normal → base exactly; Hard/Expert → more

# main.gd _apply_progress — Before:
if progress.just_mastered():
    _purse.earn(COIN_REWARD_MASTERY)
    _refresh_coins()
# After (pain pays, P4-3):
if progress.just_mastered():
    _purse.earn(_difficulty.mastery_reward(COIN_REWARD_MASTERY))
    _refresh_coins()
```

### TDD (RED first)

- **`tests/test_difficulty.gd` (extend):** `normal().mastery_reward(10) == 10` exactly (dormancy identity);
  `hard().mastery_reward(10) > 10`; `expert().mastery_reward(10) > hard().mastery_reward(10)` (strictly
  monotonic — the higher-risk mode pays strictly more); reward is a whole integer (rounded).
- **Wiring test (extend the coin-purse / earn wiring test):** boot `main` with `?bra_difficulty=expert`,
  master a trick, assert the balance rose by `expert().mastery_reward(COIN_REWARD_MASTERY)` — not the flat
  base; and with default Normal it rose by exactly `COIN_REWARD_MASTERY` (regression guard).

## Acceptance criteria

- [ ] TDD (RED→GREEN): `Difficulty.mastery_reward(base)` returns `base` exactly on Normal and a strictly
      larger whole-coin amount on Hard, larger still on Expert.
- [ ] In the running game the mastery payout scales with the active difficulty (`?bra_difficulty=` seam);
      default Normal pays exactly today's `COIN_REWARD_MASTERY` (economy unregressed).
- [ ] **Dormancy proven:** default Normal run earns the same coins per mastery as HEAD (regression guard
      test); no default-HUD change.
- [ ] Placeholder check clean.
- [ ] `nix develop -c bash verify.sh` green (import·boot·test·export).

## Notes

Depends on **080** (`Difficulty` bundle + `_difficulty` on boot) and pairs with **081** (the read). This is
the third leg of the core difficulty loop: choose it (080) → it changes the read, stacked on the breed (081)
→ it pays more (082). P4-5 (background-resume grace) stays for a later work-ahead round — it is independent
and small. Nothing here depends on owner assets.
