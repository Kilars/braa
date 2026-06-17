import type { Dog } from './roster';

/** Points awarded per graduation event. */
export const PRESTIGE_PER_GRADUATION = 1;

/**
 * Returns true when the dog has mastered every trick in allTrickIds.
 */
export function canGraduate(dog: Dog, allTrickIds: string[]): boolean {
  return allTrickIds.every(id => dog.masteredTrickIds.includes(id));
}

/**
 * Returns a new Dog with masteredTrickIds cleared (re-trainable).
 * All other fields are preserved; the original dog is not mutated.
 */
export function graduate(dog: Dog): Dog {
  return { ...dog, masteredTrickIds: [] };
}

/**
 * Prestige multiplier applied to all payouts.
 * Returns 1 when prestigePoints = 0; grows linearly per point, capped at 2.5×.
 */
export function prestigeMultiplier(prestigePoints: number): number {
  return Math.min(2.5, 1 + prestigePoints * 0.1);
}
