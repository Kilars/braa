/**
 * Phase-1 timing tunables — a single named table, never magic numbers at the
 * call sites (task 002 acceptance).
 *
 * The values are the deprecated game's audited NORMAL-difficulty constants
 * (tech-decisions §8, table 7c) carried forward as a Phase-1 *reference, not a
 * binding*: a 400 ms scoring window with an 80 ms PERFECT sub-band, both
 * centered on the apex. Phase 1 ships a single difficulty (P1-0); the tighter
 * HARD/EXPERT tables from §8 are a later phase, so only NORMAL lives here for now.
 *
 * This module imports nothing from `src/core/*` — it is a leaf, so domain
 * modules can depend on it without a cycle.
 */
export interface MarkTuning {
  /** Full width (ms) of the scoring window; a tap inside scores OK or better. */
  windowWidthMs: number
  /** Half-width (ms) of the PERFECT sub-band, centered on the apex. */
  peakRadiusMs: number
}

/** NORMAL difficulty — the only mode in Phase 1 (spec P1-0). */
export const NORMAL_TUNING: MarkTuning = {
  windowWidthMs: 400,
  peakRadiusMs: 80,
}
