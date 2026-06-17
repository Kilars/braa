import type { MarkResult } from './mark';

export function comboAfter(combo: number, result: MarkResult): number {
  if (result === 'PERFECT' || result === 'OK') return combo + 1;
  return 0;
}

/** 1 at combo 0/1; rises by 0.1 per step above 1; capped at 2. */
export function comboMultiplier(combo: number): number {
  return Math.min(2, 1 + 0.1 * Math.max(0, combo - 1));
}
