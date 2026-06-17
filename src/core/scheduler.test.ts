import { describe, it, expect } from 'vitest';
import { buildTimeline, attemptAt, distractorActiveAt, untrainAttemptAt, SchedulerConfig, TimelineEvent } from './scheduler';

// ─── Helpers and config ──────────────────────────────────────────────────────

/** Deterministic RNG that returns values from the given sequence (cycling). */
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

// ─── Cycle 1: empty timeline → attemptAt returns null ─────────────────────────

describe('attemptAt — empty timeline', () => {
  it('returns null for any now', () => {
    expect(attemptAt([], 0)).toBeNull();
    expect(attemptAt([], 99999)).toBeNull();
  });
});

// ─── Cycle 2: single attempt — inside outer span returns Attempt, outside null ─

describe('attemptAt — single attempt event', () => {
  const innerAttempt: import('./mark').Attempt = {
    start: 1100,
    end: 1500,
    peak: 1300,
    peakRadius: 80,
  };
  const event: TimelineEvent = {
    kind: 'attempt',
    activeStart: 1000,
    activeEnd: 1800,
    attempt: innerAttempt,
  };
  const timeline: TimelineEvent[] = [event];

  it('returns the inner Attempt when now is inside the outer active span', () => {
    expect(attemptAt(timeline, 1000)).toBe(innerAttempt); // at activeStart (inclusive)
    expect(attemptAt(timeline, 1400)).toBe(innerAttempt); // mid-span
    expect(attemptAt(timeline, 1800)).toBe(innerAttempt); // at activeEnd (inclusive)
  });

  it('returns null when now is outside the outer active span', () => {
    expect(attemptAt(timeline, 999)).toBeNull();  // just before
    expect(attemptAt(timeline, 1801)).toBeNull(); // just after
  });

  it('returns null for a distractor event (kind !== attempt)', () => {
    const distractor: TimelineEvent = { kind: 'distractor', activeStart: 500, activeEnd: 900 };
    expect(attemptAt([distractor], 700)).toBeNull();
  });
});

// ─── Cycle 3: buildTimeline produces count correct attempts spaced by attemptInterval

describe('buildTimeline — count and spacing', () => {
  const rng = seqRng([0]); // always returns 0 → no distractors

  it('returns exactly count attempt events when distractorRate=0', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 3);
    const attempts = timeline.filter(e => e.kind === 'attempt');
    expect(attempts).toHaveLength(3);
  });

  it('spaces correct attempts by attemptInterval', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 3);
    const attempts = timeline.filter(e => e.kind === 'attempt');
    // Each attempt's activeStart should be separated by attemptInterval
    expect(attempts[1].activeStart - attempts[0].activeStart).toBe(BASE_CFG.attemptInterval);
    expect(attempts[2].activeStart - attempts[1].activeStart).toBe(BASE_CFG.attemptInterval);
  });

  it('each attempt event spans activeSpan ms', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 2);
    const attempts = timeline.filter(e => e.kind === 'attempt');
    for (const a of attempts) {
      expect(a.activeEnd - a.activeStart).toBe(BASE_CFG.activeSpan);
    }
  });
});

// ─── Cycle 4: distractors are inserted per distractorRate; never return Attempt ─

describe('buildTimeline — distractor slots', () => {
  const HIGH_DISTRACTOR_CFG: SchedulerConfig = {
    ...BASE_CFG,
    distractorRate: 1, // always insert a distractor between attempts
  };

  it('inserts distractors between attempts when distractorRate=1', () => {
    // 0.99 < 1.0 (distractorRate) → distractor always inserted; real Math.random is [0,1)
    const timeline = buildTimeline(HIGH_DISTRACTOR_CFG, seqRng([0.99]), 2);
    const distractors = timeline.filter(e => e.kind === 'distractor');
    expect(distractors.length).toBeGreaterThan(0);
  });

  it('distractors have no attempt property', () => {
    const timeline = buildTimeline(HIGH_DISTRACTOR_CFG, seqRng([0.99]), 2);
    const distractors = timeline.filter(e => e.kind === 'distractor');
    for (const d of distractors) {
      expect(d.attempt).toBeUndefined();
    }
  });

  it('attemptAt returns null during a distractor window', () => {
    const timeline = buildTimeline(HIGH_DISTRACTOR_CFG, seqRng([0.99]), 2);
    const distractors = timeline.filter(e => e.kind === 'distractor');
    for (const d of distractors) {
      const mid = (d.activeStart + d.activeEnd) / 2;
      expect(attemptAt(timeline, mid)).toBeNull();
    }
  });

  it('no distractors when distractorRate=0', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 3);
    const distractors = timeline.filter(e => e.kind === 'distractor');
    expect(distractors).toHaveLength(0);
  });
});

// ─── Cycle 5: window width and peakRadius come from config ────────────────────

describe('buildTimeline — window width and peakRadius from config', () => {
  it('scoring window width matches config.windowWidth', () => {
    const cfg: SchedulerConfig = { ...BASE_CFG, windowWidth: 300 };
    const timeline = buildTimeline(cfg, seqRng([0]), 1);
    const ev = timeline[0];
    expect(ev.attempt).toBeDefined();
    expect(ev.attempt!.end - ev.attempt!.start).toBe(300);
  });

  it('peakRadius on the Attempt matches config.peakRadius', () => {
    const cfg: SchedulerConfig = { ...BASE_CFG, peakRadius: 50 };
    const timeline = buildTimeline(cfg, seqRng([0]), 1);
    expect(timeline[0].attempt!.peakRadius).toBe(50);
  });

  it('scoring window is centered within the active span', () => {
    // activeSpan=1000, windowWidth=400 → offset=300 → window=[300, 700] within span
    const cfg: SchedulerConfig = { ...BASE_CFG, activeSpan: 1000, windowWidth: 400, attemptInterval: 2000 };
    const timeline = buildTimeline(cfg, seqRng([0]), 1);
    const ev = timeline[0];
    const relStart = ev.attempt!.start - ev.activeStart;
    const relEnd = ev.attempt!.end - ev.activeStart;
    expect(relStart).toBe(300);
    expect(relEnd).toBe(700);
  });

  it('peak is the midpoint of the scoring window', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 1);
    const att = timeline[0].attempt!;
    expect(att.peak).toBe((att.start + att.end) / 2);
  });

  it('scoring window fits inside active span (windowWidth <= activeSpan)', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 3);
    for (const ev of timeline.filter(e => e.kind === 'attempt')) {
      expect(ev.attempt!.start).toBeGreaterThanOrEqual(ev.activeStart);
      expect(ev.attempt!.end).toBeLessThanOrEqual(ev.activeEnd);
    }
  });
});

// ─── distractorActiveAt ───────────────────────────────────────────────────────

describe('distractorActiveAt — empty timeline', () => {
  it('returns false for any now when timeline is empty', () => {
    expect(distractorActiveAt([], 0)).toBe(false);
    expect(distractorActiveAt([], 99999)).toBe(false);
  });
});

describe('distractorActiveAt — within distractor span', () => {
  const distractor: TimelineEvent = { kind: 'distractor', activeStart: 500, activeEnd: 900 };
  const timeline: TimelineEvent[] = [distractor];

  it('returns true at activeStart (inclusive)', () => {
    expect(distractorActiveAt(timeline, 500)).toBe(true);
  });

  it('returns true at mid-span', () => {
    expect(distractorActiveAt(timeline, 700)).toBe(true);
  });

  it('returns true at activeEnd (inclusive)', () => {
    expect(distractorActiveAt(timeline, 900)).toBe(true);
  });

  it('returns false just before activeStart', () => {
    expect(distractorActiveAt(timeline, 499)).toBe(false);
  });

  it('returns false just after activeEnd', () => {
    expect(distractorActiveAt(timeline, 901)).toBe(false);
  });

  it('returns false during an attempt event (not a distractor)', () => {
    const attemptEvent: TimelineEvent = {
      kind: 'attempt',
      activeStart: 1000,
      activeEnd: 1800,
      attempt: { start: 1100, end: 1500, peak: 1300, peakRadius: 80 },
    };
    expect(distractorActiveAt([attemptEvent], 1400)).toBe(false);
  });
});

// ─── Integration: buildTimeline + attemptAt — the MISS vs FALSE_MARK split ────

describe('integration — classifyMark semantics with scheduler output', () => {
  // This verifies the contract that makes MISS vs FALSE_MARK work downstream:
  //   attemptAt returns non-null ONLY during an attempt's outer active span.
  //   Tapping during a distractor → attemptAt returns null → FALSE_MARK.
  //   Tapping during active span but outside scoring window → MISS.

  const cfg: SchedulerConfig = {
    attemptInterval: 3000,
    activeSpan: 1000,
    windowWidth: 400,
    peakRadius: 80,
    distractorRate: 1,
  };

  it('attemptAt is non-null inside every correct attempt outer span', () => {
    const timeline = buildTimeline(cfg, seqRng([0.99]), 3);
    const attempts = timeline.filter(e => e.kind === 'attempt');
    for (const ev of attempts) {
      expect(attemptAt(timeline, ev.activeStart)).not.toBeNull();
      expect(attemptAt(timeline, ev.activeEnd)).not.toBeNull();
    }
  });

  it('attemptAt is null in idle gaps between active spans', () => {
    // With no distractors, gaps between activeEnd and next activeStart are idle
    const noDistractorCfg: SchedulerConfig = { ...cfg, distractorRate: 0 };
    const timeline = buildTimeline(noDistractorCfg, seqRng([0]), 2);
    const attempts = timeline.filter(e => e.kind === 'attempt');
    // In the gap after first attempt but before second
    const gapTime = attempts[0].activeEnd + 100;
    expect(attemptAt(timeline, gapTime)).toBeNull();
  });
});

// ─── untrainAttemptAt — inversion: calm gap = markable, distractor = null ─────

describe('untrainAttemptAt — inversion semantics', () => {
  // Timeline: one distractor event [500,900], one attempt event [2000,2800]
  // Calm gap between: [900, 2000) and outside both spans entirely
  const distractor: TimelineEvent = { kind: 'distractor', activeStart: 500, activeEnd: 900 };
  const attemptEvent: TimelineEvent = {
    kind: 'attempt',
    activeStart: 2000,
    activeEnd: 2800,
    attempt: { start: 2200, end: 2600, peak: 2400, peakRadius: 80 },
  };
  const timeline: TimelineEvent[] = [distractor, attemptEvent];

  it('returns null during a distractor (bad-habit) window', () => {
    // t=700 is inside distractor [500,900]
    expect(untrainAttemptAt(timeline, 700)).toBeNull();
  });

  it('returns null during a normal attempt window (not the calm)', () => {
    // t=2400 is inside attemptEvent [2000,2800] — an attempt window, not a calm gap
    expect(untrainAttemptAt(timeline, 2400)).toBeNull();
  });

  it('returns a non-null Attempt during a calm gap (no attempt, no distractor)', () => {
    // t=1400 is in the gap between distractor end (900) and attempt start (2000)
    const result = untrainAttemptAt(timeline, 1400);
    expect(result).not.toBeNull();
  });

  it('calm Attempt covers the calm gap with a valid start/end/peak', () => {
    const result = untrainAttemptAt(timeline, 1400);
    expect(result).not.toBeNull();
    expect(result!.start).toBeLessThanOrEqual(1400);
    expect(result!.end).toBeGreaterThanOrEqual(1400);
    expect(result!.peak).toBeGreaterThanOrEqual(result!.start);
    expect(result!.peak).toBeLessThanOrEqual(result!.end);
  });

  it('returns null for an empty timeline (no calm gaps to derive)', () => {
    expect(untrainAttemptAt([], 1000)).toBeNull();
  });
});
