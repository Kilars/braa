import { describe, it, expect } from 'vitest';
import { canGraduate, graduate, PRESTIGE_PER_GRADUATION, prestigeMultiplier } from './prestige';
import type { Dog } from './roster';

// ── Helpers ────────────────────────────────────────────────────────────────────
const ALL_TRICK_IDS = ['sitt', 'ligg', 'legg-deg'];

function makeDog(overrides: Partial<Dog> = {}): Dog {
  return {
    id: 'rex',
    name: 'Rex',
    breedId: 'labrador',
    masteredTrickIds: [],
    ...overrides,
  };
}

// ─── Cycle 1: canGraduate — false when no tricks mastered ────────────────────

describe('canGraduate — not yet eligible', () => {
  it('returns false when the dog has mastered no tricks', () => {
    const dog = makeDog({ masteredTrickIds: [] });
    expect(canGraduate(dog, ALL_TRICK_IDS)).toBe(false);
  });
});

// ─── Cycle 2: canGraduate — true when all tricks mastered ────────────────────

describe('canGraduate — eligible when fully trained', () => {
  it('returns true when the dog has mastered every trick in allTrickIds', () => {
    const dog = makeDog({ masteredTrickIds: ['sitt', 'ligg', 'legg-deg'] });
    expect(canGraduate(dog, ALL_TRICK_IDS)).toBe(true);
  });

  it('returns false when one trick is missing', () => {
    const dog = makeDog({ masteredTrickIds: ['sitt', 'ligg'] });
    expect(canGraduate(dog, ALL_TRICK_IDS)).toBe(false);
  });

  it('handles an empty allTrickIds list (vacuously true)', () => {
    const dog = makeDog({ masteredTrickIds: [] });
    expect(canGraduate(dog, [])).toBe(true);
  });
});

// ─── Cycle 3: graduate — returns dog with cleared masteredTrickIds ────────────

describe('graduate', () => {
  it('returns a dog with empty masteredTrickIds', () => {
    const dog = makeDog({ masteredTrickIds: ['sitt', 'ligg', 'legg-deg'] });
    const result = graduate(dog);
    expect(result.masteredTrickIds).toEqual([]);
  });

  it('preserves all other fields', () => {
    const dog = makeDog({ id: 'fluffy', name: 'Fluffy', breedId: 'golden', masteredTrickIds: ['sitt'] });
    const result = graduate(dog);
    expect(result.id).toBe('fluffy');
    expect(result.name).toBe('Fluffy');
    expect(result.breedId).toBe('golden');
  });

  it('is immutable — does not modify the original dog', () => {
    const dog = makeDog({ masteredTrickIds: ['sitt', 'ligg'] });
    graduate(dog);
    expect(dog.masteredTrickIds).toEqual(['sitt', 'ligg']);
  });
});

// ─── Cycle 4: prestigeMultiplier — 1 at 0; grows per point ──────────────────

describe('prestigeMultiplier', () => {
  it('returns 1 at 0 prestige points', () => {
    expect(prestigeMultiplier(0)).toBe(1);
  });

  it('returns more than 1 at 1 prestige point', () => {
    expect(prestigeMultiplier(1)).toBeGreaterThan(1);
  });

  it('grows monotonically with more prestige points', () => {
    expect(prestigeMultiplier(2)).toBeGreaterThan(prestigeMultiplier(1));
    expect(prestigeMultiplier(5)).toBeGreaterThan(prestigeMultiplier(3));
  });
});

// ─── Cycle 4b: prestigeMultiplier — capped at 2.5× (tuning §7 — applied) ────

describe('prestigeMultiplier — cap at 2.5×', () => {
  it('returns 2.5 at 50 prestige points (clamp applied)', () => {
    expect(prestigeMultiplier(50)).toBe(2.5);
  });

  it('returns 2.5 at very high prestige points (clamp holds)', () => {
    expect(prestigeMultiplier(100)).toBe(2.5);
  });

  it('low values below the cap are unchanged', () => {
    expect(prestigeMultiplier(0)).toBe(1);
    expect(prestigeMultiplier(5)).toBeCloseTo(1.5);
    expect(prestigeMultiplier(10)).toBeCloseTo(2.0);
  });
});

// ─── Cycle 5: PRESTIGE_PER_GRADUATION is a positive integer ─────────────────

describe('PRESTIGE_PER_GRADUATION', () => {
  it('is a positive integer', () => {
    expect(PRESTIGE_PER_GRADUATION).toBeGreaterThan(0);
    expect(Number.isInteger(PRESTIGE_PER_GRADUATION)).toBe(true);
  });
});
