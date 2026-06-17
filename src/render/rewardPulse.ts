import type { MarkResult } from '../core/mark';

const WINDOW_MS = 500;

const PEAK: Record<MarkResult, number> = {
  PERFECT: 1,
  OK: 0.55,
  MISS: 0,
  FALSE_MARK: 0,
};

/**
 * Pure decay function: given the current time, the time of the last successful
 * mark, and its tier, returns a 0..1 pulse intensity.
 *
 * - At now===markAt the pulse is at the tier's peak.
 * - The pulse decays monotonically to 0 over WINDOW_MS (~500ms).
 * - MISS/FALSE_MARK always return 0.
 * - markAt===null returns 0.
 * - reducedMotion scales the amplitude down but keeps it > 0 at markAt.
 *
 * No Babylon imports — pure math, fully testable.
 */
export function rewardPulse(
  now: number,
  markAt: number | null,
  tier: MarkResult,
  opts: { reducedMotion: boolean },
): number {
  if (markAt === null) return 0;
  const t = (now - markAt) / WINDOW_MS;
  if (t < 0 || t > 1) return 0;
  const decay = 1 - t;
  const amp = opts.reducedMotion ? 0.4 : 1;
  return PEAK[tier] * decay * amp;
}
