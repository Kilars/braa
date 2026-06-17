const WINDOW_MS = 1200;

/**
 * Pure decay flourish keyed to masteredAt.
 *
 * Returns additive offsets to layer over the sustained happy state at the
 * moment a trick is mastered. Bigger than both the per-mark reward pulse
 * (064) and the steady happy bounce:
 *   - peak leapY 0.4 > happy bounce peak (~0.20)
 *   - spinYaw 0.8 rad — a happy turn, not a multi-rotation (keeps face visible)
 *   - wagBoost 1.5 — rapid tail wag during the flourish
 *
 * Decay is simple linear: peak at t=0 (masteredAt), 0 at t=1 (WINDOW_MS later).
 * This mirrors the rewardPulse pattern (064) but with bigger amplitudes and a
 * longer window (1200ms vs 500ms).
 *
 * No Babylon imports — pure math, fully testable.
 */
export function masteryFlourish(
  now: number,
  masteredAt: number | null,
  opts: { reducedMotion: boolean },
): { leapY: number; spinYaw: number; wagBoost: number } {
  if (masteredAt === null) return { leapY: 0, spinYaw: 0, wagBoost: 0 };
  const t = (now - masteredAt) / WINDOW_MS;
  if (t < 0 || t > 1) return { leapY: 0, spinYaw: 0, wagBoost: 0 };
  const decay = 1 - t;                       // peak at t=0 (masteredAt), 0 at t=1 — mirrors rewardPulse
  const amp = opts.reducedMotion ? 0.45 : 1; // reduced but present
  return { leapY: 0.4 * decay * amp, spinYaw: 0.8 * decay * amp, wagBoost: 1.5 * decay };
}
