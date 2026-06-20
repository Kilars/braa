import { DifficultyMode, effectiveDifficulty } from './difficulty';
import { Profile, Payout, award } from './economy';
import { prestigeMultiplier } from './prestige';
import { Trick, trickRewardMultiplier } from './tricks';

export const MASTERY_BASE_PAYOUT: Payout = { coins: 50, xp: 30 };
export const PRACTICE_BASE_PAYOUT: Payout = { coins: 15, xp: 0 }; // income floor, no XP

export function completePractice(
  p: Profile,
  mode: DifficultyMode,
  kennelMult: number = 1,
  prestigePoints: number = 0,
  trick?: Trick,
): Profile {
  const { rewardMultiplier } = effectiveDifficulty(mode);
  const tMult = trick ? trickRewardMultiplier(trick) : 1;
  return award(p, PRACTICE_BASE_PAYOUT, tMult * rewardMultiplier * kennelMult * prestigeMultiplier(prestigePoints));
}

export function completeMastery(
  p: Profile,
  mode: DifficultyMode,
  kennelMult: number = 1,
  prestigePoints: number = 0,
  trick?: Trick,
): Profile {
  const { rewardMultiplier } = effectiveDifficulty(mode);
  const tMult = trick ? trickRewardMultiplier(trick) : 1;
  return award(p, MASTERY_BASE_PAYOUT, tMult * rewardMultiplier * kennelMult * prestigeMultiplier(prestigePoints));
}
