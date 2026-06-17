import { describe, it, expect } from 'vitest';
import { newSession, applyMark, isConfused, CONFUSE_MS } from './session';

describe('newSession', () => {
  it('starts with learned 0 and not mastered', () => {
    const s = newSession();
    expect(s.learned).toBe(0);
    expect(s.mastered).toBe(false);
    expect(s.confusedUntil).toBeNull();
  });
});

describe('applyMark — progress', () => {
  it('PERFECT adds 8 to learned', () => {
    const s = applyMark(newSession(), 'PERFECT', 0);
    expect(s.learned).toBe(8);
  });

  it('OK adds 3 to learned', () => {
    const s = applyMark(newSession(), 'OK', 0);
    expect(s.learned).toBe(3);
  });

  it('MISS adds 0 to learned', () => {
    const s = applyMark(newSession(), 'MISS', 0);
    expect(s.learned).toBe(0);
  });

  it('bar clamps at 100 and sets mastered true', () => {
    // Start at 95, PERFECT (+8) would push to 103 — clamps to 100
    const s95 = { learned: 95, confusedUntil: null, mastered: false };
    const s = applyMark(s95, 'PERFECT', 0);
    expect(s.learned).toBe(100);
    expect(s.mastered).toBe(true);
  });

  it('FALSE_MARK subtracts 4 from learned', () => {
    const s10 = { learned: 10, confusedUntil: null, mastered: false };
    const s = applyMark(s10, 'FALSE_MARK', 0);
    expect(s.learned).toBe(6);
  });

  it('FALSE_MARK clamps at 0 — never negative (no fail)', () => {
    // learned=2, FALSE_MARK (-4) would push to -2 → clamps to 0
    const s2 = { learned: 2, confusedUntil: null, mastered: false };
    const s = applyMark(s2, 'FALSE_MARK', 0);
    expect(s.learned).toBe(0);
    expect(s.mastered).toBe(false);
  });
});

describe('confuse debuff', () => {
  it('FALSE_MARK sets confusedUntil to now + CONFUSE_MS', () => {
    const now = 1000;
    const s = applyMark(newSession(), 'FALSE_MARK', now);
    expect(s.confusedUntil).toBe(now + CONFUSE_MS);
  });

  it('isConfused is true before the window expires', () => {
    const now = 1000;
    const s = applyMark(newSession(), 'FALSE_MARK', now);
    // Check just before expiry
    expect(isConfused(s, now + CONFUSE_MS - 1)).toBe(true);
  });

  it('isConfused is false at or after the window expires', () => {
    const now = 1000;
    const s = applyMark(newSession(), 'FALSE_MARK', now);
    expect(isConfused(s, now + CONFUSE_MS)).toBe(false);
    expect(isConfused(s, now + CONFUSE_MS + 1)).toBe(false);
  });

  it('isConfused is false on a fresh session', () => {
    expect(isConfused(newSession(), 0)).toBe(false);
  });

  it('repeated FALSE_MARKs refresh the window — does not stack beyond one window', () => {
    // First false mark at t=0 → confusedUntil = CONFUSE_MS
    const s1 = applyMark(newSession(), 'FALSE_MARK', 0);
    expect(s1.confusedUntil).toBe(CONFUSE_MS);

    // Second false mark 1 second later → confusedUntil = 1000 + CONFUSE_MS (refreshed, not doubled)
    const s2 = applyMark(s1, 'FALSE_MARK', 1000);
    expect(s2.confusedUntil).toBe(1000 + CONFUSE_MS);

    // Verify it's exactly one CONFUSE_MS window from the most recent false mark, not two
    expect(s2.confusedUntil).not.toBe(2 * CONFUSE_MS);
  });
});
