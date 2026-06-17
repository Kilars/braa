import { describe, it, expect } from 'vitest';
import { classifyMark, NORMAL_DELTAS } from './mark';

describe('classifyMark', () => {
  const attempt = { start: 100, end: 200, peak: 150, peakRadius: 15 };

  it('is a false mark when nothing is being attempted', () => {
    expect(classifyMark(150, null)).toBe('FALSE_MARK');
  });

  it('is PERFECT when tapped exactly on the peak', () => {
    expect(classifyMark(150, attempt)).toBe('PERFECT');
  });

  // attempt: start=100, end=200, peak=150, peakRadius=15
  // PERFECT band: [135, 165] (inclusive both edges)
  it('is OK when tap is inside the window but just outside the peak band', () => {
    // 166 is just past the peak band edge (> 150+15)
    expect(classifyMark(166, attempt)).toBe('OK');
    // 134 is just before the peak band edge (< 150-15)
    expect(classifyMark(134, attempt)).toBe('OK');
  });

  // Boundary semantics: start and end are inclusive edges of the scoring window
  it('is MISS when tap is just before the window opens (start is inclusive)', () => {
    expect(classifyMark(99, attempt)).toBe('MISS');
    // start itself is inside the window
    expect(classifyMark(100, attempt)).toBe('OK');
  });

  it('is MISS when tap is just after the window closes (end is inclusive)', () => {
    expect(classifyMark(201, attempt)).toBe('MISS');
    // end itself is inside the window
    expect(classifyMark(200, attempt)).toBe('OK');
  });
});

describe('NORMAL_DELTAS', () => {
  // Values from spec: "PERFECT +8%  OK +3%  miss +0%  false mark -4%"
  it('gives +8 progress for PERFECT', () => {
    expect(NORMAL_DELTAS.PERFECT).toBe(8);
  });

  it('gives +3 progress for OK', () => {
    expect(NORMAL_DELTAS.OK).toBe(3);
  });

  it('gives 0 progress for MISS', () => {
    expect(NORMAL_DELTAS.MISS).toBe(0);
  });

  it('gives -4 progress for FALSE_MARK', () => {
    expect(NORMAL_DELTAS.FALSE_MARK).toBe(-4);
  });
});
