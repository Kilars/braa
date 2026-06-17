import { describe, it, expect } from 'vitest';
import { STARTER_BREED, BREED_CATALOG, adoptableBreeds, canAdopt, composeDifficulty, isBreedLevelLocked } from './breeds';
import { effectiveDifficulty } from './difficulty';
import type { Dog } from './roster';

// ─── Cycle 1: STARTER_BREED is beginner-friendly ──────────────────────────────

describe('STARTER_BREED', () => {
  it('is the Labrador', () => {
    expect(STARTER_BREED.id).toBe('labrador');
    expect(STARTER_BREED.name).toBe('Labrador');
  });

  it('has intrinsic <= 1 (not harder than neutral)', () => {
    expect(STARTER_BREED.intrinsic).toBeLessThanOrEqual(1);
  });
});

// ─── Cycle 2: composeDifficulty with neutral breed = plain mode difficulty ─────

describe('composeDifficulty — neutral breed (intrinsic = 1)', () => {
  it('equals effectiveDifficulty(NORMAL) when breed intrinsic is 1', () => {
    const neutralBreed: import('./breeds').Breed = {
      id: 'neutral', name: 'Neutral', intrinsic: 1, learnSpeed: 1, distractibility: 0.5,
    };
    expect(composeDifficulty('NORMAL', neutralBreed)).toEqual(effectiveDifficulty('NORMAL'));
  });
});

// ─── Cycle 3: BREED_CATALOG contains starter + ≥2 more, all with adoptCosts ──

describe('BREED_CATALOG', () => {
  it('contains at least 3 breeds (starter + 2 more)', () => {
    expect(BREED_CATALOG.length).toBeGreaterThanOrEqual(3);
  });

  it('includes the STARTER_BREED', () => {
    expect(BREED_CATALOG.some(b => b.id === STARTER_BREED.id)).toBe(true);
  });

  it('every non-starter breed has a positive adoptCost', () => {
    const nonStarter = BREED_CATALOG.filter(b => b.id !== STARTER_BREED.id);
    for (const breed of nonStarter) {
      expect(breed.adoptCost).toBeGreaterThan(0);
    }
  });

  it('non-starter breeds have varied intrinsics (all > 1, making them harder)', () => {
    const nonStarter = BREED_CATALOG.filter(b => b.id !== STARTER_BREED.id);
    for (const breed of nonStarter) {
      expect(breed.intrinsic).toBeGreaterThan(1);
    }
  });
});

// ─── Cycle 4: composeDifficulty — harder breed is strictly harder ──────────────

// ─── Cycle 5: adoptableBreeds returns breeds not already in roster ────────────

const REX: Dog = { id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] };

describe('adoptableBreeds', () => {
  it('returns all breeds when roster is empty', () => {
    expect(adoptableBreeds([])).toHaveLength(BREED_CATALOG.length);
  });

  it('excludes breeds already in the roster by breedId', () => {
    const result = adoptableBreeds([REX]);
    expect(result.some(b => b.id === 'labrador')).toBe(false);
    expect(result.length).toBe(BREED_CATALOG.length - 1);
  });

  it('returns empty when all breeds are owned', () => {
    const fullRoster: Dog[] = BREED_CATALOG.map((b, i) => ({
      id: `dog-${i}`, name: b.name, breedId: b.id, masteredTrickIds: [],
    }));
    expect(adoptableBreeds(fullRoster)).toHaveLength(0);
  });
});

// ─── Cycle 6: canAdopt — owned / affordability rules ─────────────────────────

const BORDER_COLLIE_BREED = BREED_CATALOG.find(b => b.id === 'border-collie')!;

describe('canAdopt', () => {
  it('returns false if breed is already in the roster', () => {
    const owned: Dog = { id: 'border-collie-1', name: 'Scout', breedId: 'border-collie', masteredTrickIds: [] };
    expect(canAdopt(BORDER_COLLIE_BREED, 9999, 99, [owned])).toBe(false);
  });

  it('returns false if coins are insufficient', () => {
    expect(canAdopt(BORDER_COLLIE_BREED, 10, 99, [])).toBe(false);
  });

  it('returns true when affordable and not owned', () => {
    expect(canAdopt(BORDER_COLLIE_BREED, 200, 99, [])).toBe(true);
  });

  it('returns true with surplus coins and not owned', () => {
    expect(canAdopt(BORDER_COLLIE_BREED, 500, 99, [REX])).toBe(true);
  });
});

// ─── Cycle: puddel — 4th adoptable breed with snurr as signature trick ───────

describe('BREED_CATALOG — puddel', () => {
  const puddel = BREED_CATALOG.find(b => b.id === 'puddel');

  it('puddel exists in BREED_CATALOG', () => {
    expect(puddel).toBeDefined();
  });

  it('puddel has name "Puddel"', () => {
    expect(puddel?.name).toBe('Puddel');
  });

  it('puddel has a positive adoptCost', () => {
    expect(puddel?.adoptCost).toBeGreaterThan(0);
  });

  it('puddel has intrinsic > 1 (harder than starter)', () => {
    expect(puddel?.intrinsic).toBeGreaterThan(1);
  });

  it('puddel has signatureTrickId "snurr"', () => {
    expect(puddel?.signatureTrickId).toBe('snurr');
  });
});

// ─── Cycle: adoptableBreeds / canAdopt work for puddel ──────────────────────

describe('adoptableBreeds and canAdopt — puddel', () => {
  const puddel = BREED_CATALOG.find(b => b.id === 'puddel')!;

  it('puddel is listed in adoptableBreeds when roster is empty', () => {
    const adoptable = adoptableBreeds([]);
    expect(adoptable.some(b => b.id === 'puddel')).toBe(true);
  });

  it('puddel is not adoptable when already owned', () => {
    const ownedPuddel: import('./roster').Dog = { id: 'p1', name: 'Fifi', breedId: 'puddel', masteredTrickIds: [] };
    const adoptable = adoptableBreeds([ownedPuddel]);
    expect(adoptable.some(b => b.id === 'puddel')).toBe(false);
  });

  it('canAdopt returns false when coins are insufficient', () => {
    expect(canAdopt(puddel, 100, 99, [])).toBe(false);
  });

  it('canAdopt returns true when coins >= adoptCost and not owned', () => {
    expect(canAdopt(puddel, 225, 99, [])).toBe(true);
  });

  it('canAdopt returns false when puddel is already owned', () => {
    const ownedPuddel: import('./roster').Dog = { id: 'p1', name: 'Fifi', breedId: 'puddel', masteredTrickIds: [] };
    expect(canAdopt(puddel, 9999, 99, [ownedPuddel])).toBe(false);
  });
});

// ─── Cycle 3 (difficulty): harder breed (intrinsic > 1) is strictly harder ───

describe('composeDifficulty — harder breed (intrinsic > 1)', () => {
  const harderBreed: import('./breeds').Breed = {
    id: 'border-collie', name: 'Border Collie', intrinsic: 1.5, learnSpeed: 1.4, distractibility: 0.9,
  };
  const normalResult = composeDifficulty('NORMAL', { id: 'n', name: 'N', intrinsic: 1, learnSpeed: 1, distractibility: 0.5 });
  const harderResult = composeDifficulty('NORMAL', harderBreed);

  it('yields a strictly narrower windowWidth than neutral breed', () => {
    expect(harderResult.scheduler.windowWidth).toBeLessThan(normalResult.scheduler.windowWidth);
  });

  it('yields a strictly smaller peakRadius than neutral breed', () => {
    expect(harderResult.scheduler.peakRadius).toBeLessThan(normalResult.scheduler.peakRadius);
  });

  it('yields strictly more distractors than neutral breed', () => {
    expect(harderResult.scheduler.distractorRate).toBeGreaterThan(normalResult.scheduler.distractorRate);
  });
});

// ─── Level-gated breed adoption ──────────────────────────────────────────────

describe('canAdopt — level gate', () => {
  it('returns false when player level < breed.requiredLevel, even with ample coins', () => {
    const levelGatedBreed: import('./breeds').Breed = {
      id: 'test-breed', name: 'Test', intrinsic: 1.2, learnSpeed: 1, distractibility: 0.5,
      adoptCost: 100, requiredLevel: 3,
    };
    // Level 2 player tries to adopt a breed requiring level 3
    expect(canAdopt(levelGatedBreed, 9999, 2, [])).toBe(false);
  });

  it('returns true when player level >= breed.requiredLevel and coins sufficient', () => {
    const levelGatedBreed: import('./breeds').Breed = {
      id: 'test-breed', name: 'Test', intrinsic: 1.2, learnSpeed: 1, distractibility: 0.5,
      adoptCost: 100, requiredLevel: 3,
    };
    // Level 3 player with ample coins can adopt
    expect(canAdopt(levelGatedBreed, 9999, 3, [])).toBe(true);
  });

  it('returns false when coins are insufficient, even if level is sufficient', () => {
    const levelGatedBreed: import('./breeds').Breed = {
      id: 'test-breed', name: 'Test', intrinsic: 1.2, learnSpeed: 1, distractibility: 0.5,
      adoptCost: 500, requiredLevel: 2,
    };
    // Level 2 player but only 100 coins (cost is 500)
    expect(canAdopt(levelGatedBreed, 100, 2, [])).toBe(false);
  });

  it('returns false when breed is already owned, even at high level and coins', () => {
    const levelGatedBreed: import('./breeds').Breed = {
      id: 'test-breed', name: 'Test', intrinsic: 1.2, learnSpeed: 1, distractibility: 0.5,
      adoptCost: 100, requiredLevel: 1,
    };
    const ownedDog: Dog = { id: 'owned-1', name: 'Owned', breedId: 'test-breed', masteredTrickIds: [] };
    expect(canAdopt(levelGatedBreed, 9999, 99, [ownedDog])).toBe(false);
  });
});

describe('BREED_CATALOG — requiredLevel property', () => {
  it('every breed has a numeric requiredLevel >= 1', () => {
    for (const breed of BREED_CATALOG) {
      const requiredLevel = breed.requiredLevel ?? 1;
      expect(typeof requiredLevel).toBe('number');
      expect(requiredLevel).toBeGreaterThanOrEqual(1);
    }
  });

  it('STARTER_BREED is purchasable from level 1', () => {
    const requiredLevel = STARTER_BREED.requiredLevel ?? 1;
    expect(requiredLevel).toBeLessThanOrEqual(1);
  });
});

// ─── isBreedLevelLocked — the level question alone (adopt panel legibility) ──

describe('isBreedLevelLocked', () => {
  const lvl3Breed: import('./breeds').Breed = {
    id: 'test-breed', name: 'Test', intrinsic: 1.2, learnSpeed: 1, distractibility: 0.5,
    adoptCost: 100, requiredLevel: 3,
  };

  it('is level-locked below requiredLevel (level 1 and 2 for a level-3 breed)', () => {
    expect(isBreedLevelLocked(lvl3Breed, 1)).toBe(true);
    expect(isBreedLevelLocked(lvl3Breed, 2)).toBe(true);
  });

  it('is not level-locked at or above requiredLevel (level 3+ for a level-3 breed)', () => {
    expect(isBreedLevelLocked(lvl3Breed, 3)).toBe(false);
    expect(isBreedLevelLocked(lvl3Breed, 4)).toBe(false);
  });

  it('a breed with requiredLevel 1 is never level-locked', () => {
    const lvl1Breed: import('./breeds').Breed = {
      id: 'lab', name: 'Lab', intrinsic: 1, learnSpeed: 1, distractibility: 0.5, requiredLevel: 1,
    };
    expect(isBreedLevelLocked(lvl1Breed, 1)).toBe(false);
  });

  it('a breed with no requiredLevel defaults to never level-locked', () => {
    const noLevelBreed: import('./breeds').Breed = {
      id: 'x', name: 'X', intrinsic: 1, learnSpeed: 1, distractibility: 0.5,
    };
    expect(isBreedLevelLocked(noLevelBreed, 1)).toBe(false);
  });

  it('level dominates coins: a level-locked breed is never adoptable even with ample coins', () => {
    // Guard that levelGated is display-only and canAdopt still blocks the purchase.
    expect(isBreedLevelLocked(lvl3Breed, 2)).toBe(true);
    expect(canAdopt(lvl3Breed, 9999, 2, [])).toBe(false);
  });

  it('a breed unlocked by level but short on coins is NOT level-locked (it is the coin case)', () => {
    expect(isBreedLevelLocked(lvl3Breed, 3)).toBe(false);
    expect(canAdopt(lvl3Breed, 0, 3, [])).toBe(false); // still blocked, but by coins
  });
});
