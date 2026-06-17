# FEATURE: Trainer's Hand Enters Frame on Reward (Visual Presentation)

**Status**: Done
**Created**: 2026-06-15
**Completed**: 2026-06-16
**Priority**: High
**Labels**: render, dog, scene, feel, visual-review, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec **Visual Presentation**:

> A **trainer's hand** enters the frame for rewards and gestures (treat, pat).

This is currently **unimplemented** — `src/render/` has no hand/treat at all. The
hand is part of the show's feel and of "the mark must always feel good" (D8): a
reward should be *delivered*, not just tinted. Now that the dog reacts to marks
(064) this is the natural next beat — a hand offering a treat/pat on a successful
mark and a bigger gesture on mastery.

## Current State

- `src/render/scene.ts` — dog + shadow + backdrop only; `notifyMark(tier, at)`
  already exists (from 064) and fires on every PERFECT/OK mark. No hand.
- `src/main.ts` — knows successful marks and mastery (`recordMastery`).

## Desired Outcome

A simple stylized **trainer's hand** (placeholder geometry fine per D14) that
**slides into frame from the bottom/side, offers a treat or pat near the dog,
then retracts** on a successful mark — quick for a per-mark reward, a slightly
bigger/longer gesture on mastery. It never blocks reading the dog (enters from an
edge, retracts fast), and respects `prefers-reduced-motion` (shorter/smaller
travel, but still appears).

## Affected Components

### Files to Create
- `src/render/handReward.ts` + `src/render/handReward.test.ts` — a **pure**
  `handAnim(now, triggeredAt, kind, { reducedMotion }): { progress: number; t: number }`
  giving the hand's enter→hold→exit position param (0 = off-frame, peaks near the
  dog, back to 0). `kind: 'mark' | 'mastery'` sets duration/reach. **Test-first.**
- `src/render/handMesh.ts` (optional) — builds the hand/treat primitive; or build
  it inline in `scene.ts`.

### Files to Modify
- `src/render/scene.ts` — build the hand mesh (off-frame at rest); in the render
  loop drive its position from `handAnim`; expose/extend so a reward triggers it.
  Reuse `notifyMark` for the per-mark gesture; add a hook (or reuse a mastery
  signal) for the mastery gesture.
- `src/main.ts` — trigger the mastery-kind gesture on mastery.

### Dependencies
- **External**: none (Babylon primitives).
- **Internal**: 064 (`notifyMark`) — done.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions

- **Pure animation curve, visual mesh.** The enter/hold/exit timing is the testable
  unit (`handAnim`); the hand mesh + its placement is Visual-Review-only.
- **Enter from an edge, never cover the dog.** Hand rests off-frame; on trigger it
  arcs in toward the dog's head/mouth (treat) then retracts. Mastery = bigger reach
  / a pat on the head, slightly longer.
- **Reduced motion** shortens travel/duration but the hand still appears (the
  reward still reads).

### Behaviours to test (TDD, `handReward.test.ts`)

1. At rest (now far from triggeredAt, or triggeredAt null) progress is 0 (off-frame).
2. Just after trigger, progress rises (hand enters); mid-window it peaks; after the
   window it returns to 0 (retracted).
3. `kind: 'mastery'` has a larger peak reach and/or longer duration than `'mark'`.
4. Progress is continuous and returns to 0 by the end (no stuck-on-frame hand).
5. `reducedMotion` reduces peak reach/duration but keeps progress > 0 during the
   window (gesture still happens).

### Implementation Steps

1. **TDD `handReward.ts`** (behaviours 1–5).
2. **Build the hand mesh** in `scene.ts` (palm + a couple of finger boxes + a small
   treat sphere, or a simple mitt) at an off-frame rest position.
3. **Drive it** from `handAnim` each frame; trigger on `notifyMark` (mark) and on a
   mastery hook.
4. **Visual Review** — observe a mark: hand pops in with a treat near the dog and
   retracts; mastery: bigger gesture; hand never obscures the dog read.

### Risks & Considerations

- **Risk: hand covers/obscures the dog** — **Mitigation**: enter from a bottom
  corner, keep it small, retract fast; review framing in portrait.
- **Risk: feels laggy or stuck** — **Mitigation**: behaviour 4 guarantees return to
  0; tune window to ~500–800 ms (mark) / ~1–1.4 s (mastery).
- **Risk: scope creep into rigged fingers** — **Mitigation**: placeholder mitt is
  fine (D14); legibility (a hand offering a treat) is the bar, not fidelity.

## Before / After Examples

### Example 1: pure hand animation (tested)

**After** (`src/render/handReward.ts`):
```ts
export type RewardKind = 'mark' | 'mastery';
const WINDOW: Record<RewardKind, number> = { mark: 650, mastery: 1300 };
const REACH:  Record<RewardKind, number> = { mark: 1.0, mastery: 1.6 };
export function handAnim(
  now: number, triggeredAt: number | null, kind: RewardKind, opts: { reducedMotion: boolean },
): { progress: number; reach: number } {
  if (triggeredAt === null) return { progress: 0, reach: 0 };
  const t = (now - triggeredAt) / WINDOW[kind];
  if (t < 0 || t > 1) return { progress: 0, reach: 0 };
  const inOut = Math.sin(t * Math.PI);           // 0 → 1 (mid) → 0
  const amp = opts.reducedMotion ? 0.5 : 1;
  return { progress: inOut * amp, reach: REACH[kind] };
}
```

### Example 2: scene drives the hand

**After** (`src/render/scene.ts`, render loop):
```ts
const { progress, reach } = handAnim(now, lastRewardAt, lastRewardKind, { reducedMotion });
hand.position.y = HAND_REST_Y + progress * reach;   // slides up into frame toward the dog
hand.setEnabled(progress > 0.001);
```

## Code References

- `src/render/scene.ts` — `notifyMark` (064) to reuse; render loop for the hand.
- `src/main.ts` — mastery path (`recordMastery`) for the bigger gesture.
- `.docs/specs.md` "Visual Presentation" (trainer's hand), "The Dog" D8/D14.

## Progress Log

- 2026-06-15 — Task created (scan round 4, focus: dog).
- 2026-06-15 — `handReward.ts` + 9 TDD tests written; hand mesh + `notifyMastery`
  wired into `scene.ts`; `main.ts` fires the mastery gesture on `recordMastery`.
- 2026-06-16 — Visual Review (this iteration): screenshots showed the hand was
  invisible — it rested at `z=0.5` (BEHIND the dog, occluded) and shot off the top
  of the frame on mastery. Re-mapped the scene placement so the hand rises out of
  the ground IN FRONT of the dog (`z=-0.8`) to offer the treat at the muzzle, with
  the palm kept low so it never covers the head. Verified all four states from real
  frozen screenshots (mark / mastery / reduced-motion / rest). Pure `handAnim`
  unchanged.

## Resolution

Implemented in two parts:

- **`src/render/handReward.ts`** — pure `handAnim(now, triggeredAt, kind, {reducedMotion})`
  returning `{ progress, reach }` (sine enter→peak→retract; `mark` 650ms/reach 1.0,
  `mastery` 1300ms/reach 1.6; reduced-motion halves the amplitude). 9 tests
  (`handReward.test.ts`) cover rest=0, enter→peak→retract, mastery>mark reach +
  duration, return-to-0 at window end, and reduced-but-present.
- **`src/render/scene.ts`** — a placeholder mitt (palm + two fingers + a glowing
  biscuit treat) rests hidden under the ground horizon at the bottom-right, IN
  FRONT of the dog on Z. The render loop drives it from `handAnim`: it rises so the
  treat reaches the dog's muzzle on a mark, a slightly bigger hand + longer hold on
  mastery, and the palm stays low so the dog's head is never obscured. Triggered by
  `notifyMark` (mark) and the new `notifyMastery` (mastery); `main.ts` calls
  `notifyMastery` on `recordMastery`.
- A shippable `window.__notifyReward('mark'|'mastery')` dev hook (matching the
  existing `__setBreed`/`__setTrick` pattern) lets visual-review scripts fire the
  gesture without landing a real mark.

**Visual Review** (real screenshots, 390×844 portrait): mark = hand offers the
treat at the nose, head fully visible, in-frame; mastery = bigger hand at the
muzzle, head/ears/eye visible, longer hold; reduced-motion = hand+treat appear with
shorter travel; rest = no hand. Gate green: typecheck 0, 491 tests, build (no
warnings), e2e PASS.

## Acceptance Criteria

- [x] `src/render/handReward.ts` exists with a **pure** `handAnim` and
      `handReward.test.ts` written **test-first** covering: rest=0, enter→peak→
      retract, mastery bigger than mark, returns to 0, reduced-motion reduced-but-
      present.
- [x] A stylized trainer's hand (placeholder OK) enters frame on a successful mark
      offering a treat/pat near the dog and retracts; mastery gives a bigger gesture.
- [x] The hand never obscures the dog read (palm stays low so the head stays visible;
      rises from below, retracts fast); reduced motion still shows the gesture.
- [x] **Visual Review:** screenshots of the hand on a mark, on mastery, reduced-motion,
      and at rest — all confirmed in-frame with the head readable.
- [x] `bun run verify` passes (`verify ●●● ✓ typecheck + tests + build (491 tests)`);
      existing tests stay green; e2e smoke PASS.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
