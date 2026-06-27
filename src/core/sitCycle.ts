/**
 * The Phase-1 sit loop as pure, deterministic timing — the brain behind the
 * dog's animation and the honest apex window. The renderer reads a `SitState`
 * each frame to pose the dog; the scoring layer turns `apexTime` into an
 * `ApexWindow` (`windowAtApex`) so the apex *tell* and `scoreTap` land on the
 * exact same instant the dog is fully seated (spec P1-3, P1-4).
 *
 * One cycle is: IDLE (alive but standing) → BUILD (lowering into the sit) →
 * HOLD (fully seated — the apex plateau) → RELEASE (standing back up) → repeat,
 * forever, without degrading (P1-9). The cycle is a function of wall-clock time
 * on a single shared clock, so it never accumulates drift.
 *
 * Imports only the leaf tuning types — no Babylon, no DOM — so it is unit
 * testable and the render layer can depend on it freely (no cycle).
 */

/** Durations (ms) of the four phases of one sit cycle. */
export interface SitTimings {
  /** Standing, alive-but-calm, before the sit begins. */
  idleMs: number
  /** Lowering from standing into the fully-seated apex. */
  buildMs: number
  /** Held fully seated — the apex plateau the player marks. */
  holdMs: number
  /** Standing back up from the seat to idle. */
  releaseMs: number
}

/** Where the dog is in the loop right now. */
export type SitPhase = 'IDLE' | 'BUILD' | 'HOLD' | 'RELEASE'

export interface SitState {
  /** Which phase the current moment falls in. */
  phase: SitPhase
  /**
   * Eased pose value: 0 = standing/idle, 1 = fully seated. Smooth (smoothstep)
   * across BUILD and RELEASE and flat at 1 through HOLD, so the renderer never
   * snaps between poses (P1-2/P1-3: no T-pose, no jitter).
   */
  sitAmount: number
  /** Absolute time (ms) of this cycle's fully-seated instant — the apex. */
  apexTime: number
  /** 0-based index of the current cycle since `startTime`. */
  cycleIndex: number
}

/**
 * Phase-1 sit cadence. Tuned for legibility on a phone: a calm idle beat, an
 * unhurried ~0.7 s build so the apex is readable, a brief seated hold the player
 * aims at, and an easy stand-up. A single named table — no magic numbers at the
 * call sites (the task-002 discipline, carried forward).
 */
export const SIT_TIMINGS: SitTimings = {
  idleMs: 1600,
  buildMs: 700,
  // The held plateau must not outlive the scoring window, or the dog "looks
  // seated" while a tap scores an unfair MISS and the tell is dark (PO Review
  // C1). The NORMAL window is windowWidthMs/2 = 200 ms each side of the apex, so
  // the hold is trimmed to 200 ms: the dog begins standing back up exactly as the
  // window closes — "looks seated" == "is markable", PERFECT still on the apex.
  holdMs: 200,
  releaseMs: 700,
}

/** Total duration (ms) of one full sit cycle. */
export function sitPeriodMs(t: SitTimings): number {
  return t.idleMs + t.buildMs + t.holdMs + t.releaseMs
}

/** Smoothstep: eased 0→1 with zero slope at both ends (no velocity snap). */
function smoothstep(x: number): number {
  const c = x < 0 ? 0 : x > 1 ? 1 : x
  return c * c * (3 - 2 * c)
}

/**
 * Resolve the dog's sit state at wall-clock `now`, for a loop that began its
 * first idle at `startTime`. Pure and deterministic. Times before `startTime`
 * clamp to the first cycle's idle (defensive; should not happen in practice).
 */
export function sitStateAt(
  startTime: number,
  now: number,
  t: SitTimings = SIT_TIMINGS,
): SitState {
  const period = sitPeriodMs(t)
  const elapsed = Math.max(0, now - startTime)
  const cycleIndex = Math.floor(elapsed / period)
  const cycleStart = startTime + cycleIndex * period
  const into = elapsed - cycleIndex * period

  // Apex is the instant the dog becomes fully seated: end of BUILD.
  const apexTime = cycleStart + t.idleMs + t.buildMs

  const buildEnd = t.idleMs + t.buildMs
  const holdEnd = buildEnd + t.holdMs

  let phase: SitPhase
  let sitAmount: number
  if (into < t.idleMs) {
    phase = 'IDLE'
    sitAmount = 0
  } else if (into < buildEnd) {
    phase = 'BUILD'
    sitAmount = smoothstep((into - t.idleMs) / t.buildMs)
  } else if (into < holdEnd) {
    phase = 'HOLD'
    sitAmount = 1
  } else {
    phase = 'RELEASE'
    sitAmount = smoothstep(1 - (into - holdEnd) / t.releaseMs)
  }

  return { phase, sitAmount, apexTime, cycleIndex }
}
