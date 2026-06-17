import { describe, it, expect } from 'vitest';
import { RESUME_GRACE_MS, isWithinResumeGrace } from './resumeGrace';

describe('isWithinResumeGrace', () => {
  it('is true for a tap immediately after resume (now - resumedAt < graceMs)', () => {
    expect(isWithinResumeGrace(1000, 700, 400)).toBe(true); // 300 < 400
  });

  it('is false for a tap after the window (now - resumedAt >= graceMs)', () => {
    expect(isWithinResumeGrace(1200, 700, 400)).toBe(false); // 500 >= 400
  });

  it('is false at the exact boundary (window is half-open)', () => {
    expect(isWithinResumeGrace(1100, 700, 400)).toBe(false); // 400 === 400 → allowed
  });

  it('is false for a never-resumed sentinel (resumedAt = -Infinity)', () => {
    expect(isWithinResumeGrace(500, -Infinity, 400)).toBe(false);
  });

  it('uses RESUME_GRACE_MS as the default window', () => {
    expect(isWithinResumeGrace(700 + RESUME_GRACE_MS - 1, 700)).toBe(true);
    expect(isWithinResumeGrace(700 + RESUME_GRACE_MS, 700)).toBe(false);
  });
});

describe('RESUME_GRACE_MS', () => {
  it('is a small positive constant (> 0 and < 2000 ms)', () => {
    expect(RESUME_GRACE_MS).toBeGreaterThan(0);
    expect(RESUME_GRACE_MS).toBeLessThan(2000);
  });
});
