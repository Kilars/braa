import { describe, it, expect, vi } from 'vitest';
import 'fake-indexeddb/auto';
import { InMemoryStorage, IndexedDbStorage } from './storage';
import type { GameSave } from './save';

/** A minimal valid GameSave for storage round-trip tests. */
function sampleSave(): GameSave {
  return {
    profile: { coins: 42, xp: 10, level: 1 },
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
    activeRoundDogId: null,
    activeTrickId: null,
    learnedBar: 0,
  };
}

// ─── Cycle 3: InMemoryStorage.load returns null before any save ───────────────

describe('InMemoryStorage — load before save', () => {
  it('returns null when nothing has been saved', async () => {
    const storage = new InMemoryStorage();
    const result = await storage.load();
    expect(result).toBeNull();
  });
});

// ─── Cycle 4: InMemoryStorage save then load returns the saved GameSave ───────

describe('InMemoryStorage — save then load', () => {
  it('returns the saved GameSave after saving', async () => {
    const storage = new InMemoryStorage();
    const save: GameSave = {
      profile: { coins: 200, xp: 100, level: 2 },
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
      activeRoundDogId: null,
      activeTrickId: null,
      learnedBar: 0,
    };
    await storage.save(save);
    const result = await storage.load();
    expect(result).toEqual(save);
  });
});

// ─── Cycle 5: idleTimestamp is preserved across save/load ────────────────────

describe('InMemoryStorage — idleTimestamp preserved', () => {
  it('preserves the exact idleTimestamp across save and load', async () => {
    const storage = new InMemoryStorage();
    const specificTimestamp = 1718123456789;
    const save: GameSave = {
      profile: { coins: 0, xp: 0, level: 1 },
      idleTimestamp: specificTimestamp,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
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
    await storage.save(save);
    const loaded = await storage.load();
    expect(loaded?.idleTimestamp).toBe(specificTimestamp);
  });
});

// ─── Cycle 38: InMemoryStorage.clear() ───────────────────────────────────────

describe('InMemoryStorage — clear()', () => {
  it('load() returns null after save() then clear()', async () => {
    const storage = new InMemoryStorage();
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
      activeRoundDogId: null,
      activeTrickId: null,
      learnedBar: 0,
    };
    await storage.save(save);
    await storage.clear();
    const result = await storage.load();
    expect(result).toBeNull();
  });
});

// ─── Cycle 6: IndexedDbStorage save/load round-trip (via fake-indexeddb) ─────

describe('IndexedDbStorage — save/load round-trip', () => {
  it('returns null before any save', async () => {
    const storage = new IndexedDbStorage('bra-test-empty');
    const result = await storage.load();
    expect(result).toBeNull();
  });

  it('round-trips a GameSave exactly', async () => {
    const storage = new IndexedDbStorage('bra-test-roundtrip');
    const save: GameSave = {
      profile: { coins: 500, xp: 300, level: 3 },
      idleTimestamp: 1718999888777,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
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
    await storage.save(save);
    const loaded = await storage.load();
    expect(loaded).toEqual(save);
  });

  it('preserves idleTimestamp', async () => {
    const storage = new IndexedDbStorage('bra-test-idle');
    const ts = 1718555444333;
    const save: GameSave = {
      profile: { coins: 0, xp: 0, level: 1 },
      idleTimestamp: ts,
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL',
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
    await storage.save(save);
    const loaded = await storage.load();
    expect(loaded?.idleTimestamp).toBe(ts);
  });
});

// ─── IndexedDbStorage connection reuse (task 090) ────────────────────────────

describe('IndexedDbStorage — connection reuse', () => {
  it('opens the database only once across many operations', async () => {
    const storage = new IndexedDbStorage('bra-test-reuse');
    const openSpy = vi.spyOn(indexedDB, 'open');
    try {
      await storage.save(sampleSave());
      await storage.save(sampleSave());
      await storage.load();
      await storage.clear();
      expect(openSpy).toHaveBeenCalledTimes(1);
    } finally {
      openSpy.mockRestore();
    }
  });

  it('still round-trips correctly after reuse and clear', async () => {
    const storage = new IndexedDbStorage('bra-test-reuse-roundtrip');
    const save = sampleSave();
    await storage.save(save);
    await storage.clear();
    expect(await storage.load()).toBeNull();
    await storage.save(save);
    expect(await storage.load()).toEqual(save);
  });
});
