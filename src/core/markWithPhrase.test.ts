import { describe, it, expect } from 'vitest';
import { resolvePhraseMark } from './markWithPhrase';
import { BASE_PHRASE } from './phrases';
import type { Attempt } from './mark';
import type { Phrase } from './phrases';

const COOL_PHRASE: Phrase = {
  id: 'flink',
  word: 'flink',
  windowBonusMs: 200,
  rewardBonus: 0.1,
  cooldownMs: 5000,
};

const BASE_ATTEMPT: Attempt = { start: 100, end: 200, peak: 150, peakRadius: 15 };

describe('resolvePhraseMark', () => {
  describe('ready phrase + active attempt', () => {
    it('widens the attempt and fires', () => {
      const now = 10_000;
      const lastUsedAt = null; // never used — ready
      const result = resolvePhraseMark(BASE_ATTEMPT, COOL_PHRASE, now, lastUsedAt);
      expect(result.fired).toBe(true);
      expect(result.attempt).not.toBeNull();
      expect(result.attempt!.start).toBe(BASE_ATTEMPT.start - COOL_PHRASE.windowBonusMs);
      expect(result.attempt!.end).toBe(BASE_ATTEMPT.end + COOL_PHRASE.windowBonusMs);
    });
  });

  describe('phrase on cooldown + active attempt', () => {
    it('returns the base (unwidened) attempt and does not fire', () => {
      const lastUsedAt = 5_000;
      const now = lastUsedAt + COOL_PHRASE.cooldownMs - 1; // 1ms before cooldown expires
      const result = resolvePhraseMark(BASE_ATTEMPT, COOL_PHRASE, now, lastUsedAt);
      expect(result.fired).toBe(false);
      expect(result.attempt).toBe(BASE_ATTEMPT); // same reference — no widening
    });
  });

  describe('BASE_PHRASE', () => {
    it('always fires and leaves attempt unchanged (windowBonusMs=0)', () => {
      const justUsed = 1_000;
      const now = 1_001; // 1ms after use — base_phrase is always ready (no cooldown)
      const result = resolvePhraseMark(BASE_ATTEMPT, BASE_PHRASE, now, justUsed);
      expect(result.fired).toBe(true);
      expect(result.attempt).toBe(BASE_ATTEMPT); // applyPhraseToAttempt returns same ref when bonus=0
    });
  });

  describe('no active attempt', () => {
    it('attempt stays null and fired=true when phrase is ready', () => {
      const result = resolvePhraseMark(null, COOL_PHRASE, 10_000, null);
      expect(result.attempt).toBeNull();
      expect(result.fired).toBe(true);
    });

    it('attempt stays null and fired=false when phrase is on cooldown', () => {
      const lastUsedAt = 5_000;
      const now = lastUsedAt + 1; // well within cooldown
      const result = resolvePhraseMark(null, COOL_PHRASE, now, lastUsedAt);
      expect(result.attempt).toBeNull();
      expect(result.fired).toBe(false);
    });
  });
});
