import { describe, it, expect } from 'vitest';
import { onboardingStage, untrainTricksUnlocked, shouldCoachCoreVerb, shouldCoachDistractors, shouldShowIdleWelcome } from './onboarding';

// ─── Cycle 1: first-run coach — fresh player sees the core-verb coach ─────────

describe('shouldCoachCoreVerb — fresh first run', () => {
  it('coaches a brand-new player (nothing mastered, no mark yet)', () => {
    expect(shouldCoachCoreVerb({ masteredCount: 0, hasMarkedSuccessfully: false })).toBe(true);
  });
});

// ─── Cycle 2: auto-dismiss — coach hides after the first successful mark ──────

describe('shouldCoachCoreVerb — after the first mark', () => {
  it('stops coaching once the player has landed a successful mark', () => {
    expect(shouldCoachCoreVerb({ masteredCount: 0, hasMarkedSuccessfully: true })).toBe(false);
  });
});

// ─── Cycle 3: returning player — never coach once anything is mastered ────────

describe('shouldCoachCoreVerb — returning player', () => {
  it('never coaches a player who has already mastered a trick', () => {
    expect(shouldCoachCoreVerb({ masteredCount: 1, hasMarkedSuccessfully: false })).toBe(false);
    expect(shouldCoachCoreVerb({ masteredCount: 5, hasMarkedSuccessfully: true })).toBe(false);
  });
});

// ─── Cycle 1: distractor coach — first distractor-enabled round ───────────────

describe('shouldCoachDistractors — first distractor round', () => {
  it('coaches at the distractor-reveal band (1 mastered, not yet dismissed)', () => {
    expect(shouldCoachDistractors({ masteredCount: 1, dismissed: false })).toBe(true);
  });

  it('does not coach a brand-new player (0 mastered — core-verb stage owns the screen)', () => {
    expect(shouldCoachDistractors({ masteredCount: 0, dismissed: false })).toBe(false);
  });

  it('stops coaching once dismissed (first scoring mark of the round)', () => {
    expect(shouldCoachDistractors({ masteredCount: 1, dismissed: true })).toBe(false);
  });

  it('never coaches an experienced trainer (distractors no longer new at ≥ 2)', () => {
    expect(shouldCoachDistractors({ masteredCount: 2, dismissed: false })).toBe(false);
    expect(shouldCoachDistractors({ masteredCount: 5, dismissed: false })).toBe(false);
  });
});

// ─── Cross-gate guard: core-verb and distractor coaches are mutually exclusive ─

describe('coach gates — never both visible', () => {
  it('the two coach bands never overlap across the masteredCount range', () => {
    for (let masteredCount = 0; masteredCount <= 4; masteredCount++) {
      const verb = shouldCoachCoreVerb({ masteredCount, hasMarkedSuccessfully: false });
      const dist = shouldCoachDistractors({ masteredCount, dismissed: false });
      expect(verb && dist).toBe(false);
    }
  });
});

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

// ─── shouldShowIdleWelcome — surface the "welcome back" idle-income toast ──────
// Idle income is granted at load (kennel idle trickle); the toast announcing it
// must only appear when something accrued AND the economy stage is revealed (so a
// brand-new player, whose coins are still hidden, never sees a coin toast).

describe('shouldShowIdleWelcome', () => {
  it('shows when idle income accrued and the economy stage is revealed', () => {
    expect(shouldShowIdleWelcome({ earnedCoins: 12, economyRevealed: true })).toBe(true);
  });

  it('does not show when nothing accrued (earnedCoins 0)', () => {
    expect(shouldShowIdleWelcome({ earnedCoins: 0, economyRevealed: true })).toBe(false);
  });

  it('does not show on a fresh run when the economy stage is still hidden', () => {
    expect(shouldShowIdleWelcome({ earnedCoins: 30, economyRevealed: false })).toBe(false);
  });

  it('does not show when both gates fail (no income, not revealed)', () => {
    expect(shouldShowIdleWelcome({ earnedCoins: 0, economyRevealed: false })).toBe(false);
  });
});
