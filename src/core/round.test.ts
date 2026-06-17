import { describe, it, expect } from 'vitest';
import { buildTimeline, SchedulerConfig } from './scheduler';
import { createRound, markAt, isMastered, replaceTimeline } from './round';

// ─── Deterministic RNG helper ────────────────────────────────────────────────

function seqRng(values: number[]): () => number {
  let i = 0;
  return () => values[i++ % values.length];
}

const BASE_CFG: SchedulerConfig = {
  attemptInterval: 2000,
  activeSpan: 800,
  windowWidth: 400,
  peakRadius: 80,
  distractorRate: 0,
};

// ─── Cycle 1: fresh round starts at zero progress, not mastered ───────────────

describe('createRound', () => {
  it('fresh round has learned 0 and is not mastered', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 3);
    const round = createRound(timeline);
    expect(round.session.learned).toBe(0);
    expect(isMastered(round)).toBe(false);
    expect(round.lastResult).toBeNull();
  });
});

// ─── Cycle 2: PERFECT mark on an active attempt advances the bar ──────────────

describe('markAt — PERFECT on active attempt', () => {
  it('advances session.learned by 8 (PERFECT delta) when tapping on the peak', () => {
    // First attempt in BASE_CFG:
    //   activeStart=0, activeEnd=800
    //   windowWidth=400 centered in 800 → start=200, end=600, peak=400
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 3);
    const firstAttempt = timeline[0].attempt!;
    const round0 = createRound(timeline);
    const round1 = markAt(round0, firstAttempt.peak);
    expect(round1.session.learned).toBe(8);
    expect(round1.lastResult).toBe('PERFECT');
  });
});

// ─── Cycle 3: mark with no active attempt → FALSE_MARK + confuse started ──────

describe('markAt — FALSE_MARK when no active attempt', () => {
  it('records FALSE_MARK and sets confusedUntil when tapping in idle gap', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 3);
    // First attempt activeEnd=800, second activeStart=2000. Gap at t=1000.
    const gapTime = 1000;
    const round0 = createRound(timeline);
    const round1 = markAt(round0, gapTime);
    expect(round1.lastResult).toBe('FALSE_MARK');
    // FALSE_MARK sets confusedUntil = now + CONFUSE_MS (3000)
    expect(round1.session.confusedUntil).toBe(gapTime + 3000);
  });
});

// ─── Cycle 4: repeated good marks reach mastery ───────────────────────────────

describe('isMastered — reaches mastery after enough PERFECT marks', () => {
  it('becomes mastered once learned reaches 100 (13 PERFECTs needed)', () => {
    // 13 × 8 = 104 → clamps to 100 → mastered
    // Build a timeline with 13 attempts spaced by 2000ms, no distractors
    const cfg: SchedulerConfig = { ...BASE_CFG, attemptInterval: 2000 };
    const timeline = buildTimeline(cfg, seqRng([0]), 13);
    let round = createRound(timeline);

    for (const event of timeline.filter(e => e.kind === 'attempt')) {
      // Tap exactly on the peak of each attempt
      round = markAt(round, event.attempt!.peak);
    }

    expect(isMastered(round)).toBe(true);
    expect(round.session.learned).toBe(100);
  });
});

// ─── Cycle 5: lastResult tracks the most recent mark ─────────────────────────

describe('lastResult — reflects the latest mark', () => {
  it('updates from null to PERFECT on first tap, then to FALSE_MARK on idle tap', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 3);
    const firstAttempt = timeline[0].attempt!;

    let round = createRound(timeline);
    expect(round.lastResult).toBeNull();

    // Tap on peak of first attempt → PERFECT
    round = markAt(round, firstAttempt.peak);
    expect(round.lastResult).toBe('PERFECT');

    // Tap in the idle gap after first attempt → FALSE_MARK
    round = markAt(round, 1000);
    expect(round.lastResult).toBe('FALSE_MARK');
  });

  it('reflects MISS when tap is inside the active span but outside scoring window', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 1);
    // activeStart=0, activeEnd=800; windowWidth=400 → start=200, end=600
    // Tap at t=100 is in active span [0,800] but before scoring window [200,600] → MISS
    const round0 = createRound(timeline);
    const round1 = markAt(round0, 100);
    expect(round1.lastResult).toBe('MISS');
  });
});

// ─── replaceTimeline: swap the timeline but PRESERVE learned progress ─────────

describe('replaceTimeline — preserves session progress', () => {
  it('swaps the timeline while keeping learned/session and lastResult intact', () => {
    const oldTimeline = buildTimeline(BASE_CFG, seqRng([0]), 3);
    let round = createRound(oldTimeline);
    round = markAt(round, oldTimeline[0].attempt!.peak); // learned = 8, PERFECT
    expect(round.session.learned).toBe(8);

    const newTimeline = buildTimeline(BASE_CFG, seqRng([0]), 5);
    const swapped = replaceTimeline(round, newTimeline);

    expect(swapped.session).toBe(round.session); // progress untouched
    expect(swapped.session.learned).toBe(8);
    expect(swapped.lastResult).toBe('PERFECT');
    expect(swapped.timeline).toBe(newTimeline); // timeline replaced
  });
});
