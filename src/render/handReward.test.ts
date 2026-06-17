import { describe, it, expect } from 'vitest';
import { handAnim } from './handReward';

describe('handAnim', () => {
  // Slice 1: at rest (null triggeredAt, or now well past window) → progress 0
  it('returns progress 0 when triggeredAt is null', () => {
    const result = handAnim(1000, null, 'mark', { reducedMotion: false });
    expect(result.progress).toBe(0);
  });

  it('returns progress 0 when now is well past the window', () => {
    const triggeredAt = 1000;
    const result = handAnim(triggeredAt + 5000, triggeredAt, 'mark', { reducedMotion: false });
    expect(result.progress).toBe(0);
  });

  // Slice 3: 'mastery' has larger reach and longer duration than 'mark'
  it('mastery has a larger peak reach than mark', () => {
    const triggeredAt = 1000;
    const opts = { reducedMotion: false };
    const markResult = handAnim(triggeredAt + 325, triggeredAt, 'mark', opts);
    const masteryResult = handAnim(triggeredAt + 325, triggeredAt, 'mastery', opts);
    expect(masteryResult.reach).toBeGreaterThan(markResult.reach);
  });

  it('mastery has a longer window than mark (still active after mark window ends)', () => {
    const triggeredAt = 1000;
    const opts = { reducedMotion: false };
    // At 900ms: mark window (650ms) is done; mastery (1300ms) is mid-window
    const markResult = handAnim(triggeredAt + 900, triggeredAt, 'mark', opts);
    const masteryResult = handAnim(triggeredAt + 900, triggeredAt, 'mastery', opts);
    expect(markResult.progress).toBe(0);
    expect(masteryResult.progress).toBeGreaterThan(0);
  });

  // Slice 5: reducedMotion reduces peak reach/duration but keeps progress > 0 in window
  it('reducedMotion reduces peak progress amplitude but keeps it > 0 during the window', () => {
    const triggeredAt = 1000;
    const full = handAnim(triggeredAt + 325, triggeredAt, 'mark', { reducedMotion: false });
    const reduced = handAnim(triggeredAt + 325, triggeredAt, 'mark', { reducedMotion: true });
    // Gesture is smaller but still visible
    expect(reduced.progress).toBeLessThan(full.progress);
    expect(reduced.progress).toBeGreaterThan(0);
  });

  it('reducedMotion also applies to mastery — reduced but still > 0 in window', () => {
    const triggeredAt = 1000;
    const full = handAnim(triggeredAt + 650, triggeredAt, 'mastery', { reducedMotion: false });
    const reduced = handAnim(triggeredAt + 650, triggeredAt, 'mastery', { reducedMotion: true });
    expect(reduced.progress).toBeLessThan(full.progress);
    expect(reduced.progress).toBeGreaterThan(0);
  });

  // Slice 4: progress returns exactly to 0 at and after the window end (no stuck hand)
  it('progress is 0 at exactly the mark window end (no stuck hand)', () => {
    const triggeredAt = 1000;
    // t = 650/650 = 1.0 → boundary → 0
    const atEnd = handAnim(triggeredAt + 650, triggeredAt, 'mark', { reducedMotion: false });
    expect(atEnd.progress).toBe(0);
    // and just after
    const pastEnd = handAnim(triggeredAt + 651, triggeredAt, 'mark', { reducedMotion: false });
    expect(pastEnd.progress).toBe(0);
  });

  it('mastery progress is 0 at exactly the mastery window end', () => {
    const triggeredAt = 1000;
    const atEnd = handAnim(triggeredAt + 1300, triggeredAt, 'mastery', { reducedMotion: false });
    expect(atEnd.progress).toBe(0);
  });

  // Slice 2: enter → peak → retract within window
  it('progress rises just after trigger, peaks near mid-window, returns to 0 at window end', () => {
    const triggeredAt = 1000;
    const opts = { reducedMotion: false };
    // Just after trigger — progress should be > 0 (hand entering)
    const earlyResult = handAnim(triggeredAt + 50, triggeredAt, 'mark', opts);
    expect(earlyResult.progress).toBeGreaterThan(0);
    // Mid-window (~50% through) — should be near peak (~1)
    const midResult = handAnim(triggeredAt + 325, triggeredAt, 'mark', opts);
    expect(midResult.progress).toBeGreaterThan(0.9);
    // At window end — should be back at 0
    const endResult = handAnim(triggeredAt + 650, triggeredAt, 'mark', opts);
    expect(endResult.progress).toBe(0);
  });
});
