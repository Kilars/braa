# FEATURE: Per-Mark Dog Reward Reaction (D8 — every good mark feels good)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: render, dog, animation, feel, visual-review, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec **D8 — Happy / reward** and the **"the mark must always feel good"** design
pillar:

> **On every successful mark**, and bigger on mastery, the dog gives a clearly
> positive reaction (perk-up, bounce, tail wag).

Today the dog only enters the `happy` visual state on **mastery** (`session
.mastered`). An individual **PERFECT/OK mark mid-round produces no on-dog
reaction** — the dog keeps offering as if nothing happened. So the core satisfying
beat ("BRA!" → the dog reacts) is missing on the per-mark level; only the audio +
UI respond. This is the cheapest remaining win for game feel.

## Current State

- `src/main.ts` — on tap: `result = classifyMark(...)`, `state = { ...applyMark,
  lastResult: result }`, `markAudio.play(result)`, combo update. No on-dog hook.
- `src/render/dogState.ts` — `dogVisualState` only returns `happy` when
  `session.mastered`; per-mark results don't change the steady visual state.
- `src/render/dogPose.ts` — `happy` pose exists (bounce + fast wag) but is only
  reached on mastery.
- A successful mark = `result` is `'perfect'` or `'ok'` (a `'miss'`/`'false'` is
  not a reward).

## Desired Outcome

On **every successful mark** (PERFECT or OK), the dog gives a brief, transient
**reward pulse** — a quick perk/bounce + tail flick — layered over whatever state
it's in, **bigger for PERFECT than OK**, then it settles back. Mastery still gives
the full, bigger `happy` reaction (unchanged). Miss/false marks give **no** reward
pulse (false marks already drive the confused state). Reduced motion dampens the
pulse but keeps a small positive cue (D8 must still read — perk/tint — per D13).

## Affected Components

### Files to Create
- `src/render/rewardPulse.ts` + `src/render/rewardPulse.test.ts` — a **pure**
  decay function: given the time since the last successful mark and its tier,
  return a 0..1 pulse intensity (e.g. `rewardPulse(now, markAt, tier, { reducedMotion })`).
  **Test-first** (timing/decay maths).

### Files to Modify
- `src/render/scene.ts` — expose a way to register a successful mark (e.g.
  `updateDog` reads `state.lastResult` + a mark timestamp, or a new
  `rewardPulse(tier, at)` method); apply the pulse as an additive bounce/wag in the
  render loop, decaying over ~400–600 ms.
- `src/main.ts` — after a successful `classifyMark`, notify the scene of the
  reward (tier + `now`).
- Possibly `src/render/dogPose.ts` — add an additive reward channel, or apply the
  pulse directly in scene (implementer's call; keep the decay maths pure/tested).

### Dependencies
- **External**: none.
- **Internal**: `mark.ts` (`classifyMark` tiers), 058 (poses) — done.
- **Blocking**: none. Independent of 062/063.

## Technical Approach

### Architecture Decisions

- **Transient event, not a steady state.** The 6-state `dogVisualState` mapping
  stays as-is (it's for sustained states). The reward is a **time-decaying pulse**
  layered on top, so the dog can be mid-`offering` and still flick a happy bounce
  on a good mark without leaving the offering pose.
- **Pure decay maths** (`rewardPulse.ts`) is the testable unit: intensity starts
  at the tier's peak at `markAt` and decays to 0 over the window; PERFECT peak >
  OK peak; reduced motion scales the amplitude down but not instantly to 0.
- **No reward on miss/false** — only `'perfect'`/`'ok'` trigger it.

### Behaviours to test (TDD, `rewardPulse.test.ts`)

1. At `now === markAt` the pulse is at its tier peak; well after the window it's 0.
2. PERFECT peak intensity > OK peak intensity.
3. `miss`/`false` (or no mark) → 0 intensity always.
4. Intensity **decays monotonically** from markAt to the window end.
5. `reducedMotion: true` reduces the peak amplitude but keeps it > 0 at markAt
   (cue retained, D8/D13).

### Implementation Steps

1. **TDD `rewardPulse.ts`** through behaviours 1–5 (slices, red→green).
2. **Wire the mark event**: main.ts tells the scene `(tier, now)` on a successful
   mark; scene stores it and feeds `rewardPulse` into the render loop.
3. **Apply** the pulse as an additive bounce + tail-wag boost over the current pose.
4. **Visual Review** — observe/screenshot: a good mark visibly pops the dog;
   PERFECT pops more than OK; a false mark does not; mastery still does the full
   happy reaction.

### Risks & Considerations

- **Risk: pulse fights the offering/apex pose** — **Mitigation**: additive bounce
  on top; cap the combined motion so it reads as a happy flick, not a glitch.
- **Risk: rapid marks stack into jitter** — **Mitigation**: the pulse **refreshes**
  (restart from the new markAt) rather than summing — mirror the confuse-debuff
  "refresh not stack" rule in specs/Mistakes.
- **Risk: reduced-motion still too lively** — **Mitigation**: the TDD amplitude
  test guards it; verify with emulation.

## Before / After Examples

### Example 1: pure decay (tested)

**After** (`src/render/rewardPulse.ts`):
```ts
export type MarkTier = 'perfect' | 'ok' | 'miss' | 'false';
const PEAK: Record<MarkTier, number> = { perfect: 1, ok: 0.55, miss: 0, false: 0 };
const WINDOW_MS = 500;
export function rewardPulse(
  now: number, markAt: number | null, tier: MarkTier, opts: { reducedMotion: boolean },
): number {
  if (markAt === null) return 0;
  const t = (now - markAt) / WINDOW_MS;
  if (t < 0 || t > 1) return 0;
  const decay = 1 - t;                         // monotonic to 0
  const amp = opts.reducedMotion ? 0.4 : 1;
  return PEAK[tier] * decay * amp;
}
```

### Example 2: main notifies the scene on a good mark

**Before** (`src/main.ts`):
```ts
const result = classifyMark(now, attempt);
state = { ...state, session: applyMark(...), lastResult: result };
markAudio.play(result);
```

**After**:
```ts
const result = classifyMark(now, attempt);
state = { ...state, session: applyMark(...), lastResult: result };
markAudio.play(result);
if (result === 'perfect' || result === 'ok') sceneApi?.rewardPulse(result, now);
```

## Code References

- `src/core/mark.ts` — `classifyMark` tiers (`perfect`/`ok`/`miss`/`false`).
- `src/main.ts` — the tap/mark handler (~line 310) where the result is known.
- `src/render/dogPose.ts` / `scene.ts` — where the pulse is applied over the pose.
- `.docs/specs.md` "The Dog" D8, "Design Principles" (the mark must always feel
  good), "Mistakes" (refresh-not-stack rule to mirror).

## Progress Log

- 2026-06-14 — Task created (scan round 3, focus: dog).
- 2026-06-15 — Implemented. Part A: TDD with 8 tests across 5 slices (rewardPulse.ts + rewardPulse.test.ts). Part B: wired into scene.ts (notifyMark API, additive pulse in render loop) and main.ts (calls notifyMark on PERFECT/OK). Visual review: PERFECT mark shows visible dog bounce and tail-wag pop at 0ms, decaying through 80ms, 250ms, fully settled by 550ms. FALSE_MARK shows no reaction. 482 tests green.

## Resolution

Implemented per-mark reward pulse (D8 — every good mark feels good). The pure `rewardPulse()` decay function (test-first, 8 tests) drives an additive bounce (root.position.y +0.10 max) and tail-wag boost layered over the current dog pose in scene.ts. The `notifyMark(tier, markAt)` API on the scene replaces (refresh-not-stack) on rapid marks. main.ts calls it only on 'PERFECT' or 'OK'. Visual review confirmed: PERFECT produces a visible jump + tail flick decaying over ~500ms; OK produces a smaller pop; FALSE_MARK produces no reaction; mastery happy state unchanged.

## Acceptance Criteria

- [x] `src/render/rewardPulse.ts` exists with a **pure** decay function and
      `rewardPulse.test.ts` written **test-first** covering: peak at markAt / 0
      after window, PERFECT > OK, miss/false = 0, monotonic decay, reduced-motion
      reduced-but-non-zero.
- [x] A successful mark (PERFECT/OK) triggers a brief on-dog reward pulse layered
      over the current state; PERFECT pops more than OK; miss/false trigger none.
- [x] Mastery still gives the full `happy` reaction (unchanged); rapid marks
      **refresh** the pulse rather than stacking.
- [x] **Visual Review:** a good mark visibly and satisfyingly pops the dog mid-round
      (satisfies **D8** / "the mark must always feel good"); reduced-motion keeps a
      smaller cue.
- [x] `bun run test`, `bun run typecheck`, `bun run build` all pass; existing tests green.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
