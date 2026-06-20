# BALANCE: Per-trick reward uplift so hard tricks aren't strictly dominated

**Status**: ✅ Done (2026-06-18)
**Created**: 2026-06-17

> **Outcome:** TDD red→green (12 new tests). Pure `trickRewardMultiplier(trick)` =
> `min(2.2, 1 + (1-learnMult) + (1-windowMult)×0.5)` in `tricks.ts` (sitt 1.0×,
> ligg 1.35×, legg-deg 1.7×, synthetic worst-case clamped to `REWARD_UPLIFT_CAP`
> 2.2×). `completeMastery`/`completePractice` gained an optional last `trick?`
> param folding the uplift into the multiplier in documented order (`trickMult ×
> modeMult × kennelMult × prestige`); omitted = 1× (backward-compat, existing
> tests untouched). Re-practice keeps XP 0 (base.xp 0 × uplift = 0 — task 070
> intact). `main.ts` passes `activeTrick` at both call sites. 646 tests, verify +
> e2e green. Formula + resolution of the deferred legg-deg×EXPERT item in
> tech-decisions §7n.

**Priority**: Medium (v1 design-intent gap — §Difficulty Modes "no single dominant setting"; own-audit-flagged)
**Labels**: balance, difficulty, economy, tdd
**Estimated Effort**: Small

## Context & Motivation

specs.md §Difficulty Modes states the tuning intent explicitly:

> "*Intent:* the reward curve should be tuned so each mode is the rational choice
> at a different skill level (**no single dominant setting**)."

The same principle applies to trick choice: a much harder trick that pays the
**same** as an easy one is a *dominated* choice no rational player picks. Right
now that dominance exists. Tricks carry `learnMult` (bar-fill rate) and
`windowMult` (window/peak tightness) penalties (`core/tricks.ts:12-35`) but the
payout is **flat across tricks** — only the global mode multiplier
(`rewardMultiplier`: NORMAL 1 → HARD 1.3 → EXPERT 2.5, `core/difficulty.ts`)
scales rewards, and it scales **every** trick equally.

Worked example (flagged as Deferred in tech-decisions §7n):
- `legg-deg`: `learnMult 0.5`, `windowMult 0.6`.
- EXPERT `peakRadius 25` → effective PERFECT band `25 × 0.6 = 15 ms`, while the
  bar fills at **half** rate. So legg-deg in EXPERT takes far more, far tighter
  perfect taps than `sitt` in EXPERT — for the **identical** payout. legg-deg is
  strictly dominated: maximal pain, no extra pay.

This is a real v1 design-intent gap, pure game-logic, fully unit-testable, and
flagged by the team's own difficulty audit (tech-decisions §7n: "Legg deg +
EXPERT stacks two penalties … without a corresponding reward uplift, making this
combination extremely grindy" — recommendation deferred, no code change made).

## Desired Outcome

Harder tricks pay proportionally more, so no trick is a strictly dominated
choice: a trick's intrinsic difficulty (its `learnMult`/`windowMult` penalties)
earns a **reward uplift** that roughly offsets the extra effort, composing with —
not replacing — the existing mode and kennel multipliers. The composition order
stays the documented `payout = base × difficulty-mult × kennel-mult` (specs.md
§Kennel); the trick uplift folds into the difficulty-mult term so the formula's
shape is unchanged. Easy tricks (`sitt`, `learnMult 1`/`windowMult 1`) are
unaffected (uplift = 1×).

## Affected Components

### Files to Create / Modify
- `src/core/tricks.ts` (+ `tricks.test.ts`) — add a pure
  `trickRewardMultiplier(trick)` derived from the trick's existing
  `learnMult`/`windowMult` (no new hand-tuned field per trick → single source of
  truth, stays consistent if a trick's difficulty is retuned). Bounded.
- `src/core/game.ts` (+ existing economy tests) — fold the trick multiplier into
  the mastery payout so `completeMastery` pays `base × trickMult × modeMult ×
  kennelMult × prestige`. Re-practice payout: apply the same uplift to the
  reduced coin floor (still **no XP** on re-practice — task 070).
- `.docs/tech-decisions.md` §7n — record the formula and mark the deferred item
  resolved.

## Technical Approach

Functional/game-logic → **test-first (TDD)** per
[`.claude/skills/tdd`](../../.claude/skills/tdd/SKILL.md): one failing test →
minimal impl → repeat. Derive the uplift from the penalties already on the trick
so there is no second source of truth and no per-trick magic number to maintain.

### Behaviours to test (TDD)
1. `trickRewardMultiplier(sitt)` (`learnMult 1`, `windowMult 1`) === `1` — easy
   tricks unchanged.
2. `trickRewardMultiplier(leggDeg)` > `trickRewardMultiplier(ligg)` >
   `trickRewardMultiplier(sitt)` — monotonic in difficulty (harder ⇒ higher pay).
3. The multiplier is **bounded** (e.g. capped ≤ ~2.2×) so legg-deg can't out-earn
   sane play; assert the cap holds for the hardest trick.
4. `completeMastery` payout for a hard trick exceeds an easy trick's at the same
   mode/kennel/prestige, in the documented order `base × trickMult × modeMult ×
   kennelMult`; re-practice applies the uplift to coins and still grants **0 XP**.
5. Composition is multiplicative and order-stable (no double-counting of the mode
   multiplier).

### Before
```ts
// src/core/game.ts (shape)
completeMastery(profile, mode, kennelMult, prestigePoints) {
  const base = MASTERY_BASE_PAYOUT;                 // flat across tricks
  const coins = base.coins * modeMult(mode) * kennelMult * prestige(prestigePoints);
  const xp    = base.xp    * modeMult(mode) *           prestige(prestigePoints);
  ...
}
```

### After
```ts
// src/core/tricks.ts
/** Reward uplift for a trick's intrinsic difficulty; 1 for the easiest, bounded above. */
export function trickRewardMultiplier(trick: Trick): number {
  // harder = lower learnMult/windowMult ⇒ higher uplift, capped.
  const raw = 1 + (1 - trick.learnMult) + (1 - trick.windowMult) * 0.5;
  return Math.min(REWARD_UPLIFT_CAP, raw);
}

// src/core/game.ts
completeMastery(profile, mode, kennelMult, prestigePoints, trick) {
  const tMult = trickRewardMultiplier(trick);
  const coins = base.coins * tMult * modeMult(mode) * kennelMult * prestige(prestigePoints);
  const xp    = base.xp    * tMult * modeMult(mode) *              prestige(prestigePoints);
  ...
}
```
*(Exact coefficients/cap are a tuning call — pick conservative values, document
them in tech-decisions §7n, and pin them with the bound/monotonicity tests above.
The call sites in `main.ts` must pass the active trick through.)*

## Risks & Considerations
- **No-XP-on-repractice invariant (task 070):** the uplift must apply to the
  reduced re-practice **coins** but must not reintroduce XP on re-practice —
  assert XP stays 0 there.
- **Bound it:** an uncapped uplift could let players farm the hardest trick;
  cap the multiplier and test the cap.
- **Single source of truth:** derive from existing `learnMult`/`windowMult`
  rather than adding a hand-tuned per-trick reward field, so retuning a trick's
  difficulty keeps its pay consistent automatically.
- **Save compatibility:** payout is computed live at mastery; no save-schema change.
- **Call-site threading:** `completeMastery`/`completePractice` now need the
  active `Trick`; update `main.ts` call sites (they already have the trick id).

## Acceptance Criteria
- [x] Failing tests written first for `trickRewardMultiplier` (sitt = 1; monotonic harder ⇒ higher; bounded by cap) — TDD red → green.
- [x] `completeMastery` pays a hard trick more than an easy trick at equal mode/kennel/prestige, preserving the `base × trickMult × modeMult × kennelMult` order with no double-counting.
- [x] Re-practice applies the uplift to coins and still grants **0 XP** (task 070 invariant intact).
- [x] `main.ts` mastery/practice call sites pass the active trick; no flat-payout path remains.
- [x] Formula + coefficients/cap recorded in `.docs/tech-decisions.md` §7n; the Deferred "legg-deg + EXPERT" item marked resolved.
- [x] `bun run verify` green (typecheck + tests + build, no warnings); `bun run e2e` green.
