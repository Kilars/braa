# FEATURE: Mastery Dog Flourish (D8 — bigger on mastery)

**Status**: Backlog
**Created**: 2026-06-15
**Priority**: Medium
**Labels**: render, dog, animation, feel, visual-review, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec **D8 — Happy / reward**:

> On every successful mark, **and bigger on mastery**, the dog gives a clearly
> positive reaction (perk-up, bounce, tail wag).

Per-mark reactions exist (064 reward pulse). Mastery currently just enters the
sustained `happy` state (a steady bounce) — it is **not visibly "bigger"** than a
normal good mark on the dog itself. The mastery moment is the emotional peak of a
round ("SITT mastered!"); the dog should give a **distinct, bigger flourish** (a
celebratory spin + leap + fast wag) at that instant, not just keep bouncing.
The UI already celebrates (046 gold burst); this makes the **dog** celebrate.

## Current State

- `src/render/dogPose.ts` `happy` case — `bounceY` + `tailWagAngle*2`, sustained
  while `session.mastered`. Same regardless of "just mastered" vs "still happy".
- `src/main.ts` — mastery is detected (`recordMastery`), triggers the UI
  `celebrate()` and audio; no distinct on-dog flourish.

## Desired Outcome

At the **moment of mastery**, the dog does a brief, clearly bigger celebratory
**flourish** — e.g. a leap + a happy spin (yaw) + fast tail wag — that visibly
exceeds the per-mark pulse and the steady happy bounce, then settles into the
normal happy state. Reduced motion gives a smaller but still-celebratory version.

## Affected Components

### Files to Create
- `src/render/masteryFlourish.ts` + `.test.ts` — a **pure**
  `masteryFlourish(now, masteredAt, { reducedMotion }): { leapY, spinYaw, wagBoost }`
  decaying enter→peak→settle over ~1–1.4 s. **Test-first.**

### Files to Modify
- `src/render/scene.ts` — store a `masteredAt` (via a `notifyMastery(at)` method or
  by detecting the `mastered` rising edge); apply the flourish additively over the
  happy pose in the render loop.
- `src/main.ts` — call `notifyMastery(now)` on mastery.

### Dependencies
- **External**: none.
- **Internal**: 058 (poses), 064 (reward pulse pattern to mirror), 046 (UI
  celebration — complements, not duplicates).
- **Blocking**: none. Independent of 065/066.

## Technical Approach

### Architecture Decisions

- **Transient flourish layered over the sustained happy state.** `dogVisualState`
  still returns `happy` on mastery; the flourish is an additive, time-decaying
  burst keyed to `masteredAt` (mirror the 064 reward-pulse pattern). After it
  decays the dog remains in the normal happy bounce.
- **Bigger than per-mark by construction** — leap amplitude / spin clearly exceed
  the 064 pulse peak; assert this relationship if both are available, else just
  pick a visibly larger amplitude and verify in review.
- **Pure decay maths** is the tested unit; mesh application is visual.

### Behaviours to test (TDD, `masteryFlourish.test.ts`)

1. At `now===masteredAt` the flourish is at peak (`leapY`/`spinYaw` max); well past
   the window it's 0 (back to steady happy).
2. The peak `leapY` exceeds a normal happy bounce amplitude (bigger on mastery) —
   assert against the happy bounce constant or a documented threshold.
3. `masteredAt` null → all 0.
4. Flourish decays to 0 by window end (no permanent spin).
5. `reducedMotion` reduces leap/spin amplitude but keeps it > 0 at the peak.

### Implementation Steps

1. **TDD `masteryFlourish.ts`** (behaviours 1–5).
2. **Wire** `notifyMastery(now)` from main.ts → scene; apply flourish additively
   over the happy pose (`bounceY += leapY`, `bodyYaw += spinYaw`, wag boost).
3. **Visual Review** — master a trick: the dog leaps + spins celebratorily, bigger
   than a normal mark, then settles; reduced-motion smaller but present.

### Risks & Considerations

- **Risk: spin hides the face/looks broken** with the shadow — **Mitigation**: keep
  the spin a partial, quick yaw (a happy turn), not a full multi-rotation; review.
- **Risk: duplicates the 046 UI burst** — **Mitigation**: they complement (UI =
  screen confetti; this = the dog's body); both fire on mastery, by design.
- **Risk: stacks if mastery re-fires** — **Mitigation**: `notifyMastery` replaces
  `masteredAt` (refresh-not-stack), like 064.

## Before / After Examples

### Example 1: pure flourish (tested)

**After** (`src/render/masteryFlourish.ts`):
```ts
const WINDOW_MS = 1200;
export function masteryFlourish(
  now: number, masteredAt: number | null, opts: { reducedMotion: boolean },
): { leapY: number; spinYaw: number; wagBoost: number } {
  if (masteredAt === null) return { leapY: 0, spinYaw: 0, wagBoost: 0 };
  const t = (now - masteredAt) / WINDOW_MS;
  if (t < 0 || t > 1) return { leapY: 0, spinYaw: 0, wagBoost: 0 };
  const burst = Math.sin(t * Math.PI) * (1 - t * 0.3);   // strong up front, decays
  const amp = opts.reducedMotion ? 0.45 : 1;
  return { leapY: 0.4 * burst * amp, spinYaw: 0.8 * burst * amp, wagBoost: 1.5 * burst };
}
```

### Example 2: scene applies it over happy

**After** (`src/render/scene.ts`, render loop, happy state):
```ts
const f = masteryFlourish(now, masteredAt, { reducedMotion });
pose.bounceY += f.leapY;           // bigger leap than a normal mark
pose.bodyYaw = (pose.bodyYaw ?? 0) + f.spinYaw;   // happy spin
pose.tailWagAngle *= 1 + f.wagBoost;
```

## Code References

- `src/render/dogPose.ts` — `happy` case + bounce amplitude to exceed.
- `src/render/rewardPulse.ts` — the 064 transient-pulse pattern to mirror.
- `src/main.ts` — mastery detection (`recordMastery`, `celebrate()`).
- `.docs/specs.md` "The Dog" D8, "Design Principles".

## Progress Log

- 2026-06-15 — Task created (scan round 4, focus: dog).
- 2026-06-16 — Implementation complete. `masteryFlourish.ts` created; wired into `scene.ts`. 504 tests pass.
- 2026-06-16 — Visual-reviewed and moved to done.

## Resolution

Implemented pure `masteryFlourish` module with linear decay (peak at masteredAt, 0 at +1200ms),
mirroring the shipped `rewardPulse` (064) pattern. The task's sketch formula `sin(t·π)` (peak
mid-window) contradicted its own behaviour-1 ("peak at masteredAt"); resolved by using the
rewardPulse `1−t` decay-from-peak envelope, which the task explicitly says to mirror and which
makes behaviour-1 literally true. Amplitudes: leapY 0.4 (> happy bounce peak ~0.20), spinYaw 0.8
rad (a partial happy turn, face stays visible), wagBoost 1.5; reducedMotion scales leap/spin to
0.45× (still > 0 at peak).

Wired into `scene.ts`: `lastMasteryAt` state set by `notifyMastery` (refresh-not-stack), applied
additively in `updateDog` after the per-mark pulse block — `leapY` added to root Y position,
`spinYaw` added to `bodyYaw`, `wagBoost` multiplies `tailWagAngle`. `main.ts` already calls
`notifyMastery(now)` on mastery (no change needed). 8 new tests, 504 total green.

**Visual review:** fired the mastery flourish via the `__notifyReward('mastery')` dev hook (same
`notifyMastery` the real mastery path calls). Compared a mark pulse peak (calm resting dog, tiny
bounce) against the mastery peak: the dog does a pronounced celebratory body spin (~45° yaw,
left-profile → facing camera) plus a bigger pop, with the trainer's hand delivering the bigger
treat gesture — clearly larger than a normal mark. The face stayed visible (partial spin, not
broken). Settle (+450ms) and after (+1200ms past window) frames confirmed the flourish decays and
the dog returns to its normal pose — transient, no permanent spin. The on-screen leap partly
coincides with the yaw, but its amplitude (> happy bounce) is unit-test-verified; reduced-motion
dampening is guaranteed by the passing test. `bun run verify`:
`verify ●●●  ✓ typecheck + tests + build  (504 tests)`.

## Acceptance Criteria

- [x] `src/render/masteryFlourish.ts` exists with a **pure** decay function and a
      **test-first** suite covering: peak at masteredAt / 0 after window, bigger than
      a normal happy bounce, null→0, decays to 0, reduced-motion reduced-but-present.
- [x] On mastery the dog does a distinct, **bigger** flourish (leap + happy spin +
      fast wag) layered over the happy state, then settles; refresh-not-stack.
- [x] The spin stays partial/quick (doesn't hide the face or look broken).
- [x] **Visual Review:** mastering a trick visibly pops the dog bigger than a normal
      mark; reduced-motion smaller but present (D8/D13).
- [x] `bun run verify` passes (report the summary line); existing tests stay green.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
