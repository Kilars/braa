import { describe, it, expect } from 'vitest';
import { isDisengaged, canScoreMark, callBackEngagement } from './disengage';
import { disengageBeat, type DisengageBeat } from './engagement';

const BEATS: DisengageBeat[] = ['engaged', 'itch', 'flop', 'bark', 'walk-off'];

// ── Cycle 1: the dog is "disengaged" only at the walk-off beat ────────────────

describe('isDisengaged', () => {
  it('is true only for the walk-off beat', () => {
    expect(isDisengaged('walk-off')).toBe(true);
  });

  it('is false for every non-walk-off beat (mild beats are still in play)', () => {
    for (const beat of BEATS.filter((b) => b !== 'walk-off')) {
      expect(isDisengaged(beat)).toBe(false);
    }
  });
});

// ── Cycle 2: marks cannot score while the dog has walked off ──────────────────

describe('canScoreMark', () => {
  it('is false at walk-off (a tap is a call-back, not a scored mark)', () => {
    expect(canScoreMark('walk-off')).toBe(false);
  });

  it('is true for every non-walk-off beat (normal play still scores)', () => {
    for (const beat of BEATS.filter((b) => b !== 'walk-off')) {
      expect(canScoreMark(beat)).toBe(true);
    }
  });
});

// ── Cycle 3: a call-back restores engagement comfortably above walk-off ───────

describe('callBackEngagement', () => {
  it('restores from empty to a level that is no longer walk-off (re-engaged)', () => {
    const restored = callBackEngagement(0);
    expect(disengageBeat(restored)).not.toBe('walk-off');
  });

  it('never exceeds 1 nor drops below 0 (clamped meter)', () => {
    for (const prev of [-1, 0, 0.5, 1, 2]) {
      const restored = callBackEngagement(prev);
      expect(restored).toBeGreaterThanOrEqual(0);
      expect(restored).toBeLessThanOrEqual(1);
    }
  });

  it('does not immediately re-walk-off — restored level sits above the bark band, leaving slack', () => {
    // The restored level must be high enough that it is neither walk-off nor the
    // adjacent "bark" beat, so a single bad mark cannot bounce it straight back.
    const restored = callBackEngagement(0);
    expect(disengageBeat(restored)).not.toBe('walk-off');
    expect(disengageBeat(restored)).not.toBe('bark');
  });
});
