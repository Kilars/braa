import { describe, it, expect } from 'vitest';
import { rewardPulse } from './rewardPulse';
import type { MarkResult } from '../core/mark';

describe('rewardPulse', () => {
  // Slice 1: peak at markAt, 0 past window
  it('returns the tier peak at now===markAt and 0 well past the window', () => {
    const markAt = 1000;
    const atMark = rewardPulse(markAt, markAt, 'PERFECT', { reducedMotion: false });
    expect(atMark).toBeGreaterThan(0);

    const wellPast = rewardPulse(markAt + 2000, markAt, 'PERFECT', { reducedMotion: false });
    expect(wellPast).toBe(0);
  });

  // Slice 2: PERFECT peak > OK peak
  it('PERFECT has a higher peak intensity than OK at now===markAt', () => {
    const markAt = 1000;
    const perfect = rewardPulse(markAt, markAt, 'PERFECT', { reducedMotion: false });
    const ok = rewardPulse(markAt, markAt, 'OK', { reducedMotion: false });
    expect(perfect).toBeGreaterThan(ok);
    expect(ok).toBeGreaterThan(0);
  });

  // Slice 3: MISS, FALSE_MARK, and null markAt always return 0
  it('returns 0 for MISS at any time', () => {
    const markAt = 1000;
    expect(rewardPulse(markAt, markAt, 'MISS', { reducedMotion: false })).toBe(0);
    expect(rewardPulse(markAt + 100, markAt, 'MISS', { reducedMotion: false })).toBe(0);
  });

  it('returns 0 for FALSE_MARK at any time', () => {
    const markAt = 1000;
    expect(rewardPulse(markAt, markAt, 'FALSE_MARK', { reducedMotion: false })).toBe(0);
    expect(rewardPulse(markAt + 100, markAt, 'FALSE_MARK', { reducedMotion: false })).toBe(0);
  });

  it('returns 0 when markAt is null (no mark registered)', () => {
    expect(rewardPulse(1000, null, 'PERFECT', { reducedMotion: false })).toBe(0);
    expect(rewardPulse(1000, null, 'OK', { reducedMotion: false })).toBe(0);
  });

  // Slice 4: monotonic decay from markAt to window end
  it('decays monotonically from markAt through the window', () => {
    const markAt = 1000;
    const opts = { reducedMotion: false };
    const samples = [0, 100, 200, 300, 400, 500].map(dt =>
      rewardPulse(markAt + dt, markAt, 'PERFECT', opts)
    );
    // Each sample must be <= the previous (non-increasing)
    for (let i = 1; i < samples.length; i++) {
      expect(samples[i]).toBeLessThanOrEqual(samples[i - 1]);
    }
    // And the last sample (at window end) must be 0
    expect(samples[samples.length - 1]).toBe(0);
  });

  // Slice 5: reducedMotion reduces peak amplitude but keeps it > 0 at markAt (D8/D13)
  it('reducedMotion reduces the peak amplitude but keeps it > 0 at markAt', () => {
    const markAt = 1000;
    const full = rewardPulse(markAt, markAt, 'PERFECT', { reducedMotion: false });
    const reduced = rewardPulse(markAt, markAt, 'PERFECT', { reducedMotion: true });
    expect(reduced).toBeLessThan(full);
    expect(reduced).toBeGreaterThan(0);
  });

  it('reducedMotion also applies to OK tier — reduced but still > 0', () => {
    const markAt = 1000;
    const full = rewardPulse(markAt, markAt, 'OK', { reducedMotion: false });
    const reduced = rewardPulse(markAt, markAt, 'OK', { reducedMotion: true });
    expect(reduced).toBeLessThan(full);
    expect(reduced).toBeGreaterThan(0);
  });
});
