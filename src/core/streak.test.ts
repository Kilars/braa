import { describe, it, expect } from 'vitest';
import { updateStreak } from './streak';

// ─── Cycle 52-1: no prior play → streak 1 ────────────────────────────────────


describe('updateStreak — no prior play', () => {
  it('returns streak 1 when lastPlayedYmd is empty string', () => {
    const result = updateStreak('', '2026-06-14', 0);
    expect(result.streak).toBe(1);
    expect(result.lastPlayedYmd).toBe('2026-06-14');
  });
});

// ─── Cycle 52-2: same day → streak unchanged ─────────────────────────────────

describe('updateStreak — same day', () => {
  it('returns unchanged streak when lastPlayed equals today', () => {
    const result = updateStreak('2026-06-14', '2026-06-14', 5);
    expect(result.streak).toBe(5);
    expect(result.lastPlayedYmd).toBe('2026-06-14');
  });
});

// ─── Cycle 52-3: consecutive day → streak + 1 ────────────────────────────────

describe('updateStreak — consecutive day', () => {
  it('increments streak by 1 when today is exactly the next calendar day', () => {
    const result = updateStreak('2026-06-14', '2026-06-15', 3);
    expect(result.streak).toBe(4);
    expect(result.lastPlayedYmd).toBe('2026-06-15');
  });

  it('handles month boundary: 2026-06-30 → 2026-07-01', () => {
    const result = updateStreak('2026-06-30', '2026-07-01', 7);
    expect(result.streak).toBe(8);
    expect(result.lastPlayedYmd).toBe('2026-07-01');
  });

  it('handles year boundary: 2026-12-31 → 2027-01-01', () => {
    const result = updateStreak('2026-12-31', '2027-01-01', 14);
    expect(result.streak).toBe(15);
    expect(result.lastPlayedYmd).toBe('2027-01-01');
  });
});

// ─── Cycle 52-5: 2+ day gap → reset to 1 ────────────────────────────────────

describe('updateStreak — gap resets streak', () => {
  it('resets to 1 when gap is exactly 2 days', () => {
    const result = updateStreak('2026-06-12', '2026-06-14', 10);
    expect(result.streak).toBe(1);
    expect(result.lastPlayedYmd).toBe('2026-06-14');
  });

  it('resets to 1 when gap is many days', () => {
    const result = updateStreak('2026-01-01', '2026-06-14', 30);
    expect(result.streak).toBe(1);
  });
});
