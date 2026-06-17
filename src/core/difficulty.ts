import { MarkResult, NORMAL_DELTAS } from './mark';
import { SchedulerConfig } from './scheduler';
import type { Trick } from './tricks';

export type DifficultyMode = 'NORMAL' | 'HARD' | 'EXPERT';

export interface EffectiveDifficulty {
  scheduler: Pick<SchedulerConfig, 'windowWidth' | 'peakRadius' | 'distractorRate'>;
  deltas: Record<MarkResult, number>;
  rewardMultiplier: number; // NORMAL = 1, HARD > 1, EXPERT > HARD
  tellIntensity: number;    // 1 = clearest apex pulse; lower = fainter/faster
  learnMult: number;        // 1 = baseline; <1 slower bar fill (applied from trick profile)
}

// Normal baseline scheduler values (matching SchedulerConfig defaults used in tests)
const NORMAL_SCHEDULER: Pick<SchedulerConfig, 'windowWidth' | 'peakRadius' | 'distractorRate'> = {
  windowWidth: 400,
  peakRadius: 80,
  distractorRate: 0.2,
};

export function effectiveDifficulty(mode: DifficultyMode): EffectiveDifficulty {
  switch (mode) {
    case 'NORMAL':
      return {
        scheduler: { ...NORMAL_SCHEDULER },
        deltas: { ...NORMAL_DELTAS },
        rewardMultiplier: 1,
        tellIntensity: 1,
        learnMult: 1,
      };

    case 'HARD':
      return {
        scheduler: {
          windowWidth: 280,      // tighter than NORMAL 400
          peakRadius: 50,        // tighter than NORMAL 80
          distractorRate: 0.45,  // higher than NORMAL 0.2
        },
        deltas: {
          ...NORMAL_DELTAS,
          FALSE_MARK: -8,        // harsher than NORMAL -4
        },
        rewardMultiplier: 1.3,   // higher than NORMAL 1
        tellIntensity: 0.6,      // fainter than NORMAL 1
        learnMult: 1,
      };

    case 'EXPERT':
      return {
        scheduler: {
          windowWidth: 160,      // tighter than HARD 280
          peakRadius: 25,        // tighter than HARD 50
          distractorRate: 0.55,  // higher than HARD 0.45
        },
        deltas: {
          ...NORMAL_DELTAS,
          FALSE_MARK: -10,       // harsher than HARD -8
        },
        rewardMultiplier: 2.5,   // higher than HARD 1.5
        tellIntensity: 0.3,      // fainter than HARD 0.6
        learnMult: 1,
      };
  }
}

/**
 * Apply a trick's difficulty profile to an existing EffectiveDifficulty.
 * Pure and immutable — returns a new object; does not mutate `eff`.
 *
 * Baseline trick (learnMult=1, windowMult=1, distractorBonus=0) is identity.
 * Hard trick: tighter window (×windowMult), more distractors (+bonus, ≤1),
 * slower bar-fill via learnMult scaling positive deltas (PERFECT, OK) and
 * exposed as result.learnMult for main.ts.
 */
export function applyTrickProfile(eff: EffectiveDifficulty, trick: Trick): EffectiveDifficulty {
  return {
    ...eff,
    scheduler: {
      windowWidth: eff.scheduler.windowWidth * trick.windowMult,
      peakRadius: eff.scheduler.peakRadius * trick.windowMult,
      distractorRate: Math.min(1, eff.scheduler.distractorRate + trick.distractorBonus),
    },
    deltas: {
      ...eff.deltas,
      PERFECT: eff.deltas.PERFECT * trick.learnMult,
      OK: eff.deltas.OK * trick.learnMult,
    },
    learnMult: trick.learnMult,
  };
}

const CONFUSE_WINDOW_MULT = 0.6;     // window narrows ≈ −40%
const CONFUSE_DISTRACTOR_MULT = 1.5; // distractors increase ≈ +50%

/** Apply the false-mark confuse debuff to a difficulty: tighter window, more
 *  distractors. Pure/immutable; other fields preserved. */
export function confuseDifficulty(eff: EffectiveDifficulty): EffectiveDifficulty {
  return {
    ...eff,
    scheduler: {
      ...eff.scheduler,
      windowWidth: eff.scheduler.windowWidth * CONFUSE_WINDOW_MULT,
      peakRadius: eff.scheduler.peakRadius * CONFUSE_WINDOW_MULT,
      distractorRate: Math.min(1, eff.scheduler.distractorRate * CONFUSE_DISTRACTOR_MULT),
    },
  };
}
