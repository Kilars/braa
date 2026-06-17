import { describe, it, expect } from 'vitest';
import { effectiveDifficulty, applyTrickProfile, confuseDifficulty, type EffectiveDifficulty } from './difficulty';
import { NORMAL_DELTAS } from './mark';
import type { Trick } from './tricks';

import { applyMark, newSession } from './session';

// ─── Cycle 1: NORMAL baseline ─────────────────────────────────────────────────

describe('effectiveDifficulty NORMAL — baseline', () => {
  it('returns rewardMultiplier of 1', () => {
    expect(effectiveDifficulty('NORMAL').rewardMultiplier).toBe(1);
  });

  it('returns deltas equal to NORMAL_DELTAS', () => {
    expect(effectiveDifficulty('NORMAL').deltas).toEqual(NORMAL_DELTAS);
  });

  it('returns tellIntensity of 1 (clearest/loudest tell)', () => {
    expect(effectiveDifficulty('NORMAL').tellIntensity).toBe(1);
  });
});

// ─── Cycle 2: HARD is strictly harsher than NORMAL on every axis ──────────────

describe('effectiveDifficulty HARD — stricter than NORMAL', () => {
  it('has a narrower windowWidth than NORMAL', () => {
    expect(effectiveDifficulty('HARD').scheduler.windowWidth)
      .toBeLessThan(effectiveDifficulty('NORMAL').scheduler.windowWidth);
  });

  it('has a smaller peakRadius than NORMAL', () => {
    expect(effectiveDifficulty('HARD').scheduler.peakRadius)
      .toBeLessThan(effectiveDifficulty('NORMAL').scheduler.peakRadius);
  });

  it('has a higher distractorRate than NORMAL', () => {
    expect(effectiveDifficulty('HARD').scheduler.distractorRate)
      .toBeGreaterThan(effectiveDifficulty('NORMAL').scheduler.distractorRate);
  });

  it('has a more-negative FALSE_MARK delta than NORMAL', () => {
    expect(effectiveDifficulty('HARD').deltas.FALSE_MARK)
      .toBeLessThan(effectiveDifficulty('NORMAL').deltas.FALSE_MARK);
  });

  it('has a higher rewardMultiplier than NORMAL', () => {
    expect(effectiveDifficulty('HARD').rewardMultiplier)
      .toBeGreaterThan(effectiveDifficulty('NORMAL').rewardMultiplier);
  });

  it('has a lower tellIntensity than NORMAL (fainter/faster tell)', () => {
    expect(effectiveDifficulty('HARD').tellIntensity)
      .toBeLessThan(effectiveDifficulty('NORMAL').tellIntensity);
  });
});

// ─── Cycle 3: EXPERT is strictly harsher than HARD on every axis (monotonic) ──

describe('effectiveDifficulty EXPERT — stricter than HARD', () => {
  it('has a narrower windowWidth than HARD', () => {
    expect(effectiveDifficulty('EXPERT').scheduler.windowWidth)
      .toBeLessThan(effectiveDifficulty('HARD').scheduler.windowWidth);
  });

  it('has a smaller peakRadius than HARD', () => {
    expect(effectiveDifficulty('EXPERT').scheduler.peakRadius)
      .toBeLessThan(effectiveDifficulty('HARD').scheduler.peakRadius);
  });

  it('has a higher distractorRate than HARD', () => {
    expect(effectiveDifficulty('EXPERT').scheduler.distractorRate)
      .toBeGreaterThan(effectiveDifficulty('HARD').scheduler.distractorRate);
  });

  it('has a more-negative FALSE_MARK delta than HARD', () => {
    expect(effectiveDifficulty('EXPERT').deltas.FALSE_MARK)
      .toBeLessThan(effectiveDifficulty('HARD').deltas.FALSE_MARK);
  });

  it('has a higher rewardMultiplier than HARD', () => {
    expect(effectiveDifficulty('EXPERT').rewardMultiplier)
      .toBeGreaterThan(effectiveDifficulty('HARD').rewardMultiplier);
  });

  it('has a lower tellIntensity than HARD (even fainter/faster tell)', () => {
    expect(effectiveDifficulty('EXPERT').tellIntensity)
      .toBeLessThan(effectiveDifficulty('HARD').tellIntensity);
  });
});

// ─── Cycle 3b: Specific constant values (tuning §7 — applied) ─────────────────

describe('effectiveDifficulty — specific tuned constant values', () => {
  it('EXPERT FALSE_MARK delta is −10', () => {
    expect(effectiveDifficulty('EXPERT').deltas.FALSE_MARK).toBe(-10);
  });

  it('EXPERT distractorRate is 0.55', () => {
    expect(effectiveDifficulty('EXPERT').scheduler.distractorRate).toBe(0.55);
  });

  it('HARD rewardMultiplier is 1.3', () => {
    expect(effectiveDifficulty('HARD').rewardMultiplier).toBe(1.3);
  });
});

// ─── Cycle 4: Integration — FALSE_MARK under HARD/EXPERT hurts more ───────────

describe('applyMark integration — difficulty-scaled deltas', () => {
  it('FALSE_MARK under HARD subtracts more than under NORMAL', () => {
    const normalDeltas = effectiveDifficulty('NORMAL').deltas;
    const hardDeltas = effectiveDifficulty('HARD').deltas;
    const startState = { learned: 50, confusedUntil: null, mastered: false };

    const afterNormal = applyMark(startState, 'FALSE_MARK', 0, normalDeltas);
    const afterHard = applyMark(startState, 'FALSE_MARK', 0, hardDeltas);

    expect(afterHard.learned).toBeLessThan(afterNormal.learned);
  });

  it('FALSE_MARK under EXPERT subtracts more than under HARD', () => {
    const hardDeltas = effectiveDifficulty('HARD').deltas;
    const expertDeltas = effectiveDifficulty('EXPERT').deltas;
    const startState = { learned: 50, confusedUntil: null, mastered: false };

    const afterHard = applyMark(startState, 'FALSE_MARK', 0, hardDeltas);
    const afterExpert = applyMark(startState, 'FALSE_MARK', 0, expertDeltas);

    expect(afterExpert.learned).toBeLessThan(afterHard.learned);
  });

  it('existing call sites work unchanged — NORMAL default when no deltas given', () => {
    const s = applyMark({ learned: 10, confusedUntil: null, mastered: false }, 'FALSE_MARK', 0);
    // NORMAL delta for FALSE_MARK = -4, so 10 - 4 = 6
    expect(s.learned).toBe(6);
  });
});

// ─── Cycle 5: applyTrickProfile — baseline trick = identity ──────────────────

const BASELINE_TRICK: Trick = {
  id: 'baseline',
  name: 'Baseline',
  learnMult: 1,
  windowMult: 1,
  distractorBonus: 0,
};

const HARD_TRICK: Trick = {
  id: 'hard',
  name: 'Hard',
  learnMult: 0.5,
  windowMult: 0.6,
  distractorBonus: 0.2,
};

describe('applyTrickProfile — baseline trick is identity', () => {
  it('returns the same scheduler values when trick is baseline', () => {
    const eff = effectiveDifficulty('NORMAL');
    const result = applyTrickProfile(eff, BASELINE_TRICK);
    expect(result.scheduler).toEqual(eff.scheduler);
  });

  it('returns the same deltas when trick is baseline', () => {
    const eff = effectiveDifficulty('NORMAL');
    const result = applyTrickProfile(eff, BASELINE_TRICK);
    expect(result.deltas).toEqual(eff.deltas);
  });

  it('returns the same learnMult=1 when trick is baseline', () => {
    const eff = effectiveDifficulty('NORMAL');
    const result = applyTrickProfile(eff, BASELINE_TRICK);
    expect(result.learnMult).toBe(1);
  });
});

// ─── Cycle 6: applyTrickProfile — hard trick tightens window + adds distractors ─

describe('applyTrickProfile — hard trick', () => {
  it('reduces windowWidth by windowMult', () => {
    const eff = effectiveDifficulty('NORMAL');
    const result = applyTrickProfile(eff, HARD_TRICK);
    expect(result.scheduler.windowWidth).toBeLessThan(eff.scheduler.windowWidth);
    expect(result.scheduler.windowWidth).toBeCloseTo(eff.scheduler.windowWidth * HARD_TRICK.windowMult);
  });

  it('reduces peakRadius by windowMult', () => {
    const eff = effectiveDifficulty('NORMAL');
    const result = applyTrickProfile(eff, HARD_TRICK);
    expect(result.scheduler.peakRadius).toBeLessThan(eff.scheduler.peakRadius);
    expect(result.scheduler.peakRadius).toBeCloseTo(eff.scheduler.peakRadius * HARD_TRICK.windowMult);
  });

  it('increases distractorRate by distractorBonus (clamped to 1)', () => {
    const eff = effectiveDifficulty('NORMAL');
    const result = applyTrickProfile(eff, HARD_TRICK);
    expect(result.scheduler.distractorRate).toBeGreaterThan(eff.scheduler.distractorRate);
    expect(result.scheduler.distractorRate).toBeCloseTo(
      Math.min(1, eff.scheduler.distractorRate + HARD_TRICK.distractorBonus)
    );
  });

  it('exposes learnMult from the trick for bar-fill scaling', () => {
    const eff = effectiveDifficulty('NORMAL');
    const result = applyTrickProfile(eff, HARD_TRICK);
    expect(result.learnMult).toBe(HARD_TRICK.learnMult);
  });

  it('distractorRate clamps to 1.0 when distractorBonus would exceed it', () => {
    const eff = effectiveDifficulty('EXPERT'); // distractorRate=0.7
    const bigBonus: Trick = { ...HARD_TRICK, distractorBonus: 0.5 };
    const result = applyTrickProfile(eff, bigBonus);
    expect(result.scheduler.distractorRate).toBe(1);
  });
});

// ─── Cycle 7: confuseDifficulty — false-mark confuse debuff ─────────────────────

describe('confuseDifficulty — confuse debuff transform (window −40%, distractors +50%)', () => {
  it('narrows windowWidth to 0.6× the input', () => {
    const eff = effectiveDifficulty('NORMAL'); // windowWidth = 400
    const confused = confuseDifficulty(eff);
    expect(confused.scheduler.windowWidth).toBeCloseTo(eff.scheduler.windowWidth * 0.6);
    expect(confused.scheduler.windowWidth).toBeCloseTo(240);
  });

  it('narrows peakRadius to 0.6× the input', () => {
    const eff = effectiveDifficulty('NORMAL'); // peakRadius = 80
    const confused = confuseDifficulty(eff);
    expect(confused.scheduler.peakRadius).toBeCloseTo(eff.scheduler.peakRadius * 0.6);
    expect(confused.scheduler.peakRadius).toBeCloseTo(48);
  });

  it('increases distractorRate to 1.5× the input', () => {
    const eff = effectiveDifficulty('NORMAL'); // distractorRate = 0.2
    const confused = confuseDifficulty(eff);
    expect(confused.scheduler.distractorRate).toBeCloseTo(eff.scheduler.distractorRate * 1.5);
    expect(confused.scheduler.distractorRate).toBeCloseTo(0.3);
  });

  it('caps distractorRate at 1 when 1.5× would exceed it', () => {
    const eff = effectiveDifficulty('EXPERT'); // distractorRate = 0.55
    const confused = confuseDifficulty(eff);
    // 0.55 * 1.5 = 0.825, still under 1, so should be 0.825
    expect(confused.scheduler.distractorRate).toBeCloseTo(0.55 * 1.5);
    expect(confused.scheduler.distractorRate).toBeLessThan(1);
  });

  it('caps distractorRate at exactly 1.0 when multiplied rate exceeds cap', () => {
    const eff: EffectiveDifficulty = {
      scheduler: { windowWidth: 400, peakRadius: 80, distractorRate: 0.8 },
      deltas: { ...NORMAL_DELTAS },
      rewardMultiplier: 1,
      tellIntensity: 1,
      learnMult: 1,
    };
    const confused = confuseDifficulty(eff);
    // 0.8 * 1.5 = 1.2 > 1, so should cap to 1.0
    expect(confused.scheduler.distractorRate).toBe(1);
  });

  it('preserves non-scheduler fields (deltas, rewardMultiplier, tellIntensity, learnMult)', () => {
    const eff = effectiveDifficulty('HARD');
    const confused = confuseDifficulty(eff);
    expect(confused.deltas).toEqual(eff.deltas);
    expect(confused.rewardMultiplier).toBe(eff.rewardMultiplier);
    expect(confused.tellIntensity).toBe(eff.tellIntensity);
    expect(confused.learnMult).toBe(eff.learnMult);
  });

  it('is pure/immutable — input object is unchanged', () => {
    const eff = effectiveDifficulty('NORMAL');
    const originalWindowWidth = eff.scheduler.windowWidth;
    const originalPeakRadius = eff.scheduler.peakRadius;
    const originalDistractorRate = eff.scheduler.distractorRate;

    confuseDifficulty(eff);

    expect(eff.scheduler.windowWidth).toBe(originalWindowWidth);
    expect(eff.scheduler.peakRadius).toBe(originalPeakRadius);
    expect(eff.scheduler.distractorRate).toBe(originalDistractorRate);
  });

  it('composes with applyTrickProfile (confuse then trick)', () => {
    const eff = effectiveDifficulty('NORMAL');
    const confused = confuseDifficulty(eff);
    const confusedThenTrick = applyTrickProfile(confused, HARD_TRICK);

    // Should have both the confuse window tightening and the trick's window tightening
    const confuseWindowMult = 0.6;
    const expectedConfuseWindow = eff.scheduler.windowWidth * confuseWindowMult;
    const expectedFinalWindow = expectedConfuseWindow * HARD_TRICK.windowMult;

    expect(confusedThenTrick.scheduler.windowWidth).toBeCloseTo(expectedFinalWindow);
  });

  it('composes with applyTrickProfile (trick then confuse)', () => {
    const eff = effectiveDifficulty('NORMAL');
    const tricked = applyTrickProfile(eff, HARD_TRICK);
    const trickedThenConfused = confuseDifficulty(tricked);

    // Should have both the trick's window tightening and the confuse window tightening
    const expectedFinalWindow = eff.scheduler.windowWidth * HARD_TRICK.windowMult * 0.6;

    expect(trickedThenConfused.scheduler.windowWidth).toBeCloseTo(expectedFinalWindow);
  });
});
