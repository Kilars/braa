import { describe, it, expect } from 'vitest';
import { BASE_PHRASE, isReady, applyPhraseToAttempt, PHRASE_CATALOG, isPhraseUnlocked, availablePhrases, isPhrasePurchasable, nextPurchasableEntry } from './phrases';
import type { Attempt } from './mark';
import type { Profile } from './economy';

describe('BASE_PHRASE', () => {
  it('is always ready even right after use', () => {
    const now = 1000;
    const justUsed = 999;
    expect(isReady(BASE_PHRASE, now, justUsed)).toBe(true);
  });
});

describe('isReady - cooldown phrase', () => {
  const coolPhrase = { id: 'flink', word: 'flink', windowBonusMs: 200, rewardBonus: 0.1, cooldownMs: 5000 };

  it('is NOT ready when within cooldownMs of lastUsedAt', () => {
    const lastUsedAt = 1000;
    const now = 1000 + 4999; // 1 ms before cooldown expires
    expect(isReady(coolPhrase, now, lastUsedAt)).toBe(false);
  });

  it('IS ready exactly at cooldownMs boundary', () => {
    const lastUsedAt = 1000;
    const now = 1000 + 5000; // exactly at cooldown boundary
    expect(isReady(coolPhrase, now, lastUsedAt)).toBe(true);
  });

  it('IS ready after cooldownMs has elapsed', () => {
    const lastUsedAt = 1000;
    const now = 1000 + 5001; // 1 ms past cooldown
    expect(isReady(coolPhrase, now, lastUsedAt)).toBe(true);
  });

  it('IS ready when lastUsedAt is null (never used)', () => {
    expect(isReady(coolPhrase, 0, null)).toBe(true);
  });
});

// ─── Phrase catalog + unlock/availability ────────────────────────────────────

const baseProfile: Profile = { coins: 0, xp: 0, level: 1 };

describe('isPhraseUnlocked — BASE_PHRASE', () => {
  it('BASE_PHRASE is always unlocked regardless of coins or ownedIds', () => {
    expect(isPhraseUnlocked(BASE_PHRASE, baseProfile, [])).toBe(true);
  });
});

describe('isPhraseUnlocked — costed phrase', () => {
  const flinkPhrase = PHRASE_CATALOG[1].phrase; // flink

  it('is NOT unlocked when not in ownedIds, even with enough coins', () => {
    const richProfile: Profile = { coins: 9999, xp: 9999, level: 5 };
    expect(isPhraseUnlocked(flinkPhrase, richProfile, [])).toBe(false);
  });

  it('IS unlocked when id is present in ownedIds', () => {
    expect(isPhraseUnlocked(flinkPhrase, baseProfile, ['flink'])).toBe(true);
  });
});

describe('availablePhrases', () => {
  it('returns only BASE_PHRASE when ownedIds is empty', () => {
    const result = availablePhrases(baseProfile, []);
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe('bra');
  });

  it('returns base + owned phrases when ownedIds has entries', () => {
    const result = availablePhrases(baseProfile, ['flink']);
    expect(result).toHaveLength(2);
    const ids = result.map(p => p.id);
    expect(ids).toContain('bra');
    expect(ids).toContain('flink');
  });

  it('does not include unowned costed phrases', () => {
    const result = availablePhrases(baseProfile, ['flink']);
    const ids = result.map(p => p.id);
    expect(ids).not.toContain('super');
  });
});

// ─── PHRASE_CATALOG unlock costs (tuning §7 — applied) ──────────────────────

describe('PHRASE_CATALOG — specific unlock costs', () => {
  it('SUPER phrase unlockCost is 275', () => {
    const superEntry = PHRASE_CATALOG.find(e => e.phrase.id === 'super');
    expect(superEntry?.unlockCost).toBe(275);
  });
});

// ─── New phrases: dyktig + kjempebra ─────────────────────────────────────────

describe('PHRASE_CATALOG — dyktig phrase exists', () => {
  it('dyktig entry exists in PHRASE_CATALOG with positive unlockCost and valid bonus/cooldown', () => {
    const entry = PHRASE_CATALOG.find(e => e.phrase.id === 'dyktig');
    expect(entry).toBeDefined();
    expect(entry!.unlockCost).toBeGreaterThan(0);
    expect(entry!.phrase.windowBonusMs).toBeGreaterThan(0);
    expect(entry!.phrase.rewardBonus).toBeGreaterThan(0);
    expect(entry!.phrase.cooldownMs).toBeGreaterThan(0);
  });
});

describe('PHRASE_CATALOG — kjempebra phrase exists', () => {
  it('kjempebra entry exists in PHRASE_CATALOG with positive unlockCost and valid bonus/cooldown', () => {
    const entry = PHRASE_CATALOG.find(e => e.phrase.id === 'kjempebra');
    expect(entry).toBeDefined();
    expect(entry!.unlockCost).toBeGreaterThan(0);
    expect(entry!.phrase.windowBonusMs).toBeGreaterThan(0);
    expect(entry!.phrase.rewardBonus).toBeGreaterThan(0);
    expect(entry!.phrase.cooldownMs).toBeGreaterThan(0);
  });
});

describe('PHRASE_CATALOG — trade-off ordering: windowBonusMs is monotonically increasing', () => {
  it('flink < dyktig < super < kjempebra for windowBonusMs', () => {
    const get = (id: string) => PHRASE_CATALOG.find(e => e.phrase.id === id)!.phrase.windowBonusMs;
    expect(get('flink')).toBeLessThan(get('dyktig'));
    expect(get('dyktig')).toBeLessThan(get('super'));
    expect(get('super')).toBeLessThan(get('kjempebra'));
  });
});

describe('PHRASE_CATALOG — trade-off ordering: rewardBonus is monotonically increasing', () => {
  it('flink < dyktig < super < kjempebra for rewardBonus', () => {
    const get = (id: string) => PHRASE_CATALOG.find(e => e.phrase.id === id)!.phrase.rewardBonus;
    expect(get('flink')).toBeLessThan(get('dyktig'));
    expect(get('dyktig')).toBeLessThan(get('super'));
    expect(get('super')).toBeLessThan(get('kjempebra'));
  });
});

describe('PHRASE_CATALOG — trade-off ordering: cooldownMs is monotonically increasing', () => {
  it('flink < dyktig < super < kjempebra for cooldownMs', () => {
    const get = (id: string) => PHRASE_CATALOG.find(e => e.phrase.id === id)!.phrase.cooldownMs;
    expect(get('flink')).toBeLessThan(get('dyktig'));
    expect(get('dyktig')).toBeLessThan(get('super'));
    expect(get('super')).toBeLessThan(get('kjempebra'));
  });
});

describe('PHRASE_CATALOG — trade-off ordering: unlockCost is monotonically increasing', () => {
  it('flink < dyktig < super < kjempebra for unlockCost', () => {
    const get = (id: string) => PHRASE_CATALOG.find(e => e.phrase.id === id)!.unlockCost;
    expect(get('flink')).toBeLessThan(get('dyktig'));
    expect(get('dyktig')).toBeLessThan(get('super'));
    expect(get('super')).toBeLessThan(get('kjempebra'));
  });
});

describe('PHRASE_CATALOG — trade-off ordering: unlockLevel gates', () => {
  it('dyktig requires level 2, super level 3, kjempebra level 4', () => {
    const get = (id: string) => PHRASE_CATALOG.find(e => e.phrase.id === id)!.unlockLevel;
    expect(get('dyktig')).toBe(2);
    expect(get('super')).toBe(3);
    expect(get('kjempebra')).toBe(4);
  });
});

describe('PHRASE_CATALOG — §7 cost filter: costs are high enough that level is a real filter', () => {
  it('dyktig unlockCost >= 100 (cannot clear before reaching level 2)', () => {
    const entry = PHRASE_CATALOG.find(e => e.phrase.id === 'dyktig')!;
    expect(entry.unlockCost).toBeGreaterThanOrEqual(100);
  });

  it('kjempebra unlockCost >= 300 (cannot clear before reaching level 4)', () => {
    const entry = PHRASE_CATALOG.find(e => e.phrase.id === 'kjempebra')!;
    expect(entry.unlockCost).toBeGreaterThanOrEqual(300);
  });
});

// ─── isPhraseUnlocked / availablePhrases / isReady / applyPhraseToAttempt for new phrases ──

describe('isPhraseUnlocked — dyktig', () => {
  const dyktigPhrase = PHRASE_CATALOG.find(e => e.phrase.id === 'dyktig')!.phrase;

  it('is NOT unlocked when not in ownedIds', () => {
    expect(isPhraseUnlocked(dyktigPhrase, baseProfile, [])).toBe(false);
  });

  it('IS unlocked when id is present in ownedIds', () => {
    expect(isPhraseUnlocked(dyktigPhrase, baseProfile, ['dyktig'])).toBe(true);
  });
});

describe('isPhraseUnlocked — kjempebra', () => {
  const kjempebra = PHRASE_CATALOG.find(e => e.phrase.id === 'kjempebra')!.phrase;

  it('is NOT unlocked when not in ownedIds', () => {
    expect(isPhraseUnlocked(kjempebra, baseProfile, [])).toBe(false);
  });

  it('IS unlocked when id is present in ownedIds', () => {
    expect(isPhraseUnlocked(kjempebra, baseProfile, ['kjempebra'])).toBe(true);
  });
});

describe('availablePhrases — includes new phrases only when owned', () => {
  it('does NOT include dyktig or kjempebra when ownedIds is empty', () => {
    const result = availablePhrases(baseProfile, []);
    const ids = result.map(p => p.id);
    expect(ids).not.toContain('dyktig');
    expect(ids).not.toContain('kjempebra');
  });

  it('includes dyktig when owned, excludes kjempebra when not owned', () => {
    const result = availablePhrases(baseProfile, ['dyktig']);
    const ids = result.map(p => p.id);
    expect(ids).toContain('dyktig');
    expect(ids).not.toContain('kjempebra');
  });

  it('includes kjempebra when owned', () => {
    const result = availablePhrases(baseProfile, ['kjempebra']);
    const ids = result.map(p => p.id);
    expect(ids).toContain('kjempebra');
  });

  it('includes all owned phrases including dyktig and kjempebra', () => {
    const result = availablePhrases(baseProfile, ['flink', 'dyktig', 'super', 'kjempebra']);
    const ids = result.map(p => p.id);
    expect(ids).toContain('bra');
    expect(ids).toContain('flink');
    expect(ids).toContain('dyktig');
    expect(ids).toContain('super');
    expect(ids).toContain('kjempebra');
    expect(result).toHaveLength(5);
  });
});

describe('isReady — dyktig respects cooldown', () => {
  const dyktig = PHRASE_CATALOG.find(e => e.phrase.id === 'dyktig')!.phrase;

  it('is NOT ready within 10000ms cooldown', () => {
    expect(isReady(dyktig, 1000 + 9999, 1000)).toBe(false);
  });

  it('IS ready at exactly 10000ms cooldown boundary', () => {
    expect(isReady(dyktig, 1000 + 10000, 1000)).toBe(true);
  });

  it('IS ready when never used (null)', () => {
    expect(isReady(dyktig, 0, null)).toBe(true);
  });
});

describe('isReady — kjempebra respects cooldown', () => {
  const kjempebra = PHRASE_CATALOG.find(e => e.phrase.id === 'kjempebra')!.phrase;

  it('is NOT ready within 18000ms cooldown', () => {
    expect(isReady(kjempebra, 1000 + 17999, 1000)).toBe(false);
  });

  it('IS ready at exactly 18000ms cooldown boundary', () => {
    expect(isReady(kjempebra, 1000 + 18000, 1000)).toBe(true);
  });

  it('IS ready when never used (null)', () => {
    expect(isReady(kjempebra, 0, null)).toBe(true);
  });
});

describe('applyPhraseToAttempt — dyktig widens window by 200ms', () => {
  const baseAttempt: Attempt = { start: 100, end: 200, peak: 150, peakRadius: 15 };
  const dyktig = PHRASE_CATALOG.find(e => e.phrase.id === 'dyktig')!.phrase;

  it('widens [start,end] by ±200ms', () => {
    const result = applyPhraseToAttempt(baseAttempt, dyktig);
    expect(result.start).toBe(-100); // 100 - 200
    expect(result.end).toBe(400);    // 200 + 200
    expect(result.peak).toBe(150);
    expect(result.peakRadius).toBe(15);
  });
});

describe('applyPhraseToAttempt — kjempebra widens window by 350ms', () => {
  const baseAttempt: Attempt = { start: 100, end: 200, peak: 150, peakRadius: 15 };
  const kjempebra = PHRASE_CATALOG.find(e => e.phrase.id === 'kjempebra')!.phrase;

  it('widens [start,end] by ±350ms', () => {
    const result = applyPhraseToAttempt(baseAttempt, kjempebra);
    expect(result.start).toBe(-250); // 100 - 350
    expect(result.end).toBe(550);    // 200 + 350
    expect(result.peak).toBe(150);
    expect(result.peakRadius).toBe(15);
  });
});

describe('applyPhraseToAttempt', () => {
  const baseAttempt: Attempt = { start: 100, end: 200, peak: 150, peakRadius: 15 };

  it('widens [start,end] symmetrically by windowBonusMs for a phrase with bonus', () => {
    const phrase = { id: 'flink', word: 'flink', windowBonusMs: 50, rewardBonus: 0, cooldownMs: 5000 };
    const result = applyPhraseToAttempt(baseAttempt, phrase);
    expect(result.start).toBe(50);  // 100 - 50
    expect(result.end).toBe(250);   // 200 + 50
    expect(result.peak).toBe(150);  // unchanged
    expect(result.peakRadius).toBe(15); // unchanged
  });

  it('leaves attempt unchanged when using BASE_PHRASE (no bonus)', () => {
    const result = applyPhraseToAttempt(baseAttempt, BASE_PHRASE);
    expect(result).toBe(baseAttempt); // same reference — no new object
  });
});

// ─── Level-gated phrase purchasability ───────────────────────────────────────

describe('isPhrasePurchasable — level gate', () => {
  const dyktigEntry = PHRASE_CATALOG.find(e => e.phrase.id === 'dyktig')!;

  it('returns false when unlockLevel exceeds player level, even with sufficient coins', () => {
    // DYKTIG requires level 2; player is level 1
    expect(isPhrasePurchasable(dyktigEntry, 1, [])).toBe(false);
  });

  it('returns true when player level meets unlockLevel and phrase is not owned', () => {
    // DYKTIG requires level 2; player reaches level 2
    expect(isPhrasePurchasable(dyktigEntry, 2, [])).toBe(true);
  });

  it('returns false when phrase is already owned', () => {
    // Even at the required level, already owned phrases are not purchasable
    expect(isPhrasePurchasable(dyktigEntry, 2, ['dyktig'])).toBe(false);
  });

  it('returns false when unlockCost is 0 (base phrases cannot be purchased)', () => {
    const baseEntry = PHRASE_CATALOG.find(e => e.phrase.id === 'bra')!;
    expect(isPhrasePurchasable(baseEntry, 5, [])).toBe(false);
  });

  it('flink (level 1, cost 50) is purchasable at level 1', () => {
    const flinkEntry = PHRASE_CATALOG.find(e => e.phrase.id === 'flink')!;
    expect(isPhrasePurchasable(flinkEntry, 1, [])).toBe(true);
  });
});

describe('nextPurchasableEntry — finds next level-eligible entry', () => {
  it('returns FLINK (unlockLevel 1) when at level 1 with no owned phrases', () => {
    const result = nextPurchasableEntry(1, []);
    expect(result).toBeDefined();
    expect(result?.phrase.id).toBe('flink');
  });

  it('returns null when FLINK is owned and player is level 1 (next is DYKTIG requiring level 2)', () => {
    // FLINK is level 1, DYKTIG is level 2; at level 1 with FLINK owned, nothing purchasable
    const result = nextPurchasableEntry(1, ['flink']);
    expect(result).toBeNull();
  });

  it('returns DYKTIG when at level 2 and FLINK is owned', () => {
    const result = nextPurchasableEntry(2, ['flink']);
    expect(result).toBeDefined();
    expect(result?.phrase.id).toBe('dyktig');
  });

  it('returns SUPER when at level 3 with FLINK and DYKTIG owned', () => {
    const result = nextPurchasableEntry(3, ['flink', 'dyktig']);
    expect(result).toBeDefined();
    expect(result?.phrase.id).toBe('super');
  });

  it('returns KJEMPEBRA when at level 4 with all previous owned', () => {
    const result = nextPurchasableEntry(4, ['flink', 'dyktig', 'super']);
    expect(result).toBeDefined();
    expect(result?.phrase.id).toBe('kjempebra');
  });

  it('returns null when all purchasable phrases are owned', () => {
    const allOwned = ['flink', 'dyktig', 'super', 'kjempebra'];
    const result = nextPurchasableEntry(5, allOwned);
    expect(result).toBeNull();
  });

  it('returns null at level 1 when all level-1 entries are already owned and next requires higher level', () => {
    // Only FLINK is level 1; if owned, nextPurchasableEntry at level 1 returns null
    const result = nextPurchasableEntry(1, ['flink']);
    expect(result).toBeNull();
  });

  it('skips level-locked entries: at level 2 with FLINK owned, returns DYKTIG not BASE', () => {
    const result = nextPurchasableEntry(2, ['flink']);
    expect(result?.phrase.id).toBe('dyktig');
    expect(result?.phrase.id).not.toBe('bra');
  });
});
