import { describe, it, expect } from 'vitest';
import { classifySwipe, cycleIndex, SWIPE_THRESHOLD_PX } from './swipeGesture';

// ── Cycle 1: a horizontal drag past the threshold is a swipe ──────────────────

describe('classifySwipe — horizontal drag past threshold', () => {
  it('a left drag is a swipe to the next phrase', () => {
    expect(classifySwipe(-(SWIPE_THRESHOLD_PX + 10), 0)).toEqual({ type: 'swipe', dir: 'next' });
  });

  it('a right drag is a swipe to the previous phrase', () => {
    expect(classifySwipe(SWIPE_THRESHOLD_PX + 10, 0)).toEqual({ type: 'swipe', dir: 'prev' });
  });

  it('a drag exactly at the threshold counts as a swipe (boundary is inclusive)', () => {
    expect(classifySwipe(-SWIPE_THRESHOLD_PX, 0)).toEqual({ type: 'swipe', dir: 'next' });
  });
});

// ── Cycle 2: anything that isn't a clear horizontal swipe is a tap (mark) ──────

describe('classifySwipe — falls through to a tap', () => {
  it('a sub-threshold movement is a tap (preserves the timing mark)', () => {
    expect(classifySwipe(5, 3)).toEqual({ type: 'tap' });
  });

  it('a zero-movement press is a tap', () => {
    expect(classifySwipe(0, 0)).toEqual({ type: 'tap' });
  });

  it('a vertical-dominant drag is a tap, not a swipe', () => {
    // far enough horizontally to pass the threshold, but vertical movement dominates
    expect(classifySwipe(SWIPE_THRESHOLD_PX + 10, SWIPE_THRESHOLD_PX + 60)).toEqual({ type: 'tap' });
  });

  it('honours a custom threshold', () => {
    expect(classifySwipe(30, 0, 100)).toEqual({ type: 'tap' });
    expect(classifySwipe(120, 0, 100)).toEqual({ type: 'swipe', dir: 'prev' });
  });
});

// ── Cycle 3: direction-aware index cycling over the available phrase list ──────

describe('cycleIndex — wraps both directions', () => {
  it('next advances and wraps past the end', () => {
    expect(cycleIndex(0, 3, 'next')).toBe(1);
    expect(cycleIndex(2, 3, 'next')).toBe(0);
  });

  it('prev steps back and wraps past the start', () => {
    expect(cycleIndex(2, 3, 'prev')).toBe(1);
    expect(cycleIndex(0, 3, 'prev')).toBe(2);
  });

  it('is a no-op when only one (or zero) phrase is available', () => {
    expect(cycleIndex(0, 1, 'next')).toBe(0);
    expect(cycleIndex(0, 0, 'prev')).toBe(0);
  });
});
