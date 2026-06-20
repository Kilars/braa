import type { MarkResult } from './mark';

/**
 * The engagement meter is a 0..1 scalar describing how eager the dog is.
 * 1 = fully eager / on-task; 0 = "done with you" (walked off). Spec: §Mistakes →
 * "Wrong-behavior beats & disengagement" — good timing keeps it eager; sloppy/false
 * marks or slow rewards drain it. Pure logic only (no Babylon).
 */

/** A fresh round starts with an eager dog. */
export const ENGAGEMENT_FULL = 1;
export const ENGAGEMENT_EMPTY = 0;

export type EngagementEvent =
  | { kind: 'mark'; result: MarkResult }
  | { kind: 'reward'; latencyMs: number };

/** Per-mark engagement deltas (Normal). Good timing refills; sloppy/false marks drain. */
export const MARK_ENGAGEMENT_DELTA: Record<MarkResult, number> = {
  PERFECT: 0.15,
  OK: 0.08,
  MISS: -0.06,
  FALSE_MARK: -0.2,
};

/** Reward-latency response: a snappy reward keeps the dog eager; a slow one bores it. */
export const REWARD_SNAPPY_MS = 800; // at/under → max refill
export const REWARD_SLOW_MS = 2400; // at/over → max drain
export const REWARD_SNAPPY_REFILL = 0.05;
export const REWARD_SLOW_DRAIN = -0.15;

function rewardLatencyDelta(latencyMs: number): number {
  if (latencyMs <= REWARD_SNAPPY_MS) return REWARD_SNAPPY_REFILL;
  if (latencyMs >= REWARD_SLOW_MS) return REWARD_SLOW_DRAIN;
  const t = (latencyMs - REWARD_SNAPPY_MS) / (REWARD_SLOW_MS - REWARD_SNAPPY_MS);
  return REWARD_SNAPPY_REFILL + t * (REWARD_SLOW_DRAIN - REWARD_SNAPPY_REFILL);
}

/**
 * The reward latency for a successful mark: how long after the behavior's apex the
 * player rewarded it. Clamped at 0 — a tap that pre-empts the apex is "instant", not
 * negative. Feeds the `{ kind:'reward', latencyMs }` event so the live loop can express
 * "slow rewards drain it" (spec §Mistakes) using only timing — no dog clips needed.
 */
export function rewardLatencyMs(tapTime: number, apexTime: number): number {
  return Math.max(0, tapTime - apexTime);
}

const clamp01 = (n: number): number => Math.max(0, Math.min(1, n));

export function engagement(prev: number, event: EngagementEvent): number {
  const delta =
    event.kind === 'mark' ? MARK_ENGAGEMENT_DELTA[event.result] : rewardLatencyDelta(event.latencyMs);
  return clamp01(prev + delta);
}

/**
 * The escalating off-task beat the meter currently warrants. As engagement drops:
 *   engaged → itch → flop → bark → walk-off
 * (spec §Mistakes: graded so it stays funny, never punishing).
 */
export type DisengageBeat = 'engaged' | 'itch' | 'flop' | 'bark' | 'walk-off';

export function disengageBeat(level: number): DisengageBeat {
  if (level <= 0) return 'walk-off';
  if (level < 0.25) return 'bark';
  if (level < 0.5) return 'flop';
  if (level < 0.75) return 'itch';
  return 'engaged';
}
