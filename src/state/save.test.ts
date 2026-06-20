import { describe, it, expect } from 'vitest';
import { serialize, deserialize } from './save';
import type { GameSave } from './save';
import { buildGameSave } from '../app/gameHelpers';
import { newProfile } from '../core/economy';

// ─── Cycle 1: serialize→deserialize round-trip ───────────────────────────────

describe('serialize/deserialize round-trip', () => {
  it('round-trips a GameSave exactly', () => {
    const save: GameSave = {
      profile: { coins: 150, xp: 300, level: 3 },
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: ['treats-pouch'],
      difficultyMode: 'HARD',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: ['sitt'] }],
      unlockedPhraseIds: ['flink'],
      prestigePoints: 0,
      muted: false,
      bestCombo: 0,
      streak: 0,
      lastPlayedYmd: '',
      activeRoundDogId: null,
      activeTrickId: null,
      learnedBar: 0,
    };
    const raw = serialize(save);
    const result = deserialize(raw);
    expect(result).toEqual(save);
  });
});

// ─── Cycle 2: malformed input does not throw — returns null ──────────────────

describe('deserialize — malformed input', () => {
  it('returns null for invalid JSON without throwing', () => {
    const result = deserialize('not valid json {{{');
    expect(result).toBeNull();
  });

  it('returns null for empty string', () => {
    const result = deserialize('');
    expect(result).toBeNull();
  });
});

// ─── Cycle 9: backward-compat — old saves without kennelUpgradeIds ───────────

describe('deserialize — backward-compat for old saves', () => {
  it('defaults kennelUpgradeIds to [] when field is absent', () => {
    const oldSave = JSON.stringify({
      profile: { coins: 50, xp: 30, level: 1 },
      masteredTrickIds: [],
      idleTimestamp: 1718000000000,
      // no kennelUpgradeIds field
    });
    const result = deserialize(oldSave);
    expect(result).not.toBeNull();
    expect(result!.kennelUpgradeIds).toEqual([]);
  });
});

// ─── Cycle 18: backward-compat — old saves without difficultyMode ────────────

describe('deserialize — backward-compat for difficultyMode', () => {
  it('defaults difficultyMode to NORMAL when field is absent', () => {
    const oldSave = JSON.stringify({
      profile: { coins: 50, xp: 30, level: 1 },
      masteredTrickIds: [],
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      // no difficultyMode field
    });
    const result = deserialize(oldSave);
    expect(result).not.toBeNull();
    expect(result!.difficultyMode).toBe('NORMAL');
  });

  it('preserves difficultyMode when present', () => {
    const save: GameSave = {
      profile: { coins: 0, xp: 0, level: 1 },
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'EXPERT',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      muted: false,
      bestCombo: 0,
      streak: 0,
      lastPlayedYmd: '',
      activeRoundDogId: null,
      activeTrickId: null,
      learnedBar: 0,
    };
    const result = deserialize(serialize(save));
    expect(result).not.toBeNull();
    expect(result!.difficultyMode).toBe('EXPERT');
  });
});

// ─── Cycle 25: backward-compat — old saves without unlockedPhraseIds ─────────

describe('deserialize — backward-compat for unlockedPhraseIds', () => {
  it('defaults unlockedPhraseIds to [] when field is absent', () => {
    const oldSave = JSON.stringify({
      profile: { coins: 50, xp: 30, level: 1 },
      masteredTrickIds: [],
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      // no unlockedPhraseIds field
    });
    const result = deserialize(oldSave);
    expect(result).not.toBeNull();
    expect(result!.unlockedPhraseIds).toEqual([]);
  });

  it('preserves unlockedPhraseIds when present', () => {
    const save: GameSave = {
      profile: { coins: 0, xp: 0, level: 1 },
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: ['flink'],
      prestigePoints: 0,
      muted: false,
      bestCombo: 0,
      streak: 0,
      lastPlayedYmd: '',
      activeRoundDogId: null,
      activeTrickId: null,
      learnedBar: 0,
    };
    const result = deserialize(serialize(save));
    expect(result).not.toBeNull();
    expect(result!.unlockedPhraseIds).toEqual(['flink']);
  });
});

// ─── Cycle 21: backward-compat — old saves without roster ────────────────────

describe('deserialize — backward-compat for roster', () => {
  it('defaults roster to starter dog (Rex/labrador) when field is absent', () => {
    const oldSave = JSON.stringify({
      profile: { coins: 50, xp: 30, level: 1 },
      masteredTrickIds: [],
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      // no roster field
    });
    const result = deserialize(oldSave);
    expect(result).not.toBeNull();
    expect(result!.roster).toHaveLength(1);
    expect(result!.roster[0]).toMatchObject({
      id: 'rex',
      name: 'Rex',
      breedId: 'labrador',
      masteredTrickIds: [],
    });
  });

  it('preserves roster when present', () => {
    const save: GameSave = {
      profile: { coins: 0, xp: 0, level: 1 },
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: ['sitt', 'ligg'] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      muted: false,
      bestCombo: 0,
      streak: 0,
      lastPlayedYmd: '',
      activeRoundDogId: null,
      activeTrickId: null,
      learnedBar: 0,
    };
    const result = deserialize(serialize(save));
    expect(result).not.toBeNull();
    expect(result!.roster[0].masteredTrickIds).toEqual(['sitt', 'ligg']);
  });
});

// ─── Cycle 38: backward-compat — old saves without muted ─────────────────────

describe('deserialize — backward-compat for muted', () => {
  it('preserves muted: true through round-trip', () => {
    const save: GameSave = {
      profile: { coins: 0, xp: 0, level: 1 },
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      muted: true,
      bestCombo: 0,
      streak: 0,
      lastPlayedYmd: '',
      activeRoundDogId: null,
      activeTrickId: null,
      learnedBar: 0,
    };
    const result = deserialize(serialize(save));
    expect(result).not.toBeNull();
    expect(result!.muted).toBe(true);
  });

  it('defaults muted to false when field is absent', () => {
    const oldSave = JSON.stringify({
      profile: { coins: 50, xp: 30, level: 1 },
      masteredTrickIds: [],
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      // no muted field
    });
    const result = deserialize(oldSave);
    expect(result).not.toBeNull();
    expect(result!.muted).toBe(false);
  });
});

// ─── Cycle 49: bestCombo persists (round-trip + backward-compat) ─────────────

describe('deserialize — bestCombo round-trip', () => {
  it('preserves bestCombo when present', () => {
    const save: GameSave = {
      profile: { coins: 0, xp: 0, level: 1 },
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      muted: false,
      bestCombo: 12,
      streak: 0,
      lastPlayedYmd: '',
      activeRoundDogId: null,
      activeTrickId: null,
      learnedBar: 0,
    };
    const result = deserialize(serialize(save));
    expect(result).not.toBeNull();
    expect(result!.bestCombo).toBe(12);
  });
});

describe('deserialize — backward-compat for bestCombo', () => {
  it('defaults bestCombo to 0 when field is absent', () => {
    const oldSave = JSON.stringify({
      profile: { coins: 50, xp: 30, level: 1 },
      masteredTrickIds: [],
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      muted: false,
      // no bestCombo field
    });
    const result = deserialize(oldSave);
    expect(result).not.toBeNull();
    expect(result!.bestCombo).toBe(0);
  });
});

// ─── Cycle 30: backward-compat — old saves without prestigePoints ─────────────

describe('deserialize — backward-compat for prestigePoints', () => {
  it('defaults prestigePoints to 0 when field is absent', () => {
    const oldSave = JSON.stringify({
      profile: { coins: 50, xp: 30, level: 1 },
      masteredTrickIds: [],
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      // no prestigePoints field
    });
    const result = deserialize(oldSave);
    expect(result).not.toBeNull();
    expect(result!.prestigePoints).toBe(0);
  });

  it('preserves prestigePoints when present', () => {
    const save: GameSave = {
      profile: { coins: 0, xp: 0, level: 1 },
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      prestigePoints: 3,
      muted: false,
      bestCombo: 0,
      streak: 0,
      lastPlayedYmd: '',
      activeRoundDogId: null,
      activeTrickId: null,
      learnedBar: 0,
    };
    const result = deserialize(serialize(save));
    expect(result).not.toBeNull();
    expect(result!.prestigePoints).toBe(3);
  });
});

// ─── Cycle 52: backward-compat — old saves without streak / lastPlayedYmd ────

describe('deserialize — backward-compat for streak + lastPlayedYmd', () => {
  it('defaults streak to 0 and lastPlayedYmd to "" when fields are absent', () => {
    const oldSave = JSON.stringify({
      profile: { coins: 50, xp: 30, level: 1 },
      masteredTrickIds: [],
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      muted: false,
      bestCombo: 0,
      // no streak or lastPlayedYmd
    });
    const result = deserialize(oldSave);
    expect(result).not.toBeNull();
    expect(result!.streak).toBe(0);
    expect(result!.lastPlayedYmd).toBe('');
  });

  it('preserves streak and lastPlayedYmd through round-trip', () => {
    const save: GameSave = {
      profile: { coins: 0, xp: 0, level: 1 },
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      muted: false,
      bestCombo: 0,
      streak: 5,
      lastPlayedYmd: '2026-06-14',
      activeRoundDogId: null,
      activeTrickId: null,
      learnedBar: 0,
    };
    const result = deserialize(serialize(save));
    expect(result).not.toBeNull();
    expect(result!.streak).toBe(5);
    expect(result!.lastPlayedYmd).toBe('2026-06-14');
  });
});

// ─── Cleanup Task 076: top-level masteredTrickIds removal ─────────────────────

describe('deserialize — back-compat for legacy top-level masteredTrickIds', () => {
  it('loads a legacy save with top-level masteredTrickIds and preserves roster mastery', () => {
    const legacySave = JSON.stringify({
      profile: { coins: 100, xp: 50, level: 2 },
      masteredTrickIds: ['sitt', 'ligg'],
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: ['sitt', 'ligg'] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      muted: false,
      bestCombo: 0,
      streak: 0,
      lastPlayedYmd: '',
    });
    const result = deserialize(legacySave);
    expect(result).not.toBeNull();
    expect(result!.profile.coins).toBe(100);
    expect(result!.profile.level).toBe(2);
    expect(result!.idleTimestamp).toBe(1718000000000);
    expect(result!.roster).toHaveLength(1);
    expect(result!.roster[0].masteredTrickIds).toEqual(['sitt', 'ligg']);
  });
});

describe('deserialize — post-cleanup: buildGameSave round-trip without top-level masteredTrickIds', () => {
  it('after cleanup, a buildGameSave round-trip should omit the top-level masteredTrickIds field', () => {
    // After cleanup, buildGameSave will not write masteredTrickIds at the top level.
    // This test verifies that when we serialize such a save and deserialize it,
    // the result also does not have a top-level masteredTrickIds property.
    //
    // Today (before cleanup), buildGameSave writes masteredTrickIds: [],
    // so this test is RED: the deserialized result will have the field.
    // After cleanup, buildGameSave stops writing it, so this test becomes GREEN.
    const builtSave = buildGameSave({
      profile: newProfile(),
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: ['sitt'] }],
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      unlockedPhraseIds: [],
      prestigePoints: 0,
      idleTimestamp: 1000000,
    });
    const serialized = serialize(builtSave);
    const deserialized = deserialize(serialized);
    expect(deserialized).not.toBeNull();
    // After cleanup, buildGameSave will not write masteredTrickIds,
    // so the deserialized result should not have it as an own property.
    expect(Object.prototype.hasOwnProperty.call(deserialized, 'masteredTrickIds')).toBe(false);
  });
});

// ─── Cycle 86: backward-compat — old saves without active round fields ────────

describe('deserialize — backward-compat for activeRoundDogId, activeTrickId, learnedBar', () => {
  it('defaults activeRoundDogId to null, activeTrickId to null, learnedBar to 0 for old saves without these fields', () => {
    const oldSave = JSON.stringify({
      profile: { coins: 50, xp: 30, level: 1 },
      masteredTrickIds: [],
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      muted: false,
      bestCombo: 0,
      streak: 0,
      lastPlayedYmd: '',
      // no activeRoundDogId, activeTrickId, or learnedBar
    });
    const result = deserialize(oldSave);
    expect(result).not.toBeNull();
    expect(result!.activeRoundDogId).toBe(null);
    expect(result!.activeTrickId).toBe(null);
    expect(result!.learnedBar).toBe(0);
  });

  it('round-trips activeRoundDogId, activeTrickId, learnedBar when present', () => {
    const save: GameSave = {
      profile: { coins: 0, xp: 0, level: 1 },
      idleTimestamp: 1718000000000,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: [] }],
      unlockedPhraseIds: [],
      prestigePoints: 0,
      muted: false,
      bestCombo: 0,
      streak: 0,
      lastPlayedYmd: '',
      activeRoundDogId: 'rex',
      activeTrickId: 'sitt',
      learnedBar: 55,
    };
    const result = deserialize(serialize(save));
    expect(result).not.toBeNull();
    expect(result!.activeRoundDogId).toBe('rex');
    expect(result!.activeTrickId).toBe('sitt');
    expect(result!.learnedBar).toBe(55);
  });
});
