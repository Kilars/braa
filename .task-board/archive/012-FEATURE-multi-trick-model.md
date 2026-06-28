# FEATURE: Multi-trick model — generalize the Sitt-only brain into a trick registry (Phase-2 foundation)

**Status**: Done (2026-06-27)
**Created**: 2026-06-27
**Priority**: P0 — Phase-2 blocking foundation (everything else in Phase 2 depends on it)
**Labels**: phase-2, architecture, game-logic, tdd
**Estimated Effort**: Medium

## Context & Motivation

Phase 1 is signed off. The current phase is **Phase 2 — "More tricks, same quality
bar"** (`specs2.md` §Phase 2). A scan found **all six Phase-2 stories Missing**, and the
gap analysis is unambiguous: there is **no trick abstraction anywhere** — "Sitt" is the
entire model, hardcoded end to end:

- `src/core/sitCycle.ts` — the timing brain is Sitt-specific (`SIT_TIMINGS`, `SitState`,
  `SitPhase`, `sitStateAt`).
- `src/render/scene.ts:96-102` — the scene hardwires `SIT_TIMINGS` + `sitStateAt`.
- `src/render/dog.ts:251` — `pose(sitAmount, …)` draws only the sit.

Every other Phase-2 story needs tricks to *exist as data* first: **P2-1** (selector) needs
a trick list to choose from, **P2-2** (per-trick animations) needs a per-trick pose
contract, **P2-4** (learned bar) needs trick IDs as keys, **P2-5** (persistence) needs
trick IDs as save keys. This task builds **only that seam** — the smallest model that lets
the dog perform more than one trick — and is deliberately scoped to leave the *second
animation* (Ligg) to task 013 and the *selector UI* to task 014.

This is **game-logic → test-first** (`tdd` skill, `.claude/skills/tdd/SKILL.md`).

## Desired Outcome

A trick-agnostic timing model with a registry of `TrickDef`s. The scene drives the dog and
the scoring window from an **active trick** and exposes `setTrick(id)` to swap it. **Sitt's
behavior is byte-identical to today** (a regression guard test proves it) — this is pure
generalization, no feel change. After this task the dog still only *animates* Sitt
visually, but the model can carry any number of tricks for 013/014 to light up.

## Affected Components

### Files to Add
- `src/core/trick.ts` — `TrickId`, `TrickDef`, the `TRICKS` registry, `getTrick(id)`.
- `src/core/trick.test.ts` — registry + lookup invariants (TDD, red first).

### Files to Modify
- `src/core/sitCycle.ts` — generalize: keep the IDLE→BUILD→HOLD→RELEASE math (it is
  generic to any static-pose trick), but make the timings come from a `TrickDef`. Keep
  `SIT_TIMINGS` exported (it becomes Sitt's entry) so nothing else breaks.
- `src/core/sitCycle.test.ts` — add the "Sitt unchanged" regression assertion.
- `src/render/scene.ts` — hold an `activeTrickId`, read its timings, add `setTrick(id)` to
  `SceneHandle`; `activeWindowAt`/`stateAt`/the render loop read the active trick's timings.
- `src/main.ts` — expose a `window.__braSetTrick?(id)` probe + `window.__braTricks?()` so
  e2e/selector can switch deterministically (mirrors the existing `__bra*` probes).

### Files to Check (must stay honest)
- `src/core/window.ts` — already parametric on tuning; confirm it stays trick-agnostic
  (the window is built from `apexTime`, which every trick produces).
- `src/render/dog.ts` — **not** changed here; the pose stays sit-only until task 013.
  Document in the `TrickDef` a `poseKind` field 013 will switch on.

## Technical Approach (TDD — write the registry + regression tests first)

### Before — Sitt is the only model (scene.ts:96-102)
```ts
import { sitStateAt, SIT_TIMINGS, type SitState } from '../core/sitCycle'
// ...
const activeWindowAt = (now: number) => {
  const st = sitStateAt(startTime, now, SIT_TIMINGS)
  return st.phase === 'IDLE' ? null : windowAtApex(st.apexTime)
}
```

### After — a trick registry; the scene reads the active trick
```ts
// src/core/trick.ts  (NEW)
import type { SitTimings } from './sitCycle'

export type TrickId = 'sitt' | 'ligg' // extend as tricks are added (013+)

/** How the dog should be drawn at the apex — switched on in dog.ts (task 013). */
export type PoseKind = 'sit' | 'liedown'

export interface TrickDef {
  id: TrickId
  /** Norwegian command shown in the UI selector (task 014). */
  label: string
  /** Per-trick cadence (reuses the SitTimings shape — generic to static poses). */
  timings: SitTimings
  /** Which pose the renderer draws for this trick (task 013 wires this in dog.ts). */
  poseKind: PoseKind
}

// Sitt keeps EXACTLY today's timings — no feel change (SIT_TIMINGS unchanged).
export const TRICKS: readonly TrickDef[] = [
  { id: 'sitt', label: 'Sitt', timings: SIT_TIMINGS, poseKind: 'sit' },
  // 'ligg' is added by task 013 (its timings + a distinct liedown pose).
]

export function getTrick(id: TrickId): TrickDef {
  const t = TRICKS.find((x) => x.id === id)
  if (!t) throw new Error(`Unknown trick: ${id}`)
  return t
}
```
```ts
// scene.ts — parametric by the active trick
let activeTrick = getTrick('sitt')
const activeWindowAt = (now: number) => {
  const st = sitStateAt(startTime, now, activeTrick.timings)
  return st.phase === 'IDLE' ? null : windowAtApex(st.apexTime)
}
// ...SceneHandle gains:
setTrick(id: TrickId) { activeTrick = getTrick(id) }
```

### Tests to write first (red → green)
```ts
// trick.test.ts
it('registry has Sitt and lookups round-trip', () => {
  expect(getTrick('sitt').label).toBe('Sitt')
  expect(getTrick('sitt').poseKind).toBe('sit')
})
it('getTrick throws on an unknown id', () => {
  expect(() => getTrick('nope' as TrickId)).toThrow()
})

// sitCycle.test.ts — Sitt is byte-identical after generalization
it('Sitt timings/state are unchanged by the trick generalization', () => {
  const t = getTrick('sitt').timings
  expect(t).toEqual(SIT_TIMINGS)
  // sample the cycle; state must match sitStateAt(..., SIT_TIMINGS) exactly
  for (let now = 0; now < sitPeriodMs(SIT_TIMINGS); now += 37) {
    expect(sitStateAt(0, now, t)).toEqual(sitStateAt(0, now, SIT_TIMINGS))
  }
})
```

## Risks & Considerations
- **Scope discipline.** Do NOT add the Ligg animation or the selector UI here — only the
  model + the seam. The dog renders the sit for every trick until task 013. Note this
  limitation in the completion notes so 013/014 pick it up.
- **Don't regress Sitt.** The whole point is zero feel change; the regression test is the
  contract. Keep `SIT_TIMINGS`, `SitState`, `sitAmount`, `sitStateAt` exports intact (alias
  if you rename) so scene/dog/capture harness and the e2e probes keep working.
- **Naming.** `sitAmount` is now a generic 0→1 "pose build amount"; you may keep the name
  to avoid churn, but document that it is trick-generic. Avoid renaming public symbols the
  e2e probes (`__braPose`, `__braPhase`) depend on.
- **Window/tell honesty unchanged.** The apex tell + `scoreTap` still derive from the
  active trick's `apexTime`; confirm the tell stays dark in IDLE for any trick.

## Acceptance Criteria
- [x] `src/core/trick.ts` adds `TrickId`, `PoseKind`, `TrickDef`, `TRICKS` (Sitt entry),
      and `getTrick(id)`; `trick.test.ts` covers lookup + unknown-id throw (red first).
- [x] `sitCycle`/`scene` are parametric by the active trick's timings; `SceneHandle.setTrick(id)`
      swaps the trick and the dog/scoring follow it.
- [x] **Sitt is byte-identical** to before — regression test passes (state sampled across a
      full cycle equals `sitStateAt(..., SIT_TIMINGS)`), and the running app's sit looks/scores
      unchanged.
- [x] `window.__braSetTrick(id)` and `window.__braTricks()` probes exposed in `main.ts`
      (deterministic switching for e2e + task 014), mirroring the existing `__bra*` probes.
- [x] `poseKind` is carried on each `TrickDef` (consumed by task 013) — documented, not yet
      switched on in `dog.ts`.
- [x] TDD followed (failing tests first), and the discrepancy note records that the second
      animation (013) + selector (014) are deliberately out of this task's scope.
- [x] Verify gate green: `typecheck` · `test` · `build` · `e2e`.

## Resolution (2026-06-27)

Built the trick **model + seam only**, leaving the second animation (013) and the selector
(014) out of scope by design.

**What changed**
- **New `src/core/trick.ts`** — `TrickId`, `PoseKind` (`'sit' | 'liedown'`), `TrickDef`
  (`id`, `label`, `timings`, `poseKind`), the `TRICKS` registry (Sitt only, reusing
  `SIT_TIMINGS` verbatim), and `getTrick(id)` (throws on unknown). Depends only on the leaf
  `sitCycle` timing types — `sitCycle` never imports back, so **no import cycle** and the
  registry is pure/unit-testable.
- **`src/render/scene.ts`** — holds `let activeTrick = getTrick('sitt')`; `activeWindowAt`,
  `stateAt`, and the render loop now read `activeTrick.timings` instead of the hardcoded
  `SIT_TIMINGS`. Added `SceneHandle.setTrick(id)` (both the live and the no-GPU handle).
  `poseFreezeTime` gained an optional `timings` param (default `SIT_TIMINGS`) and the
  capture probes pass `activeTrick.timings`, so 013's Ligg capture frames will be honest.
- **`src/main.ts`** — exposed `window.__braTricks()` and `window.__braSetTrick(id)` probes,
  mirroring the existing `__bra*` set, for the selector (014) + deterministic e2e.

**TDD.** Red first: `trick.test.ts` failed to resolve `./trick` (module absent), then went
green after `trick.ts`. The byte-identical regression test (state sampled every 37 ms across
a full cycle equals `sitStateAt(..., SIT_TIMINGS)`) was green from the first run — confirming
the generalization changed no Sitt feel. 5 new tests (44 → 49).

**Discrepancy vs. the task's illustrative snippet (recorded per the rules):** the task draft
wrote `TrickId = 'sitt' | 'ligg'`, but Ligg's *registry entry* doesn't exist until 013. A
union member with no registry entry would let `getTrick('ligg')` typecheck yet throw at
runtime — a phantom. Chose **`TrickId = 'sitt'`** so the type and the registry stay in sync;
**task 013 widens the union to `'sitt' | 'ligg'` in the same edit that appends the entry.**
The unknown-id throw is still covered (the test casts a bogus string).

**Deliberately out of scope (handed to 013/014):** `dog.ts` is untouched — the dog still
*animates* the sit for the (only) active trick; `poseKind` is carried but not yet switched
on. 013 adds the Ligg entry + the `'liedown'` pose branch; 014 adds the player-facing chip
selector that drives `setTrick`.

**Gate:** `typecheck` 0 · `test` 49 passed · `build` no warnings (chunk limit configured,
tech-decisions §1) · `e2e` 5 passed.
