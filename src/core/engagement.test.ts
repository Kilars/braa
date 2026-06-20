import { describe, it, expect } from 'vitest';
import { engagement, disengageBeat, rewardLatencyMs, REWARD_SLOW_MS } from './engagement';

// ── Cycle 1: a good mark refills the meter (good timing keeps the dog eager) ──

describe('engagement — good marks refill', () => {
  it('a PERFECT mark raises the meter', () => {
    expect(engagement(0.5, { kind: 'mark', result: 'PERFECT' })).toBeGreaterThan(0.5);
  });
});

// ── Cycle 2: the meter is bounded to [0, 1] ──────────────────────────────────

describe('engagement — bounds', () => {
  it('never rises above 1 (a full meter stays full)', () => {
    expect(engagement(1, { kind: 'mark', result: 'PERFECT' })).toBe(1);
    expect(engagement(0.95, { kind: 'mark', result: 'PERFECT' })).toBe(1);
  });

  it('never drops below 0 (an empty meter stays empty)', () => {
    expect(engagement(0, { kind: 'mark', result: 'FALSE_MARK' })).toBe(0);
    expect(engagement(0.1, { kind: 'mark', result: 'FALSE_MARK' })).toBe(0);
  });
});

// ── Cycle 3: graded severity — sloppy/false marks drain, precise marks refill ─

describe('engagement — graded severity', () => {
  it('a FALSE_MARK drains harder than a MISS', () => {
    const start = 0.6;
    const afterMiss = engagement(start, { kind: 'mark', result: 'MISS' });
    const afterFalse = engagement(start, { kind: 'mark', result: 'FALSE_MARK' });
    expect(afterFalse).toBeLessThan(afterMiss);
    expect(afterMiss).toBeLessThan(start); // a MISS still drains
  });

  it('a PERFECT mark refills more than an OK mark', () => {
    const start = 0.4;
    expect(engagement(start, { kind: 'mark', result: 'PERFECT' })).toBeGreaterThan(
      engagement(start, { kind: 'mark', result: 'OK' }),
    );
  });
});

// ── Cycle 4: reward latency — slow rewards drain, snappy rewards keep it eager ─

describe('engagement — reward latency', () => {
  it('a slow reward drains the meter', () => {
    expect(engagement(0.6, { kind: 'reward', latencyMs: 3000 })).toBeLessThan(0.6);
  });

  it('a snappy reward keeps the dog eager (does not drain)', () => {
    expect(engagement(0.6, { kind: 'reward', latencyMs: 300 })).toBeGreaterThanOrEqual(0.6);
  });

  it('a slower reward drains more than a moderately-slow one', () => {
    const start = 0.8;
    expect(engagement(start, { kind: 'reward', latencyMs: 3000 })).toBeLessThan(
      engagement(start, { kind: 'reward', latencyMs: 1600 }),
    );
  });
});

// ── Cycle 4b: reward latency derived from the apex-vs-tap gap ─────────────────

describe('rewardLatencyMs — apex-to-reward gap', () => {
  it('is the positive gap when the tap lands after the apex', () => {
    expect(rewardLatencyMs(1500, 1000)).toBe(500);
  });

  it('clamps to 0 when the tap pre-empts the apex (never negative)', () => {
    expect(rewardLatencyMs(900, 1000)).toBe(0);
  });

  it('is 0 for a tap exactly on the apex', () => {
    expect(rewardLatencyMs(1000, 1000)).toBe(0);
  });
});

// ── Cycle 4c: a slow-but-correct mark nets less engagement than a snappy one ──
// (the live loop fires BOTH the mark event and a reward-latency event on PERFECT/OK)

describe('engagement — slow reward bites through the public reducer', () => {
  it('a deliberately slow OK nets less than a snappy OK of equal mark quality', () => {
    const start = 0.5;
    const snappy = engagement(
      engagement(start, { kind: 'mark', result: 'OK' }),
      { kind: 'reward', latencyMs: rewardLatencyMs(1000, 700) }, // 300 ms — snappy
    );
    const slow = engagement(
      engagement(start, { kind: 'mark', result: 'OK' }),
      { kind: 'reward', latencyMs: rewardLatencyMs(1000 + REWARD_SLOW_MS, 1000) }, // ≥ slow
    );
    expect(slow).toBeLessThan(snappy);
  });
});

// ── Cycle 5: a full meter reads as 'engaged' (dog is on-task) ────────────────

describe('disengageBeat — engaged', () => {
  it('returns "engaged" when the meter is full', () => {
    expect(disengageBeat(1)).toBe('engaged');
  });

  it('returns "engaged" while the meter stays high', () => {
    expect(disengageBeat(0.8)).toBe('engaged');
  });
});

// ── Cycle 6: an empty meter reads as 'walk-off' (the dog disengages) ─────────

describe('disengageBeat — walk-off', () => {
  it('returns "walk-off" when the meter is empty', () => {
    expect(disengageBeat(0)).toBe('walk-off');
  });
});

// ── Cycle 7: graded escalation through the middle band ───────────────────────

describe('disengageBeat — graded escalation', () => {
  it('steps engaged → itch → flop → bark → walk-off as the meter drops', () => {
    expect(disengageBeat(0.9)).toBe('engaged');
    expect(disengageBeat(0.6)).toBe('itch');
    expect(disengageBeat(0.35)).toBe('flop');
    expect(disengageBeat(0.1)).toBe('bark');
    expect(disengageBeat(0)).toBe('walk-off');
  });

  it('is monotonic — escalation never reverses as the meter falls', () => {
    const order = ['engaged', 'itch', 'flop', 'bark', 'walk-off'];
    const levels = [1, 0.75, 0.6, 0.5, 0.35, 0.25, 0.1, 0];
    const ranks = levels.map((l) => order.indexOf(disengageBeat(l)));
    for (let i = 1; i < ranks.length; i++) {
      expect(ranks[i]).toBeGreaterThanOrEqual(ranks[i - 1]);
    }
  });
});
