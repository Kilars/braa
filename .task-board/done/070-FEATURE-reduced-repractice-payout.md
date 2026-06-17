# FEATURE: Reduced Re-Practice Payout (mastered-trick income floor)

**Status**: Backlog
**Created**: 2026-06-16
**Priority**: Medium-High
**Labels**: core, logic, economy, progression, anti-softlock, tdd
**Estimated Effort**: Small-Medium

## Context & Motivation

Spec **Dogs & Roster** (specs.md:108–109):

> **Mastered tricks are re-practiceable for a reduced payout** — a guaranteed
> income floor, so a player can never soft-lock with nothing affordable left.

And **Economy** (specs.md:162–165): XP is granted by **mastering** tricks (active
play only — *"the idle trickle is coins, never XP, so unlock-gating stays
skill-driven"*).

**Today, re-practicing an already-mastered trick pays the full mastery reward.**
`src/main.ts:521` calls `completeMastery(...)` unconditionally on every
bar→100% transition; `recordMastery` is idempotent (no double-listing) but the
payout (`MASTERY_BASE_PAYOUT = { coins: 50, xp: 30 }`, `game.ts:5`) fires at full
rate regardless of whether the trick was already in the dog's repertoire. Two
problems:

1. **No reduced "income floor"** as the spec intends — grinding the easiest known
   trick pays the same as a fresh mastery.
2. **XP farming**: re-mastering an easy trick grants full XP, which would let a
   player level past the intended skill-gated pace — directly undermining the
   "unlock-gating stays skill-driven" rule and the two-step unlock (task 069).

This also matters as the anti-softlock guarantee that backs task 069's level
gate: even with nothing new affordable, a player can always re-practice for coins.

## Current State

- `src/core/game.ts:5–15` — `MASTERY_BASE_PAYOUT` + `completeMastery()`; one payout
  path, full rate.
- `src/main.ts:505–540` — mastery false→true edge: `recordMastery` (idempotent),
  jingle, celebrate, `notifyMastery`, then `completeMastery(...)` + `persist()`.
- `src/core/roster.ts:12` — `recordMastery` guards against duplicate trick ids, so
  "already mastered" is detectable by checking the dog's `masteredTrickIds`
  **before** the round starts.

## Desired Outcome

When a round completes on a trick the active dog had **already** mastered before
the round began, the payout is the **reduced** re-practice amount (lower coins,
**no XP**); a genuinely new mastery still pays the full `MASTERY_BASE_PAYOUT`.
The difficulty/kennel/prestige multipliers still apply to whichever base is used.

## Affected Components

### Files to Modify
- `src/core/game.ts` (+ `.test.ts`) — add `PRACTICE_BASE_PAYOUT` and a
  `completePractice()` (or generalise to `completeRound(profile, base, mode, …)`
  and define both bases). **Test-first.**
- `src/main.ts` — capture `wasAlreadyMastered` at round start (trick select), and
  on the mastery edge branch on it to call `completePractice` vs `completeMastery`.

### Dependencies
- **Internal**: `economy.award` (reused), `difficulty.effectiveDifficulty`,
  `kennel.kennelMultiplier`, `prestige.prestigeMultiplier` (all already threaded
  into `completeMastery`). Composes with task 069 (the income floor that prevents
  softlock under level gating) — independent, either order.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions

- **Branch on pre-round mastery, not post.** `recordMastery` mutates the roster on
  the edge, so "already mastered?" must be sampled **before** `startFreshRound`
  (i.e. in `onSelectTrick`, mirroring the existing `getTricks().mastered` flag).
  Store it in a `wasAlreadyMastered` mutable like `prevMastered`.
- **Reduced payout = lower coins, zero XP.** XP-from-mastery is the skill-gated
  progression currency (specs.md:162–164); re-practice is an explicit *coin* income
  floor (specs.md:108, mirroring the kennel "coins, never XP" rule). So
  `PRACTICE_BASE_PAYOUT = { coins: 15, xp: 0 }` (placeholder; record in
  tech-decisions). The same multiplier stack applies.
- **Keep `completeMastery` intact**; add a sibling so existing mastery tests are
  untouched and the two paths read clearly at the call site.

### Behaviours to test (TDD, `game.test.ts`)

1. `completePractice` awards `PRACTICE_BASE_PAYOUT` (reduced coins, **0 XP**) ×
   the same multiplier stack as mastery (mode reward × kennel × prestige).
2. `PRACTICE_BASE_PAYOUT.coins < MASTERY_BASE_PAYOUT.coins` and
   `PRACTICE_BASE_PAYOUT.xp === 0` (the income-floor / no-XP-farm guarantees,
   asserted directly).
3. `completePractice` does not change `profile.level` (xp unchanged) for a profile
   whose coins increase — i.e. re-practice never levels you up.
4. (Regression) `completeMastery` still pays the full base — unchanged.

### Implementation Steps

1. **TDD `game.ts`** — add `PRACTICE_BASE_PAYOUT` + `completePractice` (behaviours
   1–4), red→green.
2. **Wire `main.ts`**: in `onSelectTrick`, set `wasAlreadyMastered =
   roster.find(d => d.id === activeDogId)?.masteredTrickIds.includes(trick.id) ??
   false`. On the mastery edge, `profile = wasAlreadyMastered ?
   completePractice(...) : completeMastery(...)`.
3. **Doc**: record the `PRACTICE_BASE_PAYOUT` values + "no XP on re-practice"
   rationale in `.docs/tech-decisions.md`.

### Risks & Considerations

- **Risk: `wasAlreadyMastered` goes stale** across multiple rounds without
  re-selecting. Mitigation: it is recomputed on every `onSelectTrick`, and a round
  always begins via trick select — but reset/recompute it at `startFreshRound` too,
  to be safe.
- **Risk: zero-XP re-practice feels dead.** Mitigation: the spec explicitly frames
  this as a *coin* income floor, not progression; the celebration/feedback still
  fires. If playtesting wants a token XP, it's a one-line tuning change.
- **Risk: onboarding** — first-ever mastery is never "already mastered", so the
  early game is unaffected.

## Before / After Examples

### Example 1: payout functions (tested)

**After** (`src/core/game.ts`):
```ts
export const MASTERY_BASE_PAYOUT:  Payout = { coins: 50, xp: 30 };
export const PRACTICE_BASE_PAYOUT: Payout = { coins: 15, xp: 0 };  // income floor, no XP

export function completePractice(
  p: Profile, mode: DifficultyMode, kennelMult = 1, prestigePoints = 0,
): Profile {
  const { rewardMultiplier } = effectiveDifficulty(mode);
  return award(p, PRACTICE_BASE_PAYOUT, rewardMultiplier * kennelMult * prestigeMultiplier(prestigePoints));
}
```

### Example 2: branch at the mastery edge

**Before** (`src/main.ts:521`):
```ts
// Award coins + XP, persist (fire-and-forget), go back to select
profile = completeMastery(profile, MODE, kennelMultiplier(kennelUpgradeIds), prestigePoints);
```

**After**:
```ts
// New mastery pays full; re-practicing an already-mastered trick pays the reduced
// income floor (reduced coins, no XP) — keeps unlock-gating skill-driven.
profile = wasAlreadyMastered
  ? completePractice(profile, MODE, kennelMultiplier(kennelUpgradeIds), prestigePoints)
  : completeMastery(profile, MODE, kennelMultiplier(kennelUpgradeIds), prestigePoints);
```

…with `wasAlreadyMastered` captured in `onSelectTrick`:
```ts
onSelectTrick(trick: Trick) {
  // …existing…
  wasAlreadyMastered =
    roster.find(d => d.id === activeDogId)?.masteredTrickIds.includes(trick.id) ?? false;
  startFreshRound(performance.now());
  // …
}
```

## Code References

- `src/core/game.ts:5–15` — `MASTERY_BASE_PAYOUT`, `completeMastery`.
- `src/main.ts:341–355` — `onSelectTrick` (capture point).
- `src/main.ts:505–540` — mastery false→true edge (branch point).
- `src/core/roster.ts:12` — `recordMastery` idempotency.
- `.docs/specs.md:108–109, 162–165` — re-practice income floor, XP rules.

## Progress Log

- 2026-06-16 — Task created (scan round 5; verified `completeMastery` fires at full
  rate on every bar→100%, with no already-mastered check).
- 2026-06-17 — Implemented (TDD, 4 new tests). game.ts: `PRACTICE_BASE_PAYOUT =
  {coins:15, xp:0}` + `completePractice` (same mode×kennel×prestige multiplier
  stack as mastery). main.ts: `wasAlreadyMastered` captured in `onSelectTrick`
  (line 359, before `startFreshRound`, from the pre-round roster so `recordMastery`
  on the edge can't taint it); mastery edge branches full `completeMastery` vs
  reduced `completePractice`. Rationale recorded in tech-decisions ("Re-Practice
  Payout — DECIDED"). Verify green: 537 tests (533 baseline + 4).

## Acceptance Criteria

- [x] `PRACTICE_BASE_PAYOUT` + `completePractice` added to `src/core/game.ts`,
      **test-first**, covering: reduced coins, **0 XP**, same multiplier stack,
      coins<mastery, never levels the player up, and a `completeMastery`
      regression.
- [x] `main.ts` captures `wasAlreadyMastered` at trick select and branches the
      mastery-edge payout: full for a new mastery, reduced/no-XP for re-practice.
- [x] Re-practicing an already-mastered trick grants reduced coins and **no XP**;
      a fresh mastery is unchanged (full coins + XP).
- [x] `PRACTICE_BASE_PAYOUT` values + "no XP on re-practice" rationale recorded in
      `.docs/tech-decisions.md`.
- [x] `bun run typecheck`, `bun run test`, `bun run build`, `bun run e2e` all green
      (report the verify summary line).

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
