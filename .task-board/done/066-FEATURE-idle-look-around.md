# FEATURE: Idle Look-Around (D4 — the dog is alive, never frozen)

**Status**: Backlog
**Created**: 2026-06-15
**Priority**: Medium
**Labels**: render, dog, animation, visual-review, tdd
**Estimated Effort**: Simple

## Context & Motivation

Spec **D4 — Idle**:

> With nothing being offered, the dog looks alive but calm — ambient motion
> (breathing, **the odd tail wag / look-around**). It is never frozen.

Today the idle pose has **breathing + a constant tail wag** only (`dogPose.ts`
idle case). There's no **look-around** — the dog stares straight ahead forever,
which reads slightly lifeless during the (frequent) idle gaps between attempts.
Adding an occasional head turn / weight shift makes the dog feel alive — cheap,
high-felt-quality.

## Current State

`src/render/dogPose.ts` idle case:
```ts
case "idle":
  return { ...zero, breatheScaleY: 1 + Math.sin(now*0.003)*0.03*m, tailWagAngle: wag };
```
No head yaw / look-around channel. `DogPose` has `headTiltZ`/`headPitch` but no
`headYaw`; `dogMesh.applyPose` drives the `headPivot`.

## Desired Outcome

During idle the dog occasionally **looks around** — a slow head yaw that drifts to
one side, holds, returns, with quiet stretches in between (not a constant
metronome) — plus the existing breathing/wag. Subtle and calm, never twitchy.
Reduced motion dampens the amplitude but the dog still isn't a statue (a tiny
drift remains).

## Affected Components

### Files to Modify
- `src/render/dogPose.ts` + `dogPose.test.ts` — add a `headYaw` channel and an
  idle look-around term (a slow, occasionally-active yaw over `now`). **Test-first.**
- `src/render/dogMesh.ts` — apply `headYaw` to the `headPivot` (rotation.y).

### Dependencies
- **External**: none.
- **Internal**: 058 (`dogPose`, `headPivot`) — done.
- **Blocking**: none. Independent of 065/067.

## Technical Approach

### Architecture Decisions

- **Deterministic, time-based "occasional" motion** — no RNG (keeps `dogPose`
  pure/testable). Use a low-frequency wave with a shaped envelope so the yaw is
  near-zero most of the time and drifts out periodically (e.g. a slow sine raised
  to a power, or product of two slow waves) to read as "looks around now and
  then" rather than a constant sweep.
- **Only affects idle.** Other states are untouched (offering/confused/etc. already
  own the head).

### Behaviours to test (TDD, `dogPose.test.ts` additions)

1. idle `headYaw` is **non-zero at some times and ~zero at others** (occasional,
   not constant) — sample a few `now` values and assert both a near-zero and a
   clearly non-zero occur.
2. idle `headYaw` stays within a calm bound (|yaw| ≤ a small max) — never a wild
   spin.
3. `reducedMotion` reduces the idle look-around amplitude vs non-reduced (compare
   peaks) but keeps breathing/idle non-frozen.
4. Non-idle states return `headYaw` 0 (unchanged) — look-around doesn't leak.

### Implementation Steps

1. **TDD** the `headYaw` idle term (behaviours 1–4).
2. **Apply** `headYaw` in `dogMesh.applyPose` (headPivot.rotation.y).
3. **Visual Review** — observe idle for a few seconds: the dog calmly looks around
   and returns, breathing throughout; reduced-motion still has faint life.

### Risks & Considerations

- **Risk: looks twitchy/robotic** (constant sweep) — **Mitigation**: shaped
  envelope so it's mostly still with occasional drift; keep amplitude small and
  frequency low.
- **Risk: fights offering head motion** — **Mitigation**: gate the term to the idle
  case only.

## Before / After Examples

### Example 1: idle look-around (tested)

**Before** (`src/render/dogPose.ts`):
```ts
case "idle":
  return { ...zero, breatheScaleY: 1 + Math.sin(now*0.003)*0.03*m, tailWagAngle: wag };
```

**After**:
```ts
case "idle": {
  // occasional slow look-around: mostly ~0, drifts out periodically (no RNG, pure)
  const env = Math.pow(Math.max(0, Math.sin(now * 0.00037)), 3); // long quiet gaps
  const headYaw = Math.sin(now * 0.0016) * 0.35 * env * m;       // calm bounded drift
  return { ...zero, breatheScaleY: 1 + Math.sin(now*0.003)*0.03*m, tailWagAngle: wag, headYaw };
}
```

### Example 2: mesh applies headYaw

**After** (`src/render/dogMesh.ts`, in `applyPose`):
```ts
headPivot.rotation.y = pose.headYaw ?? 0;   // look-around
```

## Code References

- `src/render/dogPose.ts` — idle case + `DogPose` interface (add `headYaw?`).
- `src/render/dogMesh.ts` — `applyPose` / `headPivot`.
- `.docs/specs.md` "The Dog" D4, D13.

## Progress Log

- 2026-06-15 — Task created (scan round 4, focus: dog).
- 2026-06-16 — Implemented test-first (TDD) + visual-reviewed; moved to done.

## Resolution

Added a pure, deterministic idle look-around to `dogPose`:

- `DogPose` gained `headYaw?: number` (head Y-rotation, idle-only).
- The `idle` case now adds a shaped, RNG-free yaw term:
  `env = pow(max(0, sin(now*0.00037)), 3)` (long quiet gaps, ~17s period) times
  `sin(now*0.0016) * 0.35 * m`, so the head drifts out to both sides and returns
  to centre, near-zero most of the time. `m` (0.15 under reducedMotion) dampens
  the amplitude without freezing the dog.
- `dogMesh.applyPose` maps `headYaw → headPivot.rotation.y` next to the existing
  tilt/pitch lines; no other state sets `headYaw` (it stays 0).

**Tests (test-first, `dogPose.test.ts`):** occasional-not-constant (max |yaw| > 0.1
yet some samples ~0), bounded (|yaw| ≤ 0.6), reduced-motion peak < full-motion peak
while breathing still varies, and no leak (non-idle states return headYaw 0). All
496 tests green.

**Visual review:** captured confirmed-idle frames (state polled `idle` before *and*
after each shot) across one env cycle. At now≈3563ms the head was turned ~−10°, at
≈5486ms ~+9° (the other side), and at ≈9496ms (env≈0) it returned to straight —
calm look-around to both sides and back, breathing/tail throughout, no twitch. The
warm head-up offering frames were confirmed unaffected (no leak). `bun run verify`:
`verify ●●●  ✓ typecheck + tests + build  (496 tests)`.

## Acceptance Criteria

- [x] `DogPose` gains a `headYaw?` channel; idle produces an **occasional** calm
      look-around (non-zero sometimes, ~zero often), bounded small.
- [x] Tests written **test-first** cover: occasional-not-constant, bounded, reduced-
      motion dampened-not-frozen, non-idle states unaffected.
- [x] `dogMesh.applyPose` applies `headYaw` to the head pivot.
- [x] **Visual Review:** idle dog calmly looks around and returns, breathing
      throughout; reduced-motion keeps faint life (D4/D13).
- [x] `bun run verify` passes (report the summary line); existing tests stay green.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
