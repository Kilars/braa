import { describe, it, expect } from 'vitest';
import { comboAfter, comboMultiplier } from './combo';

// ── Cycle 7: Determinism ─────────────────────────────────────────────────────

describe('determinism', () => {
  it('comboAfter returns the same result for the same inputs', () => {
    expect(comboAfter(5, 'PERFECT')).toBe(comboAfter(5, 'PERFECT'));
    expect(comboAfter(3, 'MISS')).toBe(comboAfter(3, 'MISS'));
  });

  it('comboMultiplier returns the same result for the same input', () => {
    expect(comboMultiplier(7)).toBe(comboMultiplier(7));
    expect(comboMultiplier(0)).toBe(comboMultiplier(0));
  });
});

// ── Cycle 6: comboMultiplier — cap ───────────────────────────────────────────

describe('comboMultiplier — cap', () => {
  it('never exceeds 2 no matter how high the combo', () => {
    expect(comboMultiplier(11)).toBe(2);
    expect(comboMultiplier(50)).toBe(2);
    expect(comboMultiplier(1000)).toBe(2);
  });

  it('reaches the cap at combo 11 (10 steps above 1)', () => {
    // combo=11: 1 + 0.1*(11-1) = 1 + 1.0 = 2.0
    expect(comboMultiplier(11)).toBe(2);
  });
});

// ── Cycle 5: comboMultiplier — grows with combo ──────────────────────────────

describe('comboMultiplier — growth', () => {
  it('returns > 1 for combo >= 2', () => {
    expect(comboMultiplier(2)).toBeGreaterThan(1);
    expect(comboMultiplier(5)).toBeGreaterThan(comboMultiplier(2));
  });

  it('grows monotonically up to the cap', () => {
    // Each step up increases the multiplier until cap
    expect(comboMultiplier(3)).toBeGreaterThan(comboMultiplier(2));
    expect(comboMultiplier(10)).toBeGreaterThanOrEqual(comboMultiplier(5));
  });
});

// ── Cycle 4: comboMultiplier — base value ────────────────────────────────────

describe('comboMultiplier — base value', () => {
  it('returns 1 when combo is 0', () => {
    expect(comboMultiplier(0)).toBe(1);
  });

  it('returns 1 when combo is 1', () => {
    expect(comboMultiplier(1)).toBe(1);
  });
});

// ── Cycle 1: comboAfter increments on PERFECT ────────────────────────────────

describe('comboAfter — PERFECT increments', () => {
  it('comboAfter(0, PERFECT) returns 1', () => {
    expect(comboAfter(0, 'PERFECT')).toBe(1);
  });
});

// ── Cycle 3: comboAfter resets on MISS / FALSE_MARK ──────────────────────────

describe('comboAfter — break', () => {
  it('resets to 0 on MISS regardless of current combo', () => {
    expect(comboAfter(0, 'MISS')).toBe(0);
    expect(comboAfter(5, 'MISS')).toBe(0);
  });

  it('resets to 0 on FALSE_MARK regardless of current combo', () => {
    expect(comboAfter(0, 'FALSE_MARK')).toBe(0);
    expect(comboAfter(7, 'FALSE_MARK')).toBe(0);
  });
});

// ── Cycle 2: comboAfter chains PERFECT/OK ────────────────────────────────────

describe('comboAfter — chaining', () => {
  it('increments combo by 1 on each PERFECT', () => {
    expect(comboAfter(1, 'PERFECT')).toBe(2);
    expect(comboAfter(2, 'PERFECT')).toBe(3);
    expect(comboAfter(9, 'PERFECT')).toBe(10);
  });

  it('increments combo by 1 on OK', () => {
    expect(comboAfter(0, 'OK')).toBe(1);
    expect(comboAfter(3, 'OK')).toBe(4);
  });
});
