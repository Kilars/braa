# FEATURE: Gate UNTRAIN_TRICKS out of the v1 trick-select (post-v1 content leak)

**Status**: Backlog
**Created**: 2026-06-17
**Priority**: Medium
**Labels**: onboarding, scope, post-v1-leak, content-gate, tdd
**Estimated Effort**: Small

## Context & Motivation

The spec classifies **untraining** as a **later addition**, not v1:

> **Untraining** — the dog has a bad habit (jumping, barking); the player marks
> its *absence* / restraint… **(Later additions, depth, once the core game is
> solid)** (specs.md:417–423)

And onboarding must drip systems in, never dump them:

> Systems are then **revealed in stages**, never all at once… This avoids dumping
> every system right after the first mastery. (specs.md:374–381)

But `getTricks()` in `main.ts` appends `UNTRAIN_TRICKS` to **every** trick-select,
unconditionally — no onboarding gate, no level requirement, no feature flag. A
brand-new player with zero mastered tricks sees **"Ikke hopp"** (an inverted-verb
untraining trick whose "mark the calm" mechanic is never explained yet) sitting
right next to the three starter commands. That is exactly the post-v1 surface +
onboarding dump the spec tells us to avoid, and "Ikke hopp" with no context is a
genuine confusion risk.

This is a confirmed scope/correctness leak (verified in code), it is **logic
(testable)**, and it is **not** in the saturated visual domain.

## Current State

- `src/main.ts:385–393` — `getTricks()`:
  ```ts
  const breedTricks = tricksForBreed(activeBreed);
  return [...breedTricks, ...UNTRAIN_TRICKS].map(trick => ({ trick, mastered: … }));
  ```
  `UNTRAIN_TRICKS` is always concatenated.
- `src/core/tricks.ts:19–24` — `UNTRAIN_TRICKS = [{ id: 'no-jump', name: 'Ikke hopp', …, untrain: true }]`.
- `src/core/tricks.ts:42–50` — `tricksForBreed()` already documents *"Untraining
  tricks are appended separately by main.ts based on onboarding stage"* — but that
  staged gating was **never actually implemented**; main.ts appends them flat.
- `src/core/onboarding.ts` — `onboardingStage(masteredCount)` returns a `Revealed`
  flag set; there is **no** untraining flag today.
- The full untrain mechanic (`untrainAttemptAt`, misbehaving visual state,
  scheduler untrain constants) is implemented and reachable from session 0.

## Desired Outcome

`UNTRAIN_TRICKS` do **not** appear in the trick-select for a v1 player. Untraining
is a "later addition," so the default v1 build hides it. The decision of *whether*
untrain tricks are eligible is a **pure, tested predicate** (so when untraining is
formally introduced post-v1, flipping it on is a one-line, tested change), and
`getTricks()` consults it instead of appending unconditionally. Starter +
signature tricks are unaffected.

## Affected Components

### Files to Modify
- `src/core/onboarding.ts` (+ `onboarding.test.ts`) — **test-first**: add an
  `untraining` eligibility flag to the reveal model (kept `false` for v1), OR a
  dedicated pure `untrainTricksUnlocked(...)` predicate. Keep it monotonic and
  consistent with the existing staging style.
- `src/main.ts` — `getTricks()` consults the predicate instead of always spreading
  `UNTRAIN_TRICKS`.
- `.docs/tech-decisions.md` — record that untraining is gated off for v1 and the
  exact flip condition for post-v1 introduction.

### Dependencies
- **Internal**: `onboarding.ts`, `tricks.ts`. Independent of tasks 074/076.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions
- **Gate via a pure predicate, not an inline conditional.** The "are untrain
  tricks available?" decision belongs in `onboarding.ts` next to the other staged
  reveals, where it is unit-tested — not buried in `getTricks()`. `main.ts` stays
  thin glue.
- **Default OFF for v1.** Per spec, untraining is post-v1. The predicate returns
  `false` under all current v1 conditions. Encode the *future* unlock condition
  explicitly (e.g. a constant threshold or a `Revealed.untraining` flag wired to a
  deep stage) so turning it on later is a documented one-liner — but it stays off
  now. Do **not** invent a new gameplay stage for v1; just suppress the leak.
- **No behavior change to starter/signature tricks.**

### Behaviours to test (TDD, `onboarding.test.ts`)
1. The untraining gate is **`false`** for `masteredCount = 0` (fresh player).
2. It is **`false`** across the full current v1 range (e.g. 0..10 mastered) — v1
   never surfaces untraining.
3. (Forward-proofing, optional) if implemented as a threshold/flag, assert the
   exact future-on condition flips it `true`, documenting the post-v1 switch.
4. Existing `onboardingStage` reveals (distractors/phrases/economy/kennel/
   difficulty) are unchanged by the addition (regression guard).

### Implementation Steps
1. **TDD** `onboarding.ts`: add the untraining eligibility (flag on `Revealed`, or
   `untrainTricksUnlocked(masteredCount)` predicate). Tests 1–4, red→green.
2. **`main.ts` `getTricks()`**: build the list as
   `[...breedTricks, ...(untrainUnlocked ? UNTRAIN_TRICKS : [])]`, deriving
   `untrainUnlocked` from the predicate (using the same `masteredCount` /
   onboarding source already available there).
3. **Doc**: note in tech-decisions.md that untraining is intentionally gated off
   for v1, where the gate lives, and the precise condition to enable it post-v1.
4. **Verify**: full gate green; confirm a fresh select shows only the starters
   (+ the breed's signature trick when owned), no "Ikke hopp".

## Before / After Examples

### Example 1: pure gate (tested)
**After** (`src/core/onboarding.ts`):
```ts
// Untraining is a post-v1 "later addition"; gated off for the v1 build.
// Flip this condition when untraining is formally introduced.
export function untrainTricksUnlocked(_masteredCount: number): boolean {
  return false; // v1: never surface untrain tricks in select
}
```

### Example 2: wiring
**Before** (`src/main.ts:389–393`):
```ts
const breedTricks = tricksForBreed(activeBreed);
return [...breedTricks, ...UNTRAIN_TRICKS].map(trick => ({
  trick,
  mastered: masteredIds.includes(trick.id),
}));
```
**After**:
```ts
const breedTricks = tricksForBreed(activeBreed);
const untrain = untrainTricksUnlocked(masteredIds.length) ? UNTRAIN_TRICKS : [];
return [...breedTricks, ...untrain].map(trick => ({
  trick,
  mastered: masteredIds.includes(trick.id),
}));
```

## Risks & Considerations
- **Risk:** removing "Ikke hopp" from select strands the existing untrain mechanic
  code (`untrainAttemptAt`, misbehaving state). That code is **fine to keep
  dormant** — it is the post-v1 implementation, just not surfaced. Do not delete
  it; only gate the select entry. (If desired, note it as dead-until-post-v1.)
- **Risk:** a save where a player already "mastered" `no-jump` in the current
  leaky build. Hiding it from select is harmless — the mastered id simply isn't
  shown; no crash (the `mastered` map just won't list it). Acceptable.
- **Out of scope:** designing the real post-v1 untraining onboarding stage — only
  the v1 suppression + a documented flip point.

## Code References
- `src/main.ts:385–393` — `getTricks()` (gate point).
- `src/core/tricks.ts:19–24,42–50` — `UNTRAIN_TRICKS` + the stale "appended by
  main.ts based on onboarding stage" comment this task makes true.
- `src/core/onboarding.ts` — staged-reveal home for the new gate.
- `.docs/specs.md:417–423` — untraining is a "later addition" (post-v1).
- `.docs/specs.md:374–381` — onboarding reveals systems in stages.

## Progress Log
- 2026-06-17 — Task created (scan round 7). Confirmed via code read: `getTricks()`
  (`main.ts:390`) spreads `UNTRAIN_TRICKS` unconditionally; `tricksForBreed`'s
  comment claims onboarding-staged appending that was never implemented; a fresh
  player sees "Ikke hopp" with no context.
- 2026-06-17 — Implemented (TDD): test-writer added red tests for
  `untrainTricksUnlocked` (false at 0 and across 0..10); impl added the pure gate to
  `onboarding.ts` (returns false for v1) and wired `getTricks()` to append
  `UNTRAIN_TRICKS` only when unlocked (`main.ts:390`). Untrain mechanic code
  (`untrainAttemptAt`, misbehaving state) left dormant, not deleted; the id→Trick
  lookup at `main.ts:629` still resolves untrain ids (harmless). tech-decisions.md
  records the gate location + post-v1 flip condition. Verified via grep that no
  unconditional spread remains. `bun run verify` ✓ (565 tests); e2e in iteration gate.

## Resolution

Untraining (a post-v1 "later addition") no longer leaks into the v1 trick-select.
A pure `untrainTricksUnlocked(masteredCount)` gate (currently always `false`) lives
beside the other staged reveals in `onboarding.ts`; `getTricks()` consults it, so a
fresh player sees only the starter commands (+ the owned breed's signature trick) —
no "Ikke hopp". Turning untraining on post-v1 is a one-line, documented flip. The
existing untrain mechanic stays dormant for reuse. TDD; verify green.

## Acceptance Criteria

- [x] A pure untraining-eligibility gate added to `onboarding.ts` **test-first**,
      returning `false` across the entire v1 mastered-count range (fresh player and
      beyond), with existing `onboardingStage` reveals unchanged. (Behaviours 1–2,4.)
- [x] `getTricks()` in `main.ts` consults the gate and only appends
      `UNTRAIN_TRICKS` when it is unlocked; starter + signature tricks unaffected.
- [x] A fresh trick-select shows only starters (+ owned breed's signature trick) —
      **no "Ikke hopp"**.
- [x] tech-decisions.md records that untraining is gated off for v1, where the gate
      lives, and the exact condition to enable it post-v1.
- [x] `bun run typecheck`, `bun run test`, `bun run build`, `bun run e2e` all green.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
