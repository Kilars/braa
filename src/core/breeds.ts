import { DifficultyMode, EffectiveDifficulty, effectiveDifficulty } from './difficulty';
import type { Dog } from './roster';
import { isTierUnlocked } from './economy';

export interface Breed {
  id: string;
  name: string;
  intrinsic: number;          // difficulty multiplier; 1 = neutral, >1 = harder
  learnSpeed: number;         // personality stat
  distractibility: number;    // personality stat
  adoptCost?: number;         // coins to adopt; undefined = starter (free/given)
  signatureTrickId?: string;  // unique trick unlocked by owning this breed
  requiredLevel?: number;     // minimum trainer level to adopt; defaults to 1
}

export const STARTER_BREED: Breed = {
  id: 'labrador',
  name: 'Labrador',
  intrinsic: 1,
  learnSpeed: 1,
  distractibility: 0.5,
  requiredLevel: 1,
};

const BULLDOG: Breed = {
  id: 'bulldog',
  name: 'Bulldog',
  intrinsic: 1.3,
  learnSpeed: 0.7,
  distractibility: 0.3,
  adoptCost: 150,
  signatureTrickId: 'sov',
  requiredLevel: 2,
};

const BORDER_COLLIE: Breed = {
  id: 'border-collie',
  name: 'Border Collie',
  intrinsic: 1.5,
  learnSpeed: 1.4,
  distractibility: 0.9,
  adoptCost: 200,
  signatureTrickId: 'rull',
  requiredLevel: 3,
};

const PUDDEL: Breed = {
  id: 'puddel',
  name: 'Puddel',
  intrinsic: 1.4,
  learnSpeed: 1.3,
  distractibility: 0.7,
  adoptCost: 225,
  signatureTrickId: 'snurr',
  requiredLevel: 4,
};

const HUSKY: Breed = {
  id: 'husky',
  name: 'Husky',
  intrinsic: 1.8,
  learnSpeed: 1.1,
  distractibility: 0.95,
  adoptCost: 300,
  signatureTrickId: 'ul',
  requiredLevel: 5,
};

export const BREED_CATALOG: Breed[] = [STARTER_BREED, BORDER_COLLIE, BULLDOG, HUSKY, PUDDEL];

export function adoptableBreeds(roster: Dog[]): Breed[] {
  const ownedIds = new Set(roster.map(d => d.breedId));
  return BREED_CATALOG.filter(b => !ownedIds.has(b.id));
}

/**
 * True when `breed` is blocked purely by the player's level — regardless of coins.
 * Mirrors the phrase `nextLockedIsLevelGated` flag so the adopt panel can show
 * "reach level N" instead of a misleading coin-shortage message. Display-only:
 * `canAdopt` remains the authoritative purchase gate.
 */
export function isBreedLevelLocked(breed: Breed, level: number): boolean {
  return !isTierUnlocked(level, breed.requiredLevel ?? 1);
}

export function canAdopt(breed: Breed, coins: number, level: number, roster: Dog[]): boolean {
  const owned = roster.some(d => d.breedId === breed.id);
  if (owned) return false;
  if (!isTierUnlocked(level, breed.requiredLevel ?? 1)) return false; // level gate
  return coins >= (breed.adoptCost ?? 0);                              // coin gate
}

export function composeDifficulty(mode: DifficultyMode, breed: Breed): EffectiveDifficulty {
  const base = effectiveDifficulty(mode);
  if (breed.intrinsic === 1) return base;
  const s = breed.intrinsic;
  return {
    ...base,
    scheduler: {
      windowWidth: base.scheduler.windowWidth / s,
      peakRadius: base.scheduler.peakRadius / s,
      distractorRate: Math.min(1, base.scheduler.distractorRate * s),
    },
  };
}
