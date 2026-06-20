/**
 * Disambiguates a press on the BRA marker between a **tap** (fire the timing mark)
 * and a horizontal **swipe** (swap the loaded marker phrase — specs.md §Marker Phrases:
 * "swapped by swiping the BRA marker itself; the round is still one tap"). Pure geometry,
 * no DOM — the HUD feeds it the pointer delta and acts on the result.
 */

/** Minimum horizontal travel (px) before a press is treated as a swipe, not a tap. */
export const SWIPE_THRESHOLD_PX = 40;

export type SwipeOutcome =
  | { type: 'tap' }
  | { type: 'swipe'; dir: 'next' | 'prev' };

/**
 * A press is a swipe only when it travels horizontally past `thresholdPx` AND the
 * horizontal travel dominates the vertical (so a scroll/vertical drag stays a tap).
 * Swipe-left = next phrase, swipe-right = previous. Everything else is a tap, so the
 * timing mark is never lost to an accidental wobble.
 */
export function classifySwipe(
  dx: number,
  dy: number,
  thresholdPx: number = SWIPE_THRESHOLD_PX,
): SwipeOutcome {
  if (Math.abs(dx) >= thresholdPx && Math.abs(dx) > Math.abs(dy)) {
    return { type: 'swipe', dir: dx < 0 ? 'next' : 'prev' };
  }
  return { type: 'tap' };
}

/**
 * Step an index over a wrap-around list in either direction. A list of one (or zero)
 * has nothing to cycle to, so the index is returned unchanged.
 */
export function cycleIndex(current: number, length: number, dir: 'next' | 'prev'): number {
  if (length <= 1) return current;
  return dir === 'next' ? (current + 1) % length : (current - 1 + length) % length;
}
