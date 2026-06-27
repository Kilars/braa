/**
 * The Phase-2 trick model. Phase 1 hardcoded a single trick ("Sitt") end to end;
 * Phase 2 ("more tricks, same quality bar") needs tricks to exist as *data* so a
 * selector can list them (P2-1), the renderer can pose each one distinctly
 * (P2-2), and later stories can key progress/persistence off them (P2-4/P2-5).
 *
 * This module is that seam — and only that seam. It generalizes the timing brain
 * (`sitCycle.ts`, whose IDLE→BUILD→HOLD→RELEASE math is generic to any
 * static-pose trick) into a registry of `TrickDef`s, each carrying its own
 * cadence and a `poseKind` the renderer switches on. Sitt's entry reuses the
 * shipped `SIT_TIMINGS` verbatim, so this generalization changes no feel.
 *
 * Depends only on the leaf timing types (no Babylon, no DOM) — sitCycle never
 * imports back, so there is no cycle and the registry stays unit-testable.
 */

import { SIT_TIMINGS, type SitTimings } from './sitCycle'

/**
 * A trick the dog can perform. Widened as tricks are added — task 013 adds
 * `'ligg'` alongside its registry entry, so the union never names a trick the
 * registry doesn't have.
 */
export type TrickId = 'sitt' | 'ligg'

/**
 * Which pose the renderer should draw for a trick. `dog.pose()` switches on this
 * (task 013); Phase 1 only ever drew `'sit'`.
 */
export type PoseKind = 'sit' | 'liedown'

export interface TrickDef {
  /** Stable id — also the key for progress/persistence in later Phase-2 work. */
  id: TrickId
  /** Norwegian command shown in the trick selector (task 014). */
  label: string
  /** Per-trick cadence. Reuses the SitTimings shape — generic to static poses. */
  timings: SitTimings
  /** How the renderer draws the apex pose for this trick (consumed by task 013). */
  poseKind: PoseKind
}

/**
 * The known tricks. Sitt reuses the shipped `SIT_TIMINGS` exactly (byte-identical
 * Phase-1 feel). Ligg (lie down) is the first expansion trick — its own cadence
 * and a distinct `'liedown'` pose (task 013).
 *
 * Ligg's cadence: a slightly longer ~0.8 s build than Sitt's 0.7 s reads as a
 * deliberate *lowering* into the down, and an easy stand-up back to idle. The
 * held fully-down plateau is the same 200 ms as Sitt's — it must not outlive the
 * scoring window (NORMAL `windowWidthMs/2` = 200 ms each side of the apex), or
 * the dog would "look down" while a tap scores an unfair MISS (the PO C1 / task
 * 007 invariant, carried forward to every trick).
 */
export const TRICKS: readonly TrickDef[] = [
  { id: 'sitt', label: 'Sitt', timings: SIT_TIMINGS, poseKind: 'sit' },
  {
    id: 'ligg',
    label: 'Ligg',
    timings: { idleMs: 1600, buildMs: 800, holdMs: 200, releaseMs: 800 },
    poseKind: 'liedown',
  },
]

/** Look up a trick by id; throws on an unknown id so we never silently mis-pose. */
export function getTrick(id: TrickId): TrickDef {
  const trick = TRICKS.find((t) => t.id === id)
  if (!trick) throw new Error(`Unknown trick: ${id}`)
  return trick
}
