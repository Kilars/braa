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

/**
 * First-run coach gate (specs.md §Onboarding: "The first session teaches the one
 * core verb — wait for the apex, tap BRA"). Show an in-context coach only to a
 * brand-new player who has not yet landed a successful mark; it auto-dismisses on
 * the first scoring mark and never returns once anything is mastered, so it never
 * nags. Pure — no DOM.
 */
export function shouldCoachCoreVerb(progress: {
  masteredCount: number;
  hasMarkedSuccessfully: boolean;
}): boolean {
  return progress.masteredCount === 0 && !progress.hasMarkedSuccessfully;
}

/**
 * Contextual coach for the first distractor-enabled round (specs.md §Onboarding:
 * systems are "revealed in stages … distractors arrive around the second trick").
 * At `masteredCount === 1` the dog starts offering *wrong* behaviors the player
 * must NOT mark; without a cue a false-mark penalty just reads as confusing. Show
 * a one-line "don't mark the wrong behavior" pill only in that single band — never
 * to a fresh player (count 0, the core-verb stage owns the screen) nor to an
 * experienced trainer (count ≥ 2, distractors are no longer new). Auto-dismisses
 * on the first scoring mark of the round via the transient `dismissed` flag. Pure
 * — no DOM. Mirrors {@link shouldCoachCoreVerb}; the two bands are mutually
 * exclusive by `masteredCount`, so the pills never show simultaneously.
 */
export function shouldCoachDistractors(progress: {
  masteredCount: number;
  dismissed: boolean;
}): boolean {
  return progress.masteredCount === 1 && !progress.dismissed;
}

/**
 * Gate for the "welcome back" idle-income toast (specs.md §Kennel: a small,
 * capped passive idle trickle "collected on return"). The trickle is already
 * granted at load; this decides whether to *announce* it. Show only when coins
 * actually accrued AND the economy stage is revealed — a brand-new player's coins
 * are still hidden (staged reveal), so a coin toast then would leak the economy
 * before its first payout. Pure — no DOM.
 */
export function shouldShowIdleWelcome(p: {
  earnedCoins: number;
  economyRevealed: boolean;
}): boolean {
  return p.earnedCoins > 0 && p.economyRevealed;
}
