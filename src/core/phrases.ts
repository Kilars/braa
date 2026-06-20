import type { Attempt } from './mark';
import type { Profile } from './economy';
import { isTierUnlocked } from './economy';

export interface Phrase {
  id: string;
  word: string;
  windowBonusMs: number;
  rewardBonus: number;
  cooldownMs: number;
  /** Downside: shrinks the PERFECT band so the reward bonus must be earned. 0 = none. */
  peakRadiusPenaltyMs: number;
}

export interface PhraseEntry {
  phrase: Phrase;
  /** Cost to unlock; 0 for base phrases that are always available. */
  unlockCost: number;
  /** Minimum profile level required to unlock. */
  unlockLevel: number;
}

export const BASE_PHRASE: Phrase = {
  id: 'bra',
  word: 'bra',
  windowBonusMs: 0,
  rewardBonus: 0,
  cooldownMs: 0,
  peakRadiusPenaltyMs: 0,
};

const FLINK_PHRASE: Phrase = {
  id: 'flink',
  word: 'flink',
  windowBonusMs: 150,
  rewardBonus: 0.1,
  cooldownMs: 8000,
  peakRadiusPenaltyMs: 0, // onboarding-gentle: no precision cost
};

const SUPER_PHRASE: Phrase = {
  id: 'super',
  word: 'super',
  windowBonusMs: 250,
  rewardBonus: 0.2,
  cooldownMs: 12000,
  peakRadiusPenaltyMs: 40, // medium penalty: precision-for-payout tradeoff
};

const DYKTIG_PHRASE: Phrase = {
  id: 'dyktig',
  word: 'dyktig',
  windowBonusMs: 200,
  rewardBonus: 0.15,
  cooldownMs: 10000,
  peakRadiusPenaltyMs: 25, // small penalty: mild tradeoff
};

const KJEMPEBRA_PHRASE: Phrase = {
  id: 'kjempebra',
  word: 'kjempebra',
  windowBonusMs: 350,
  rewardBonus: 0.3,
  cooldownMs: 18000,
  peakRadiusPenaltyMs: 65, // largest penalty: biggest reward demands the tightest peak
};

/** Full ordered catalog — first entry is always BASE (free). */
export const PHRASE_CATALOG: PhraseEntry[] = [
  { phrase: BASE_PHRASE,       unlockCost: 0,   unlockLevel: 1 },
  { phrase: FLINK_PHRASE,      unlockCost: 50,  unlockLevel: 1 },
  { phrase: DYKTIG_PHRASE,     unlockCost: 175, unlockLevel: 2 },
  { phrase: SUPER_PHRASE,      unlockCost: 275, unlockLevel: 3 },
  { phrase: KJEMPEBRA_PHRASE,  unlockCost: 450, unlockLevel: 4 },
];

/**
 * Returns true when the player owns the phrase or it is the free base phrase.
 * BASE_PHRASE (id 'bra') is always available regardless of ownedIds or profile.
 */
export function isPhraseUnlocked(
  phrase: Phrase,
  _profile: Profile,
  ownedIds: string[],
): boolean {
  const entry = PHRASE_CATALOG.find(e => e.phrase.id === phrase.id);
  if (!entry) return false;
  if (entry.unlockCost === 0 && entry.unlockLevel <= 1) return true; // base
  return ownedIds.includes(phrase.id);
}

/** All phrases the player can currently load (base + any they own). */
export function availablePhrases(
  profile: Profile,
  ownedIds: string[],
): Phrase[] {
  return PHRASE_CATALOG
    .filter(e => isPhraseUnlocked(e.phrase, profile, ownedIds))
    .map(e => e.phrase);
}

/**
 * Returns true when a phrase entry is eligible for purchase:
 * - has a cost (not a base phrase)
 * - not already owned
 * - player level meets the entry's required level
 * Coin affordability is NOT checked here — callers distinguish level-locked vs coin-locked.
 */
export function isPhrasePurchasable(entry: PhraseEntry, level: number, ownedIds: string[]): boolean {
  return entry.unlockCost > 0
    && !ownedIds.includes(entry.phrase.id)
    && isTierUnlocked(level, entry.unlockLevel);
}

/**
 * Returns the first PHRASE_CATALOG entry the player is level-eligible to buy
 * (not owned, cost > 0, level >= unlockLevel), or null when none exists.
 * Coin affordability is checked separately at the call site.
 */
export function nextPurchasableEntry(level: number, ownedIds: string[]): PhraseEntry | null {
  return PHRASE_CATALOG.find(e => isPhrasePurchasable(e, level, ownedIds)) ?? null;
}

export function isReady(p: Phrase, now: number, lastUsedAt: number | null): boolean {
  if (p.cooldownMs === 0) return true;
  if (lastUsedAt === null) return true;
  return now - lastUsedAt >= p.cooldownMs;
}

const PEAK_RADIUS_FLOOR_MS = 20;

export function applyPhraseToAttempt(a: Attempt, p: Phrase): Attempt {
  if (p.windowBonusMs === 0 && p.peakRadiusPenaltyMs === 0) return a;
  return {
    ...a,
    start: a.start - p.windowBonusMs,
    end: a.end + p.windowBonusMs,
    ...(p.peakRadiusPenaltyMs > 0 && {
      peakRadius: Math.max(PEAK_RADIUS_FLOOR_MS, a.peakRadius - p.peakRadiusPenaltyMs),
    }),
  };
}
