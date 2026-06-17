export type RewardKind = 'mark' | 'mastery';

const WINDOW_MS: Record<RewardKind, number> = { mark: 650, mastery: 1300 };
const REACH: Record<RewardKind, number> = { mark: 1.0, mastery: 1.6 };

/**
 * Pure animation curve for the trainer's hand entering/retracting on a reward.
 *
 * - progress: 0..1, 0 = hand off-frame, peaks mid-window near 1, returns to 0.
 * - reach: how far the hand extends toward the dog (kind-dependent).
 * - No Babylon imports — pure math, fully testable.
 */
export function handAnim(
  now: number,
  triggeredAt: number | null,
  kind: RewardKind,
  opts: { reducedMotion: boolean },
): { progress: number; reach: number } {
  if (triggeredAt === null) return { progress: 0, reach: 0 };
  const t = (now - triggeredAt) / WINDOW_MS[kind];
  if (t < 0 || t >= 1) return { progress: 0, reach: 0 };
  const inOut = Math.sin(t * Math.PI); // 0 → 1 (mid) → 0
  const amp = opts.reducedMotion ? 0.5 : 1;
  return { progress: inOut * amp, reach: REACH[kind] };
}
