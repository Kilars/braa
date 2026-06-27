import { NORMAL_TUNING, type MarkTuning } from './tuning'

/**
 * The markable window of a single sit: when scoring opens and closes, and where
 * the honest scoring peak (the apex) sits inside it. The PERFECT band is
 * centered on `apex`, never slightly before or after it (spec P1-4 — the apex
 * tell marks the *actual* scoring peak).
 *
 * All fields are timeline milliseconds on one shared clock (e.g.
 * `performance.now()`). The render/scheduler layer decides *when* a sit is
 * active and hands the active window (or `null`) to `scoreTap`.
 */
export interface ApexWindow {
  /** Earliest tap time (ms) that scores — the scoring window opens. */
  open: number
  /** The actual scoring peak (ms); the PERFECT band is centered here. */
  apex: number
  /** Latest tap time (ms) that scores — the scoring window closes. */
  close: number
  /** Half-width (ms) of the PERFECT sub-band around `apex`. */
  peakRadius: number
}

/**
 * Build the scoring window for a sit whose apex peaks at `apexTime`. open/close
 * straddle the apex by half the tuned window width, so the peak is honestly in
 * the middle. Defaults to NORMAL tuning (the only Phase-1 mode).
 */
export function windowAtApex(
  apexTime: number,
  tuning: MarkTuning = NORMAL_TUNING,
): ApexWindow {
  const halfWidth = tuning.windowWidthMs / 2
  return {
    open: apexTime - halfWidth,
    apex: apexTime,
    close: apexTime + halfWidth,
    peakRadius: tuning.peakRadiusMs,
  }
}
