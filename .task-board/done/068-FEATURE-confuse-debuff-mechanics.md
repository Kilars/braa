# FEATURE: Confuse Debuff Mechanics (window narrows + distractors rise)

**Status**: Backlog
**Created**: 2026-06-16
**Priority**: High
**Labels**: core, logic, difficulty, scheduler, feel, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec **Mistakes** (specs.md:143–150):

> A **false mark** … knocks the learned bar back slightly **and** briefly
> **confuses** the dog.
> **Confuse debuff (concrete):** for ~3 s the window narrows (≈ −40%) and
> distractors increase (≈ +50%), and the dog visibly jitters — the next marks are
> harder to read. … Because off-window taps are punished, **continuous tapping is
> a net-losing strategy**.

This is the mechanism that makes the game's central design principle — *"patience
wins, mashing loses"* (specs.md:39, 149) — actually true in play. **Today it is
only half-implemented:** a false mark applies the −4% bar hit and sets
`confusedUntil`, but the **mechanical** half (tighter window + more distractors for
the debuff window) **never fires**. `isConfused()` is read in exactly two places,
both cosmetic:

- `src/ui/viewModel.ts:50` → a `confused` flag → a CSS class.
- `src/render/dogState.ts:38` → the dog's confused tint/jitter.

The `tick()` loop in `src/main.ts` never reads confuse state to change the
scheduler, so the next attempts after a false mark are exactly as easy as before.
Mashing BRA therefore costs only the one-time −4% — there is no compounding "now
it's harder to read", so spamming is **not** the losing strategy the spec
requires.

## Current State

- `src/core/session.ts` — `applyMark` sets `confusedUntil = now + CONFUSE_MS`
  (3000) on `FALSE_MARK` (refresh-not-stack already correct); `isConfused(s, now)`
  exists.
- `src/main.ts:497–562` `tick()` — regenerates the timeline on exhaustion via
  `regenerateTimeline(now)` and rebuilds `SCHEDULER_CFG` on mode/trick/dog change,
  but **never** in response to confuse.
- `src/app/gameHelpers.ts:51` `buildSchedulerCfg(masteredCount, roundDifficulty)` —
  the single point where an `EffectiveDifficulty` becomes a `SchedulerConfig`
  (and where distractors are onboarding-gated). The window (`windowWidth`,
  `peakRadius`) and `distractorRate` are baked into the **timeline** at
  generation time (`src/core/scheduler.ts:18` `buildTimeline`).

## Desired Outcome

While `isConfused(session, now)` is true, the **active timeline** uses a confused
difficulty: window ≈ −40% (`windowWidth` and `peakRadius` ×0.6) and distractors
≈ +50% (`distractorRate` ×1.5, capped at 1, and still subject to the onboarding
distractor gate). When the debuff expires, play returns to the round's normal
difficulty. No change to the existing −4%/−8%/−10% bar penalty or to the visual
confuse cue (those already work).

## Affected Components

### Files to Create
- *(none required)* — the pure modifier can live in `src/core/difficulty.ts`
  alongside `applyTrickProfile`, with its tests in `src/core/difficulty.test.ts`.

### Files to Modify
- `src/core/difficulty.ts` (+ `.test.ts`) — new **pure** `confuseDifficulty(eff)`.
  **Test-first.**
- `src/main.ts` — in `tick()`, detect the confuse on/off edge and rebuild
  `SCHEDULER_CFG` + regenerate the timeline from the confused vs. normal
  difficulty.

### Dependencies
- **Internal**: `session.isConfused` / `CONFUSE_MS` (reused as-is),
  `buildSchedulerCfg` (compose the confused difficulty through it so the
  onboarding distractor gate still applies), `regenerateTimeline`.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions

- **Confuse is a pure transform on `EffectiveDifficulty`**, composed *before*
  `buildSchedulerCfg` so the existing onboarding distractor gate
  (`effectiveDistractorRate`) keeps working (no distractors pre-first-mastery even
  while confused). The tested unit is the transform; the wiring (timeline
  regeneration on edge) is integration glue.
- **Regenerate the timeline on the confuse edge, not per frame.** The window is
  baked into the timeline at build time, so the debuff is realised by rebuilding
  `SCHEDULER_CFG` and calling `regenerateTimeline(now)` exactly when confuse turns
  **on** and again when it turns **off** — not every tick (which would thrash the
  timeline and reset attempt phases constantly). Track a `prevConfused` boolean
  like the existing `prevMastered` edge detector.
- **Magnitudes match the spec**: window ×0.6 (−40%), distractor ×1.5 (+50%),
  distractor capped at 1. Keep these as named constants.

### Behaviours to test (TDD, `difficulty.test.ts`)

1. `confuseDifficulty` narrows `scheduler.windowWidth` to 0.6× the input
   (e.g. 400 → 240) and `peakRadius` to 0.6× (80 → 48).
2. It raises `scheduler.distractorRate` to 1.5× the input (0.2 → 0.3).
3. The distractor rate is **capped at 1** (input 0.8 → 1, not 1.2).
4. It is **pure/immutable** — the input object is unchanged; non-scheduler fields
   (`deltas`, `rewardMultiplier`, `tellIntensity`, `learnMult`) are preserved.
5. It composes with `applyTrickProfile` (order-independent enough that a confused,
   trick-profiled difficulty has both the tighter window and the trick's effects).

### Implementation Steps

1. **TDD `confuseDifficulty`** in `difficulty.ts` (behaviours 1–5), red→green.
2. **Wire** in `main.ts` `tick()`: compute `confusedNow = isConfused(state.session,
   now)`; on `confusedNow !== prevConfused`, set
   `SCHEDULER_CFG = buildSchedulerCfg(totalMasteredCount(roster), confusedNow ?
   confuseDifficulty(roundDifficulty) : roundDifficulty)` and call
   `regenerateTimeline(now)`; store `prevConfused = confusedNow`.
3. **Manual sanity**: spam BRA → after a false mark the apex window is visibly
   tighter and distractors more frequent for ~3 s, then it eases back. (Covered by
   the unit tests + a quick run; not a new e2e requirement.)

### Risks & Considerations

- **Risk: regenerating mid-window yanks an in-flight attempt.** Mitigation: this
  is acceptable — the debuff is *meant* to make the moment harder to read; the
  player should re-find the rhythm. Keep it to the on/off edges only.
- **Risk: double-applying confuse if `tick` rebuilds every frame.** Mitigation:
  the `prevConfused` edge guard ensures one rebuild per transition.
- **Risk: distractor gate bypass.** Mitigation: always pass the confused
  difficulty *through* `buildSchedulerCfg`, never set `distractorRate` directly.

## Before / After Examples

### Example 1: pure transform (tested)

**After** (`src/core/difficulty.ts`):
```ts
const CONFUSE_WINDOW_MULT = 0.6;     // window narrows ≈ −40%
const CONFUSE_DISTRACTOR_MULT = 1.5; // distractors increase ≈ +50%

/** Apply the false-mark confuse debuff to a difficulty: tighter window, more
 *  distractors. Pure/immutable; other fields preserved. */
export function confuseDifficulty(eff: EffectiveDifficulty): EffectiveDifficulty {
  return {
    ...eff,
    scheduler: {
      windowWidth: eff.scheduler.windowWidth * CONFUSE_WINDOW_MULT,
      peakRadius: eff.scheduler.peakRadius * CONFUSE_WINDOW_MULT,
      distractorRate: Math.min(1, eff.scheduler.distractorRate * CONFUSE_DISTRACTOR_MULT),
    },
  };
}
```

### Example 2: wiring into the tick loop

**Before** (`src/main.ts`, `tick()` — confuse never affects the scheduler):
```ts
prevMastered = currentlyMastered;

// When the timeline is exhausted (and not yet mastered), loop it
if (!state.session.mastered) {
  const elapsed = now - timelineOffset;
  if (elapsed > TIMELINE_DURATION_MS) {
    regenerateTimeline(now);
  }
}
```

**After**:
```ts
prevMastered = currentlyMastered;

// Confuse debuff: while confused, the active timeline uses a tighter window and
// more distractors (spec "Mistakes"). Rebuild only on the on/off edge.
const confusedNow = isConfused(state.session, now);
if (confusedNow !== prevConfused) {
  const eff = confusedNow ? confuseDifficulty(roundDifficulty) : roundDifficulty;
  SCHEDULER_CFG = buildSchedulerCfg(totalMasteredCount(roster), eff);
  regenerateTimeline(now);
  prevConfused = confusedNow;
}

if (!state.session.mastered) {
  const elapsed = now - timelineOffset;
  if (elapsed > TIMELINE_DURATION_MS) {
    regenerateTimeline(now);
  }
}
```

## Code References

- `src/core/session.ts:24–30` — `confusedUntil` set on FALSE_MARK; `isConfused`.
- `src/main.ts:497–562` — `tick()` loop, `regenerateTimeline`, `SCHEDULER_CFG`.
- `src/app/gameHelpers.ts:51–61` — `buildSchedulerCfg` (distractor gate).
- `src/core/difficulty.ts:76–91` — `applyTrickProfile` (pattern to mirror).
- `src/core/scheduler.ts:18–63` — `buildTimeline` (window baked at gen time).
- `.docs/specs.md:137–155` — Mistakes / confuse debuff.

## Progress Log

- 2026-06-16 — Task created (scan round 5; focus: close non-visual v1 gaps;
  verified `isConfused` has no mechanical effect today).
- 2026-06-17 — Implemented (TDD). Added pure `confuseDifficulty(eff)` to
  `src/core/difficulty.ts` (window/peakRadius ×0.6, distractorRate ×1.5 capped at
  1, immutable, full scheduler-field spread) under 9 new tests in
  `difficulty.test.ts`. Wired into `src/main.ts` `tick()`: `prevConfused` edge
  guard rebuilds `SCHEDULER_CFG` via `buildSchedulerCfg(totalMasteredCount(roster),
  …)` (onboarding distractor gate preserved) + `regenerateTimeline(now)` on the
  on/off edge; `prevConfused` reset in `startFreshRound`. Verify green: 513 tests
  (504 baseline + 9). Note: test-writer left a `typeof … infer T` annotation that
  resolved to `never`; impl agent corrected it to an explicit `EffectiveDifficulty`
  fixture (assertions unchanged).

## Acceptance Criteria

- [x] `confuseDifficulty(eff)` added to `src/core/difficulty.ts`, **test-first**,
      covering: window ×0.6, peakRadius ×0.6, distractor ×1.5, distractor capped
      at 1, immutability + non-scheduler fields preserved, composes with
      `applyTrickProfile`.
- [x] `tick()` rebuilds `SCHEDULER_CFG` + regenerates the timeline on the confuse
      on→off and off→on edges only (via a `prevConfused` edge guard), routing the
      confused difficulty through `buildSchedulerCfg` so the onboarding distractor
      gate still applies.
- [x] After a false mark, the apex window is mechanically tighter and distractors
      more frequent for the `CONFUSE_MS` window, then play returns to normal — the
      existing −4%/−8%/−10% bar penalty and the visual confuse cue are unchanged.
- [x] `bun run typecheck`, `bun run test`, `bun run build`, `bun run e2e` all green
      (report the verify summary line); existing tests stay green.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
