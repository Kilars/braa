import type { ApexWindow } from './window'

/**
 * Outcome of a BRA tap (spec P1-5, P1-7).
 *
 * - `PERFECT` — inside the apex band, at the scoring peak.
 * - `OK`      — inside the scoring window but off-peak.
 * - `MISS`    — an active sit's window was open, but the tap fell outside it.
 *               Shown on screen (P1-7); no sound and no penalty in Phase 1.
 * - `NONE`    — nothing to mark: no window was open. The tap does nothing — no
 *               feedback, no sound, no penalty (P1-5: "a tap with no window open
 *               simply does nothing").
 *
 * There is deliberately no false-mark / penalty tier: the confuse system is out
 * of scope for Phase 1 (P1-0).
 */
export type MarkTier = 'PERFECT' | 'OK' | 'MISS' | 'NONE'

/**
 * Score a BRA tap against the currently-active sit window, or `null` when no sit
 * is active. Pure and deterministic: the same window and tap time always yield
 * the same tier. Boundaries are inclusive — a tap exactly on `open`/`close`
 * scores OK, and exactly on a peak-band edge scores PERFECT.
 */
export function scoreTap(window: ApexWindow | null, tapTime: number): MarkTier {
  if (window === null) return 'NONE'
  if (tapTime < window.open || tapTime > window.close) return 'MISS'
  if (Math.abs(tapTime - window.apex) <= window.peakRadius) return 'PERFECT'
  return 'OK'
}
