import { describe, it, expect } from 'vitest';
import { onboardingStage, untrainTricksUnlocked } from './onboarding';

// ─── Cycle 1: 0 mastered — all flags false ────────────────────────────────────

describe('onboardingStage(0)', () => {
  it('reveals nothing when no tricks have been mastered', () => {
    const stage = onboardingStage(0);
    expect(stage.distractors).toBe(false);
    expect(stage.phrases).toBe(false);
    expect(stage.economy).toBe(false);
    expect(stage.kennel).toBe(false);
    expect(stage.difficulty).toBe(false);
  });
});

// ─── Cycle 2: ≥1 mastered — distractors + economy revealed ───────────────────

describe('onboardingStage(1)', () => {
  it('reveals distractors after first mastery (payout has fired)', () => {
    expect(onboardingStage(1).distractors).toBe(true);
  });

  it('reveals economy after first mastery (first payout happened)', () => {
    expect(onboardingStage(1).economy).toBe(true);
  });

  it('keeps phrases hidden at count 1', () => {
    expect(onboardingStage(1).phrases).toBe(false);
  });

  it('keeps kennel hidden at count 1', () => {
    expect(onboardingStage(1).kennel).toBe(false);
  });

  it('keeps difficulty hidden at count 1', () => {
    expect(onboardingStage(1).difficulty).toBe(false);
  });
});

// ─── Cycle 3: ≥2 mastered — phrases revealed ──────────────────────────────────

describe('onboardingStage(2)', () => {
  it('reveals phrases at count 2', () => {
    expect(onboardingStage(2).phrases).toBe(true);
  });

  it('keeps kennel hidden at count 2', () => {
    expect(onboardingStage(2).kennel).toBe(false);
  });

  it('keeps difficulty hidden at count 2', () => {
    expect(onboardingStage(2).difficulty).toBe(false);
  });

  it('still reveals distractors and economy at count 2 (monotonic)', () => {
    const stage = onboardingStage(2);
    expect(stage.distractors).toBe(true);
    expect(stage.economy).toBe(true);
  });
});

// ─── Cycle 4: ≥3 mastered — difficulty + kennel revealed ─────────────────────

describe('onboardingStage(3)', () => {
  it('reveals difficulty at count 3', () => {
    expect(onboardingStage(3).difficulty).toBe(true);
  });

  it('reveals kennel at count 3', () => {
    expect(onboardingStage(3).kennel).toBe(true);
  });

  it('still reveals all earlier flags at count 3 (monotonic)', () => {
    const stage = onboardingStage(3);
    expect(stage.distractors).toBe(true);
    expect(stage.economy).toBe(true);
    expect(stage.phrases).toBe(true);
  });
});

// ─── Cycle 5: high count — everything revealed (full monotonic check) ─────────

describe('onboardingStage(high count)', () => {
  it('reveals all flags at count 10', () => {
    const stage = onboardingStage(10);
    expect(stage.distractors).toBe(true);
    expect(stage.phrases).toBe(true);
    expect(stage.economy).toBe(true);
    expect(stage.kennel).toBe(true);
    expect(stage.difficulty).toBe(true);
  });

  it('exact boundary: count 2 does NOT yet reveal kennel', () => {
    expect(onboardingStage(2).kennel).toBe(false);
  });

  it('exact boundary: count 2 does NOT yet reveal difficulty', () => {
    expect(onboardingStage(2).difficulty).toBe(false);
  });

  it('exact boundary: count 1 does NOT yet reveal phrases', () => {
    expect(onboardingStage(1).phrases).toBe(false);
  });
});

// ─── Regression guard: existing onboardingStage reveals unchanged ────────────────

describe('onboardingStage — regression guard (untraining gate unchanged)', () => {
  it('onboardingStage(0) still has all five flags false', () => {
    const stage = onboardingStage(0);
    expect(stage.distractors).toBe(false);
    expect(stage.phrases).toBe(false);
    expect(stage.economy).toBe(false);
    expect(stage.kennel).toBe(false);
    expect(stage.difficulty).toBe(false);
  });

  it('onboardingStage(3) still reveals kennel and difficulty', () => {
    const stage = onboardingStage(3);
    expect(stage.kennel).toBe(true);
    expect(stage.difficulty).toBe(true);
  });
});

// ─── Cycle 1: untrainTricksUnlocked — fresh player (0 mastered) ─────────────────

describe('untrainTricksUnlocked(0)', () => {
  it('returns false when no tricks have been mastered (fresh player)', () => {
    expect(untrainTricksUnlocked(0)).toBe(false);
  });
});

// ─── Cycle 2: untrainTricksUnlocked — v1 range (mastered 1..10) ─────────────────

describe('untrainTricksUnlocked(v1 range)', () => {
  it('returns false across entire v1 range', () => {
    const v1Range = [0, 1, 2, 3, 5, 10];
    v1Range.forEach(masteredCount => {
      expect(untrainTricksUnlocked(masteredCount)).toBe(false);
    });
  });

  it('returns false at count 1 (first mastery)', () => {
    expect(untrainTricksUnlocked(1)).toBe(false);
  });

  it('returns false at count 2 (second mastery)', () => {
    expect(untrainTricksUnlocked(2)).toBe(false);
  });

  it('returns false at count 3 (kennel unlocked)', () => {
    expect(untrainTricksUnlocked(3)).toBe(false);
  });

  it('returns false at count 5 (well into progression)', () => {
    expect(untrainTricksUnlocked(5)).toBe(false);
  });

  it('returns false at count 10 (high v1 progression)', () => {
    expect(untrainTricksUnlocked(10)).toBe(false);
  });
});
