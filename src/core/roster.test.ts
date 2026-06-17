import { describe, it, expect } from 'vitest';
import { addDog, recordMastery, repertoire } from './roster';
import type { Dog } from './roster';

// ─── Cycle 4: addDog immutable append ─────────────────────────────────────────

const DOG_LUNA: Dog = { id: 'dog-1', name: 'Luna', breedId: 'labrador', masteredTrickIds: [] };
const DOG_MAX: Dog  = { id: 'dog-2', name: 'Max',  breedId: 'labrador', masteredTrickIds: [] };

describe('addDog', () => {
  it('appends a dog to an empty roster', () => {
    const result = addDog([], DOG_LUNA);
    expect(result).toHaveLength(1);
    expect(result[0]).toEqual(DOG_LUNA);
  });

  it('does not mutate the original roster', () => {
    const roster: Dog[] = [];
    addDog(roster, DOG_LUNA);
    expect(roster).toHaveLength(0);
  });

  it('appends to an existing roster without changing prior entries', () => {
    const roster = [DOG_LUNA];
    const result = addDog(roster, DOG_MAX);
    expect(result).toHaveLength(2);
    expect(result[0]).toEqual(DOG_LUNA);
    expect(result[1]).toEqual(DOG_MAX);
  });
});

// ─── Cycle 5: recordMastery idempotent + targets the right dog ────────────────

describe('recordMastery', () => {
  it('adds a trick to the target dog', () => {
    const roster = [DOG_LUNA, DOG_MAX];
    const result = recordMastery(roster, 'dog-1', 'sitt');
    expect(result.find(d => d.id === 'dog-1')?.masteredTrickIds).toContain('sitt');
  });

  it('does not add the trick to other dogs', () => {
    const roster = [DOG_LUNA, DOG_MAX];
    const result = recordMastery(roster, 'dog-1', 'sitt');
    expect(result.find(d => d.id === 'dog-2')?.masteredTrickIds).not.toContain('sitt');
  });

  it('is idempotent — adding the same trick twice does not duplicate it', () => {
    const roster = [DOG_LUNA];
    const once = recordMastery(roster, 'dog-1', 'sitt');
    const twice = recordMastery(once, 'dog-1', 'sitt');
    expect(twice.find(d => d.id === 'dog-1')?.masteredTrickIds).toHaveLength(1);
  });

  it('does not mutate the original roster', () => {
    const roster = [DOG_LUNA];
    recordMastery(roster, 'dog-1', 'sitt');
    expect(DOG_LUNA.masteredTrickIds).toHaveLength(0);
  });
});

// ─── Cycle 6: repertoire returns correct trick ids ────────────────────────────

describe('repertoire', () => {
  it('returns empty array for a dog with no mastered tricks', () => {
    expect(repertoire([DOG_LUNA], 'dog-1')).toEqual([]);
  });

  it('returns all mastered trick ids for the given dog', () => {
    const roster = recordMastery(recordMastery([DOG_LUNA], 'dog-1', 'sitt'), 'dog-1', 'ligg');
    expect(repertoire(roster, 'dog-1')).toEqual(['sitt', 'ligg']);
  });

  it('returns empty array when dog id is not found', () => {
    expect(repertoire([DOG_LUNA], 'unknown-id')).toEqual([]);
  });
});
