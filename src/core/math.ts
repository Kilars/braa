/**
 * Small pure numeric helpers shared by the timing/scoring core.
 * Kept dependency-free so they run in the default (node) vitest environment.
 */

/** Clamp a value into the inclusive [0, 1] range. */
export function clamp01(value: number): number {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

/** Linear interpolation from `a` to `b` by `t` (t is clamped to [0, 1]). */
export function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * clamp01(t);
}
