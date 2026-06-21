import { describe, it, expect } from 'vitest';
import { dogVisualState, isDownFamilyTrick, DogVisual } from './dogState';
import { createRound, markAt, RoundState } from '../core/round';
import { buildTimeline, SchedulerConfig, TimelineEvent } from '../core/scheduler';
import { CONFUSE_MS } from '../core/session';
import type { Trick } from '../core/tricks';

// ─── Deterministic helpers ───────────────────────────────────────────────────

const BASE_CFG: SchedulerConfig = {
  attemptInterval: 2000,
  activeSpan: 800,
  windowWidth: 400,
  peakRadius: 80,
  distractorRate: 0,
};

function seqRng(values: number[]): () => number {
  let i = 0;
  return () => values[i++ % values.length];
}

/** Build a round with a timeline starting at t=0, no distractors. */
function freshRound(count = 5): RoundState {
  return createRound(buildTimeline(BASE_CFG, seqRng([0]), count));
}

// ─── RED Cycle 1: idle (none of the above) ──────────────────────────────────

describe('dogVisualState — idle', () => {
  it('returns idle when not mastered, not confused, and no active attempt', () => {
    const state = freshRound();
    // t=10000 is way past all active spans in a 5-event timeline (last activeEnd = 4*2000+800 = 8800)
    const result: DogVisual = dogVisualState(state, 10000);
    expect(result).toBe('idle');
  });
});

// ─── RED Cycle 2: offering (active attempt, not confused, not mastered) ──────

describe('dogVisualState — offering', () => {
  it('returns offering when now is inside an active attempt window', () => {
    const state = freshRound();
    // First attempt: activeStart=0, activeEnd=800, peak=400
    const result: DogVisual = dogVisualState(state, 400);
    expect(result).toBe('offering');
  });
});

// ─── RED Cycle 3: confused (FALSE_MARK sets confusedUntil, not mastered) ─────

describe('dogVisualState — confused', () => {
  it('returns confused when now is within confusedUntil window', () => {
    let state = freshRound();
    // Tap in an idle gap (t=1000: between first activeEnd=800 and second activeStart=2000)
    state = markAt(state, 1000);
    expect(state.session.confusedUntil).toBe(1000 + CONFUSE_MS);
    // At t=2000 we are still within the confuse window (ends at 4000)
    const result: DogVisual = dogVisualState(state, 2000);
    expect(result).toBe('confused');
  });

  it('returns idle (not confused) after the confuse window expires', () => {
    let state = freshRound();
    state = markAt(state, 1000);
    // At t=5000 confuse window has expired (1000+3000=4000 < 5000)
    // Also t=5000 is after all active spans in the gap
    const result: DogVisual = dogVisualState(state, 5000);
    expect(result).not.toBe('confused');
  });
});

// ─── RED Cycle 4: happy (mastered takes priority) ────────────────────────────

describe('dogVisualState — happy (mastered)', () => {
  it('returns happy when the round is mastered', () => {
    // Build a timeline with 13 PERFECT marks to reach mastery
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 13);
    let state = createRound(timeline);
    for (const ev of timeline.filter(e => e.kind === 'attempt')) {
      state = markAt(state, ev.attempt!.peak);
    }
    expect(state.session.mastered).toBe(true);
    const result: DogVisual = dogVisualState(state, 30000);
    expect(result).toBe('happy');
  });
});

// ─── RED Cycle 5a: distractor state ──────────────────────────────────────────

describe('dogVisualState — distractor', () => {
  it('returns distractor when a distractor is active and not confused/mastered/offering', () => {
    // Build a timeline with one distractor event and no active attempt at t=700
    const distractor: TimelineEvent = { kind: 'distractor', activeStart: 500, activeEnd: 900 };
    const attempt: TimelineEvent = {
      kind: 'attempt',
      activeStart: 2000,
      activeEnd: 2800,
      attempt: { start: 2200, end: 2600, peak: 2400, peakRadius: 80 },
    };
    const state = createRound([distractor, attempt]);
    const result: DogVisual = dogVisualState(state, 700);
    expect(result).toBe('distractor');
  });
});

// ─── RED Cycle 5b: distractor precedence ─────────────────────────────────────

describe('dogVisualState — distractor precedence', () => {
  // A timeline where a distractor and an attempt BOTH overlap at t=700
  // (unusual but tests precedence)
  const overlappingTimeline: TimelineEvent[] = [
    { kind: 'distractor', activeStart: 500, activeEnd: 900 },
    {
      kind: 'attempt',
      activeStart: 600,
      activeEnd: 1400,
      attempt: { start: 700, end: 1100, peak: 900, peakRadius: 80 },
    },
  ];

  it('offering wins over distractor when both are active', () => {
    const state = createRound(overlappingTimeline);
    // t=700: both distractor [500,900] and attempt [600,1400] are active
    const result: DogVisual = dogVisualState(state, 700);
    expect(result).toBe('offering');
  });

  it('confused wins over distractor when both are active', () => {
    // Distractor active at t=700, but also in confused state
    const distractorOnly: TimelineEvent[] = [
      { kind: 'distractor', activeStart: 500, activeEnd: 5000 },
      {
        kind: 'attempt',
        activeStart: 10000,
        activeEnd: 10800,
        attempt: { start: 10200, end: 10600, peak: 10400, peakRadius: 80 },
      },
    ];
    let state = createRound(distractorOnly);
    // FALSE_MARK at t=1 sets confusedUntil = 1 + CONFUSE_MS
    state = markAt(state, 1);
    // At t=700 distractor is active AND confused
    const result: DogVisual = dogVisualState(state, 700);
    expect(result).toBe('confused');
  });

  it('mastered wins over distractor', () => {
    // Build enough attempts to reach mastery
    const manyAttempts = buildTimeline(BASE_CFG, seqRng([0]), 13);
    let state = createRound([
      ...manyAttempts,
      { kind: 'distractor', activeStart: 0, activeEnd: 99999 },
    ]);
    for (const ev of manyAttempts.filter(e => e.kind === 'attempt')) {
      state = markAt(state, ev.attempt!.peak);
    }
    expect(state.session.mastered).toBe(true);
    const result: DogVisual = dogVisualState(state, 5000);
    expect(result).toBe('happy');
  });
});

// ─── RED Cycle 5: precedence tests ───────────────────────────────────────────

describe('dogVisualState — precedence', () => {
  it('mastered overrides confused: happy even if confusedUntil is still active', () => {
    // First trigger a FALSE_MARK to set confusedUntil, then get mastered
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 13);
    let state = createRound(timeline);

    // FALSE_MARK at t=1000 sets confusedUntil=4000
    state = markAt(state, 1000);
    expect(state.session.confusedUntil).toBe(1000 + CONFUSE_MS);

    // Now PERFECT-mark all attempts to reach mastery
    for (const ev of timeline.filter(e => e.kind === 'attempt')) {
      state = markAt(state, ev.attempt!.peak);
    }
    expect(state.session.mastered).toBe(true);

    // At t=2000 the confuse window is still active (ends 4000), but mastered wins
    const result: DogVisual = dogVisualState(state, 2000);
    expect(result).toBe('happy');
  });

  it('confused overrides offering: confused when both an attempt is active and confused', () => {
    let state = freshRound();
    // FALSE_MARK at t=1000 sets confusedUntil=4000
    state = markAt(state, 1000);
    // At t=2000 there is an active attempt (second attempt: activeStart=2000, activeEnd=2800)
    // and we are still confused (confusedUntil=4000 > 2000)
    const result: DogVisual = dogVisualState(state, 2000);
    expect(result).toBe('confused');
  });

  it('offering overrides idle: returns offering not idle when an attempt is active', () => {
    const state = freshRound();
    // t=400 is inside first attempt (activeStart=0, activeEnd=800)
    const result: DogVisual = dogVisualState(state, 400);
    expect(result).toBe('offering');
  });
});

// ─── Untraining: misbehaving during distractor; normal tricks unaffected ──────

describe('dogVisualState — untraining (opts.untrain)', () => {
  // Timeline: one distractor [500,900], one attempt [2000,2800], calm gap around t=1400
  const distractor: TimelineEvent = { kind: 'distractor', activeStart: 500, activeEnd: 900 };
  const attemptEvent: TimelineEvent = {
    kind: 'attempt',
    activeStart: 2000,
    activeEnd: 2800,
    attempt: { start: 2200, end: 2600, peak: 2400, peakRadius: 80 },
  };

  function untrainRound(): RoundState {
    return createRound([distractor, attemptEvent]);
  }

  it('returns misbehaving during a distractor window in untraining mode', () => {
    const state = untrainRound();
    // t=700 inside distractor [500,900]; untrain=true → misbehaving
    const result: DogVisual = dogVisualState(state, 700, { untrain: true });
    expect(result).toBe('misbehaving');
  });

  it('returns offering during a calm gap in untraining mode', () => {
    const state = untrainRound();
    // t=1400 is in the calm gap (distractor ends 900, attempt starts 2000)
    const result: DogVisual = dogVisualState(state, 1400, { untrain: true });
    expect(result).toBe('offering');
  });

  it('returns idle during the normal attempt window in untraining mode (not markable)', () => {
    const state = untrainRound();
    // t=2400 inside attempt [2000,2800]; in untraining this is not a calm gap → idle
    const result: DogVisual = dogVisualState(state, 2400, { untrain: true });
    expect(result).toBe('idle');
  });

  it('normal tricks are UNAFFECTED — distractor still returns distractor without opts', () => {
    const state = untrainRound();
    // Without untrain opts: t=700 → distractor (existing behavior)
    const result: DogVisual = dogVisualState(state, 700);
    expect(result).toBe('distractor');
  });

  it('normal tricks are UNAFFECTED — offering still returns offering without opts', () => {
    const state = untrainRound();
    // Without untrain opts: t=2400 inside attempt → offering
    const result: DogVisual = dogVisualState(state, 2400);
    expect(result).toBe('offering');
  });

  it('mastered still wins over misbehaving in untraining mode', () => {
    // Build enough attempts to reach mastery
    const manyAttempts = buildTimeline(BASE_CFG, (function seqRng(values: number[]) {
      let i = 0; return () => values[i++ % values.length];
    })([0]), 13);
    let state = createRound([
      ...manyAttempts,
      { kind: 'distractor', activeStart: 0, activeEnd: 99999 },
    ]);
    for (const ev of manyAttempts.filter(e => e.kind === 'attempt')) {
      state = markAt(state, ev.attempt!.peak);
    }
    expect(state.session.mastered).toBe(true);
    const result: DogVisual = dogVisualState(state, 5000, { untrain: true });
    expect(result).toBe('happy');
  });
});

// ─── Disengagement (107): opts.disengaged → 'disengaged' (walk-off, procedural) ─

describe('dogVisualState — disengaged (walk-off)', () => {
  it('returns disengaged when opts.disengaged is set, overriding an active attempt', () => {
    const state = freshRound();
    // t=400 is inside the first attempt window → would be 'offering' normally
    const result: DogVisual = dogVisualState(state, 400, { disengaged: true });
    expect(result).toBe('disengaged');
  });

  it('returns disengaged over an idle gap (tellable apart from idle)', () => {
    const state = freshRound();
    const result: DogVisual = dogVisualState(state, 10000, { disengaged: true });
    expect(result).toBe('disengaged');
  });

  it('returns disengaged over an active distractor (distinct from distractor)', () => {
    const distractor: TimelineEvent = { kind: 'distractor', activeStart: 500, activeEnd: 900 };
    const state = createRound([distractor]);
    expect(dogVisualState(state, 700)).toBe('distractor'); // baseline
    expect(dogVisualState(state, 700, { disengaged: true })).toBe('disengaged');
  });

  it('does NOT disengage when opts.disengaged is false/absent (normal play)', () => {
    const state = freshRound();
    expect(dogVisualState(state, 400, { disengaged: false })).toBe('offering');
    expect(dogVisualState(state, 400)).toBe('offering');
  });

  it('mastered (happy) still wins over disengaged — a won round is never "walked off"', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 13);
    let state = createRound(timeline);
    for (const ev of timeline.filter(e => e.kind === 'attempt')) {
      state = markAt(state, ev.attempt!.peak);
    }
    expect(state.session.mastered).toBe(true);
    expect(dogVisualState(state, 30000, { disengaged: true })).toBe('happy');
  });
});

// ─── Disengage beats (112): opts.beat → itch/flop/bark over idle lulls only ────
//
// The engagement meter's graded escalation (engaged→itch→flop→bark→walk-off) must
// read on the DOG, not only the HUD pill (spec §"Wrong-behavior beats"). The
// intermediate beats surface during idle lulls — they never mask an active correct
// `offering` (the player must always be able to read the markable behavior) and yield
// to confused / disengaged (walk-off) / mastered. The empty-meter `walk-off` is handled
// by opts.disengaged (task 107), so the beat tail only routes itch/flop/bark.

describe('dogVisualState — disengage beats (itch/flop/bark)', () => {
  it('returns itch over an idle lull when beat is itch', () => {
    const state = freshRound();
    expect(dogVisualState(state, 10000, { beat: 'itch' })).toBe('itch');
  });

  it('returns flop over an idle lull when beat is flop', () => {
    const state = freshRound();
    expect(dogVisualState(state, 10000, { beat: 'flop' })).toBe('flop');
  });

  it('returns bark over an idle lull when beat is bark', () => {
    const state = freshRound();
    expect(dogVisualState(state, 10000, { beat: 'bark' })).toBe('bark');
  });

  it('stays idle when the dog is still engaged (beat=engaged)', () => {
    const state = freshRound();
    expect(dogVisualState(state, 10000, { beat: 'engaged' })).toBe('idle');
  });

  it('stays idle when no beat is provided (back-compat)', () => {
    const state = freshRound();
    expect(dogVisualState(state, 10000)).toBe('idle');
  });

  it('a beat NEVER masks an active correct attempt — offering still wins', () => {
    const state = freshRound();
    // t=400 is inside the first attempt window → must read as the markable behavior
    expect(dogVisualState(state, 400, { beat: 'bark' })).toBe('offering');
  });

  it('a distractor still reads as distractor — beats replace idle only (D9)', () => {
    const distractor: TimelineEvent = { kind: 'distractor', activeStart: 500, activeEnd: 900 };
    const state = createRound([distractor]);
    expect(dogVisualState(state, 700, { beat: 'flop' })).toBe('distractor');
  });

  it('disengaged (walk-off) wins over any beat', () => {
    const state = freshRound();
    expect(dogVisualState(state, 10000, { beat: 'itch', disengaged: true })).toBe('disengaged');
  });

  it('confused wins over a beat', () => {
    let state = freshRound();
    state = markAt(state, 1000); // FALSE_MARK → confusedUntil = 1000 + CONFUSE_MS
    expect(dogVisualState(state, 2000, { beat: 'bark' })).toBe('confused');
  });

  it('mastered (happy) wins over a beat', () => {
    const timeline = buildTimeline(BASE_CFG, seqRng([0]), 13);
    let state = createRound(timeline);
    for (const ev of timeline.filter(e => e.kind === 'attempt')) {
      state = markAt(state, ev.attempt!.peak);
    }
    expect(state.session.mastered).toBe(true);
    expect(dogVisualState(state, 30000, { beat: 'flop' })).toBe('happy');
  });
});

// ─── Down-family trick predicate (task 120) ──────────────────────────────────
// The "down" tricks — Ligg, Legg deg, and the play-dead Sov — must read as a
// distinct lie-down, not the generic upright sit, on the imported dog (D6/D11).
// This predicate is the single tested home for that rule.
describe('isDownFamilyTrick', () => {
  it('is true for the lie-down tricks (ligg, legg-deg, sov)', () => {
    expect(isDownFamilyTrick('ligg')).toBe(true);
    expect(isDownFamilyTrick('legg-deg')).toBe(true);
    expect(isDownFamilyTrick('sov')).toBe(true);
  });

  it('is false for upright/other tricks (sitt, rull)', () => {
    expect(isDownFamilyTrick('sitt')).toBe(false);
    expect(isDownFamilyTrick('rull')).toBe(false);
  });

  it('is false for an absent/unknown trick id', () => {
    expect(isDownFamilyTrick(undefined)).toBe(false);
    expect(isDownFamilyTrick('no-jump')).toBe(false);
  });
});
