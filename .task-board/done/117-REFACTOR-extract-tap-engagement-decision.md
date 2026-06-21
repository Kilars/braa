# REFACTOR: Extract the tap engagement/call-back decision into pure, tested functions

**Status**: Done (2026-06-21)
**Created**: 2026-06-21 (iteration 24 scan)
**Priority**: Medium
**Labels**: refactor, correctness, core-logic, test-coverage, gap:untested-decision
**Estimated Effort**: Small-Medium

## Context & Motivation

`onBraTapCommit` (`src/main.ts:424-505`) holds the game's **most ordering-sensitive
logic**, and it lives in the one source file with **no unit test** (the ~885-line
bootstrap IIFE) — covered today only **indirectly** by `e2e/full-loop.mjs`. The subtle
rules braided inline here are exactly the kind a future edit can silently break:

1. **Call-back must branch BEFORE classification** — if the dog has walked off
   (engagement empty) the tap *calls the dog back* and must **never** score or
   false-mark (`main.ts:444-449`).
2. **Reward-latency engagement fires only on a real reward** — `engagement(..., {kind:
   'reward'})` is applied **only** when `result` is `PERFECT|OK` **and** there is an
   `attempt`, *after* the unconditional `{kind:'mark'}` update (`main.ts:471-480`). Get
   the condition or order wrong and a MISS/FALSE_MARK double-counts, or a reward stops
   nudging the meter.

These are pure decisions tangled with side effects (audio, scene notify, coach dismiss),
so they can't be unit-tested where they sit. The constituent pieces (`engagement`,
`rewardLatencyMs`, `isDisengaged`, `disengageBeat`, `callBackEngagement`, `comboAfter`)
are each pure and individually tested — but their **composition at the tap site is not**.
This is the highest-value correctness/test gap on the board: architecture/core-logic is a
**cold domain** (recent work is render-visual, tuning-refactor, and pure-test — all
saturated), and unlike those this directly de-risks the loop's heart.

## Current State

- `src/main.ts:444-449` — inline call-back branch (`isDisengaged(disengageBeat(meter))`).
- `src/main.ts:471-480` — inline mark engagement + conditional reward-latency engagement.
- No `src/app/` (or core) function captures either decision; no unit test exercises the
  composed ordering. `gameHelpers.ts` is the established home for extracted-from-`main.ts`
  pure helpers (tasks 033/092) and the pattern to mirror.

## Desired Outcome

- Two **pure, tested** functions capture the decisions, named so the rule is self-evident:
  - `isCallBackTap(engagementMeter): boolean` — true when a tap should call the dog back
    instead of marking (wraps `isDisengaged(disengageBeat(meter))` so the "branch before
    classification" rule has a tested name).
  - `tapEngagement({ engagementMeter, result, attempt, tnow }): number` — returns the new
    engagement value applying the `{kind:'mark', result}` transition and, **iff**
    `result ∈ {PERFECT, OK} && attempt`, the subsequent `{kind:'reward', latencyMs}`
    transition. Single source of truth for the order + condition.
- `onBraTapCommit` calls these instead of the inline expressions — **behavior-preserving**
  (byte-for-byte same runtime result), now with direct unit coverage.
- No change to gameplay, tuning, visuals, or the public HUD/scene API.

## Affected Components

### Files to Create / Modify
- `src/app/gameHelpers.ts` (+ `gameHelpers.test.ts`) — add `isCallBackTap` and
  `tapEngagement` (pure; import the existing `engagement`/`rewardLatencyMs`/`disengageBeat`/
  `isDisengaged`/`callBackEngagement`). TDD.
- `src/main.ts` — replace the inline call-back predicate (`444`) and the inline
  mark+reward engagement block (`471-480`) with calls to the new helpers. The call-back
  branch still also does `combo = 0` + `playTap` + `return` (those stay in the handler —
  only the *decision* moves out).
- `.docs/tech-decisions.md` — note the extraction + the invariant it locks down.

### Dependencies
- **Internal**: `engagement`, `rewardLatencyMs`, `ENGAGEMENT_FULL`, `disengageBeat`
  (`engagement.ts`); `isDisengaged`, `callBackEngagement` (`disengage.ts`). All pure,
  already tested. None blocking.
- **External**: none.

## Technical Approach

### Implementation Steps (TDD — `tdd` skill, vertical slices)
1. `isCallBackTap(meter)` — one test → impl: true at empty meter (walk-off), false at a
   healthy meter; boundary at the walk-off threshold (mirror `disengage.test.ts` cases).
2. `tapEngagement({ engagementMeter, result, attempt, tnow })` — one test → impl → repeat:
   - `PERFECT` with an attempt → applies **both** mark and reward transitions (assert it
     differs from mark-only, proving the reward leg ran),
   - `OK` with an attempt → both,
   - `MISS` → **only** the mark transition (no reward leg),
   - `FALSE_MARK` → only the mark transition,
   - `attempt === null` → only the mark transition even if a tier were passed (guards the
     `&& attempt` condition).
3. Swap the inline expressions in `onBraTapCommit` for the helpers; run the full gate +
   `e2e/full-loop.mjs` (the precision/regression guard) to prove behavior is unchanged.

### Before / After

**Before** (`src/main.ts`, inline — untested composition):
```ts
if (isDisengaged(disengageBeat(engagementMeter))) {       // call-back branch
  engagementMeter = callBackEngagement(engagementMeter);
  combo = 0; markAudio.playTap(); return;
}
// ...
engagementMeter = engagement(engagementMeter, { kind: 'mark', result });
if ((result === 'PERFECT' || result === 'OK') && attempt) {
  engagementMeter = engagement(engagementMeter, {
    kind: 'reward', latencyMs: rewardLatencyMs(tnow, attempt.peak),
  });
}
```

**After**:
```ts
// src/app/gameHelpers.ts (pure, tested)
export function isCallBackTap(engagementMeter: number): boolean {
  return isDisengaged(disengageBeat(engagementMeter));
}
export function tapEngagement(p: {
  engagementMeter: number; result: MarkResult; attempt: Attempt | null; tnow: number;
}): number {
  let m = engagement(p.engagementMeter, { kind: 'mark', result: p.result });
  if ((p.result === 'PERFECT' || p.result === 'OK') && p.attempt) {
    m = engagement(m, { kind: 'reward', latencyMs: rewardLatencyMs(p.tnow, p.attempt.peak) });
  }
  return m;
}
```
```ts
// src/main.ts
if (isCallBackTap(engagementMeter)) {
  engagementMeter = callBackEngagement(engagementMeter);
  combo = 0; markAudio.playTap(); return;
}
// ...
engagementMeter = tapEngagement({ engagementMeter, result, attempt, tnow });
```

### Risks & Considerations
- **Risk**: a subtle behavior change in the move. **Mitigation**: pure 1:1 extraction
  (same calls, same order); guarded by the new unit tests **and** the existing
  `e2e/full-loop.mjs` masters-by-apex-timing regression. Run both before done.
- **Risk**: import cycle (`gameHelpers` importing engagement/disengage). **Mitigation**:
  those modules don't import `gameHelpers`; `gameHelpers` already imports from `core/*`.
- **Note**: this is functional logic moving between files, so it is **test-first** (the
  helpers get unit tests as they're extracted), not a blind cut/paste. Scope is tight on
  purpose — only the two decisions move; the side effects stay in the handler. Do **not**
  expand into a full `main.ts` session-object rewrite (that's a separate, larger task).

## Acceptance Criteria

- [x] `isCallBackTap` and `tapEngagement` added to `gameHelpers.ts` **test-first** via
      `tdd`, with the cases above (both transitions on PERFECT/OK+attempt; mark-only on
      MISS/FALSE_MARK; mark-only when `attempt === null`; call-back true at empty meter).
- [x] `onBraTapCommit` uses the helpers; the inline predicate + inline engagement block
      are gone (grep-clean in `main.ts`).
- [x] **Behavior-preserving**: full gate green **and** `e2e/full-loop.mjs` still masters a
      trick by apex-timed taps (the precision regression guard) — no gameplay change.
- [x] Decision recorded in `.docs/tech-decisions.md`. **specs.md untouched.**
- [x] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

**Technical approach hint**: this is a surgical, behavior-preserving extraction of the
two riskiest ordering rules into pure tested functions — not a restructure. Keep the
side effects (audio/scene/coach) in the handler; move only the decisions. The win is
unit coverage on the loop's most edit-fragile composition.
