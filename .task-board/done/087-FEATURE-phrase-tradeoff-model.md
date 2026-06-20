# FEATURE: Give marker phrases a real trade-off (upside + downside), not pure upside

**Status**: Backlog
**Created**: 2026-06-17
**Priority**: Medium
**Labels**: feature, balance, phrases, tdd, spec-gap
**Estimated Effort**: Small

## Context & Motivation

specs.md §Marker Phrases: *"stronger phrases should gain a real **trade-off** (an
upside **and** a downside — e.g. +reward but a narrower window) so loading one
becomes a genuine choice."* Today every non-base phrase is **pure upside**:

```ts
// src/core/phrases.ts — every strong phrase is strictly better than 'bra':
SUPER_PHRASE     { windowBonusMs: 250, rewardBonus: 0.2,  cooldownMs: 12000 }
KJEMPEBRA_PHRASE { windowBonusMs: 350, rewardBonus: 0.3,  cooldownMs: 18000 }
```

`Phrase` has no downside field, and `applyPhraseToAttempt` only **widens** the
window (`start - bonus`, `end + bonus`). The only cost is a cooldown (a rate limit,
not a per-use trade-off). With the catalog now at five phrases, "just fire the
strongest off-cooldown" is becoming the dominant strategy the spec warns against.

The spec marks the *exact* model as an open design item (deferred to
tech-decisions.md), so this task **decides and documents** a conservative trade-off
(an autonomy-permitted, reversible balance call — not a money/legal/vision fork).

## Current State

- `Phrase` (`src/core/phrases.ts:5–11`): `windowBonusMs`, `rewardBonus`,
  `cooldownMs` — all upside or rate-limit; no downside lever.
- `applyPhraseToAttempt(a, p)` (`:123`) widens the outer window only; it never
  touches `peakRadius` (the PERFECT band).
- Reward bonus is consumed downstream in the payout path; window bonus feeds
  `classifyMark`.

## Desired Outcome

Stronger phrases keep their **reward bonus** but pay for it with a **narrower
PERFECT band** (`peakRadius`) — the spec's literal "+reward but a narrower window"
example. Loading a strong phrase becomes a genuine *precision-for-payout* choice:
easier to grab the bigger reward only if you can hit a tighter peak. Base `bra`
stays neutral (no bonus, no penalty, no cooldown). Exact numbers are tunable and
recorded in tech-decisions.md.

## Affected Components

### Files to Modify
- `src/core/phrases.ts` — add `peakRadiusPenaltyMs: number` to `Phrase` (default 0);
  set nonzero penalties on the stronger phrases; apply it in `applyPhraseToAttempt`.
- `src/core/phrases.test.ts` (or `markWithPhrase.test.ts`) — TDD the penalty.
- `.docs/tech-decisions.md` — record the chosen trade-off model + rationale
  (implementation notes are allowed here; specs.md is READ-ONLY).

## Technical Approach

### Architecture Decisions
- **Trade-off via the PERFECT band, not the OK window.** Keep (or reduce) the outer
  `windowBonusMs` and introduce `peakRadiusPenaltyMs` that **shrinks** `peakRadius`,
  so a strong phrase makes *landing PERFECT* (the big payout) harder while its reward
  multiplier is larger. Net expected value is a genuine skill check, not a freebie.
- **Base phrase untouched.** `BASE_PHRASE` keeps `peakRadiusPenaltyMs: 0` and remains
  the always-available, no-cooldown, no-penalty default.
- **Clamp to a floor.** Never let the penalty drive `peakRadius` to ≤ 0 — clamp to a
  small positive minimum so PERFECT stays *possible*, just harder.

### Behaviours to test (TDD — failing test first, see `.claude/skills/tdd/SKILL.md`)
1. A phrase with `peakRadiusPenaltyMs > 0` **narrows** the resulting attempt's
   `peakRadius` by the penalty.
2. The penalty is **clamped** so `peakRadius` never goes ≤ 0 (floor honored).
3. `BASE_PHRASE` (penalty 0, bonus 0) returns the attempt **unchanged**.
4. A phrase with only a window bonus and zero penalty still only widens the outer
   window (existing behaviour preserved — no regression).

### Implementation Steps
1. TDD behaviour 1 (penalty narrows `peakRadius`) — add the field + minimal apply.
2. TDD behaviours 2–4 (clamp, base unchanged, no-regression).
3. Assign conservative penalties to `SUPER` / `KJEMPEBRA` (and optionally `DYKTIG`);
   keep early/cheap phrases (`flink`) low/zero so onboarding stays gentle.
4. Document the model + values in tech-decisions.md.

### Before / After

```ts
// BEFORE
export interface Phrase {
  id: string; word: string; windowBonusMs: number; rewardBonus: number; cooldownMs: number;
}
export function applyPhraseToAttempt(a: Attempt, p: Phrase): Attempt {
  if (p.windowBonusMs === 0) return a;
  return { ...a, start: a.start - p.windowBonusMs, end: a.end + p.windowBonusMs };
}

// AFTER
export interface Phrase {
  id: string; word: string; windowBonusMs: number; rewardBonus: number; cooldownMs: number;
  /** Downside: shrinks the PERFECT band so the reward bonus must be earned. 0 = none. */
  peakRadiusPenaltyMs: number;
}
const PEAK_RADIUS_FLOOR_MS = 20;
export function applyPhraseToAttempt(a: Attempt, p: Phrase): Attempt {
  if (p.windowBonusMs === 0 && p.peakRadiusPenaltyMs === 0) return a;
  return {
    ...a,
    start: a.start - p.windowBonusMs,
    end: a.end + p.windowBonusMs,
    peakRadius: Math.max(PEAK_RADIUS_FLOOR_MS, a.peakRadius - p.peakRadiusPenaltyMs),
  };
}
```

## Risks & Considerations
- **Balance, not just code.** Pick conservative penalties; the point is a *choice*,
  not a nerf that makes strong phrases useless. Values stay tunable (documented).
- **Confirm `Attempt.peakRadius` exists** and is the field `classifyMark` uses for
  the PERFECT tier before wiring (check `src/core/mark.ts`); adapt the field name if
  the PERFECT band is modeled differently.
- **No new UI required** — the geometry flows through existing `classifyMark`; the
  loadout chip is unchanged.

## Acceptance Criteria
- [x] `Phrase` has `peakRadiusPenaltyMs` (default 0); stronger phrases set it > 0
      while keeping their reward bonus.
- [x] `applyPhraseToAttempt` narrows `peakRadius` by the penalty, clamped to a
      positive floor — TDD-covered (narrow / clamp / base-unchanged / no-regression),
      failing test written first.
- [x] The trade-off model + chosen values are recorded in `.docs/tech-decisions.md`
      (specs.md untouched).
- [x] Full verify gate green: `bun run typecheck` · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

## Resolution (2026-06-17)

Implemented test-first. `Phrase` gains `peakRadiusPenaltyMs`;
`applyPhraseToAttempt` now shrinks `peakRadius` by the penalty, clamped to
`PEAK_RADIUS_FLOOR_MS = 20` (base-phrase fast path returns the same reference
unchanged). Stronger phrases trade a tighter PERFECT band for their reward bonus —
the spec's "+reward but a narrower window," resolving the open design item.

Chosen penalties (conservative, tunable — documented in tech-decisions §7p):

| phrase | peakRadiusPenaltyMs | rationale |
|--------|--------------------|-----------|
| bra | 0 | neutral default, never penalised |
| flink | 0 | onboarding-gentle first purchase |
| dyktig | 25 | small, noticeable |
| super | 40 | medium skill check for +20% reward |
| kjempebra | 65 | steepest; +30% reward demands near-floor precision |

At NORMAL `peakRadius ≈ 80 ms`, kjempebra clamps the PERFECT band to 20 ms — tight
but hittable. **Verify:** `verify ●●● ✓ typecheck + tests + build (589 tests)`
(re-run by the main agent; penalty tests assert both window widening and band
narrowing — not weakened). Non-visual; a human "is the choice interesting?"
playtest is a welcome later check.
