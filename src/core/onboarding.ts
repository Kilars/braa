/**
 * Onboarding staged reveal — pure, no DOM.
 *
 * Systems are revealed progressively as the player masters more tricks,
 * so the first session stays focused on the single core verb (tap BRA at the
 * right moment) and complexity drips in only after it has been experienced.
 *
 * Staging thresholds:
 *   0 mastered  → all gated (bare bar + BRA + coins only)
 *   ≥ 1 mastered → distractors + economy revealed (first payout has happened)
 *   ≥ 2 mastered → phrases chip revealed
 *   ≥ 3 mastered → difficulty selector + kennel revealed
 *
 * All flags are monotonic: once true, they stay true for higher counts.
 */

export interface Revealed {
  distractors: boolean;
  phrases: boolean;
  economy: boolean;
  kennel: boolean;
  difficulty: boolean;
}

export function onboardingStage(masteredCount: number): Revealed {
  return {
    distractors: masteredCount >= 1,
    phrases: masteredCount >= 2,
    economy: masteredCount >= 1,
    kennel: masteredCount >= 3,
    difficulty: masteredCount >= 3,
  };
}

/**
 * Untraining is a post-v1 "later addition"; gated off for the v1 build.
 * Flip this condition when untraining is formally introduced post-v1.
 */
export function untrainTricksUnlocked(_masteredCount: number): boolean {
  return false; // v1: never surface untrain tricks in select
}
