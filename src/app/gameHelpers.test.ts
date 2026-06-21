import { describe, it, expect } from 'vitest';
import {
  totalMasteredCount,
  effectiveDistractorRate,
  buildSchedulerCfg,
  boostedDeltas,
  buildGameSave,
  restoreLearnedBar,
  isCallBackTap,
  tapEngagement,
} from './gameHelpers';
import type { EffectiveDifficulty } from '../core/difficulty';
import type { Dog } from '../core/roster';
import type { Attempt } from '../core/mark';
import { newProfile } from '../core/economy';
import { engagement } from '../core/engagement';
import { serialize, deserialize } from '../state/save';

// ── Shared fixtures ────────────────────────────────────────────────────────────

const NORMAL_DIFFICULTY: EffectiveDifficulty = {
  scheduler: { windowWidth: 400, peakRadius: 80, distractorRate: 0.2 },
  deltas: { PERFECT: 8, OK: 3, MISS: 0, FALSE_MARK: -4 },
  rewardMultiplier: 1,
  tellIntensity: 1,
  learnMult: 1,
};

const HARD_DIFFICULTY: EffectiveDifficulty = {
  scheduler: { windowWidth: 280, peakRadius: 50, distractorRate: 0.45 },
  deltas: { PERFECT: 8, OK: 3, MISS: 0, FALSE_MARK: -8 },
  rewardMultiplier: 1.5,
  tellIntensity: 0.6,
  learnMult: 1,
};

function makeDog(id: string, masteredTrickIds: string[]): Dog {
  return { id, name: id, breedId: 'labrador', masteredTrickIds };
}

// ── totalMasteredCount ─────────────────────────────────────────────────────────

describe('totalMasteredCount', () => {
  it('returns 0 for an empty roster', () => {
    expect(totalMasteredCount([])).toBe(0);
  });

  it('returns 0 when no dog has mastered any trick', () => {
    const roster = [makeDog('rex', []), makeDog('buddy', [])];
    expect(totalMasteredCount(roster)).toBe(0);
  });

  it('returns 1 when a single dog has mastered 1 trick', () => {
    const roster = [makeDog('rex', ['sitt'])];
    expect(totalMasteredCount(roster)).toBe(1);
  });

  it('sums tricks across multiple dogs', () => {
    const roster = [makeDog('rex', ['sitt', 'ligg']), makeDog('buddy', ['sitt'])];
    expect(totalMasteredCount(roster)).toBe(3);
  });

  it('counts the same trick id separately per dog (each mastery is independent)', () => {
    const roster = [makeDog('rex', ['sitt']), makeDog('buddy', ['sitt'])];
    expect(totalMasteredCount(roster)).toBe(2);
  });

  it('does not mutate the roster', () => {
    const roster = [makeDog('rex', ['sitt'])];
    totalMasteredCount(roster);
    expect(roster[0].masteredTrickIds).toEqual(['sitt']);
  });
});

// ── effectiveDistractorRate ────────────────────────────────────────────────────

describe('effectiveDistractorRate', () => {
  it('returns 0 when masteredCount is 0 (onboarding: distractors not yet revealed)', () => {
    expect(effectiveDistractorRate(0, NORMAL_DIFFICULTY)).toBe(0);
  });

  it('returns the roundDifficulty rate once masteredCount reaches 1 (reveal threshold)', () => {
    expect(effectiveDistractorRate(1, NORMAL_DIFFICULTY)).toBe(0.2);
  });

  it('returns the roundDifficulty rate for masteredCount > 1', () => {
    expect(effectiveDistractorRate(5, NORMAL_DIFFICULTY)).toBe(0.2);
  });

  it('works correctly with HARD difficulty rate after reveal', () => {
    expect(effectiveDistractorRate(1, HARD_DIFFICULTY)).toBe(0.45);
  });

  it('gates HARD difficulty rate to 0 before reveal (0 mastered)', () => {
    expect(effectiveDistractorRate(0, HARD_DIFFICULTY)).toBe(0);
  });
});

// ── buildSchedulerCfg ─────────────────────────────────────────────────────────

describe('buildSchedulerCfg', () => {
  it('returns base timing constants attemptInterval 2000 and activeSpan 800', () => {
    const cfg = buildSchedulerCfg(1, NORMAL_DIFFICULTY);
    expect(cfg.attemptInterval).toBe(2000);
    expect(cfg.activeSpan).toBe(800);
  });

  it('picks up windowWidth and peakRadius from roundDifficulty', () => {
    const cfg = buildSchedulerCfg(1, NORMAL_DIFFICULTY);
    expect(cfg.windowWidth).toBe(400);
    expect(cfg.peakRadius).toBe(80);
  });

  it('gates distractorRate to 0 when masteredCount is 0', () => {
    const cfg = buildSchedulerCfg(0, NORMAL_DIFFICULTY);
    expect(cfg.distractorRate).toBe(0);
  });

  it('uses roundDifficulty distractorRate after reveal (masteredCount >= 1)', () => {
    const cfg = buildSchedulerCfg(1, NORMAL_DIFFICULTY);
    expect(cfg.distractorRate).toBe(0.2);
  });

  it('reflects HARD difficulty scheduler fields', () => {
    const cfg = buildSchedulerCfg(2, HARD_DIFFICULTY);
    expect(cfg.windowWidth).toBe(280);
    expect(cfg.peakRadius).toBe(50);
    expect(cfg.distractorRate).toBe(0.45);
  });

  it('distractorRate is 0 for HARD difficulty before reveal', () => {
    const cfg = buildSchedulerCfg(0, HARD_DIFFICULTY);
    expect(cfg.distractorRate).toBe(0);
  });
});

// ── boostedDeltas ─────────────────────────────────────────────────────────────

describe('boostedDeltas', () => {
  const baseDeltas = { PERFECT: 8, OK: 3, MISS: 0, FALSE_MARK: -4 };

  it('returns identical values at multiplier 1', () => {
    const result = boostedDeltas(baseDeltas, 1);
    expect(result.PERFECT).toBe(8);
    expect(result.OK).toBe(3);
    expect(result.MISS).toBe(0);
    expect(result.FALSE_MARK).toBe(-4);
  });

  it('scales PERFECT and OK proportionally for multiplier 2', () => {
    const result = boostedDeltas(baseDeltas, 2);
    expect(result.PERFECT).toBe(16);
    expect(result.OK).toBe(6);
  });

  it('does NOT change MISS on boost', () => {
    const result = boostedDeltas(baseDeltas, 2);
    expect(result.MISS).toBe(0);
  });

  it('does NOT change FALSE_MARK on boost', () => {
    const result = boostedDeltas(baseDeltas, 2);
    expect(result.FALSE_MARK).toBe(-4);
  });

  it('rounds PERFECT to integer on fractional multiplier', () => {
    // 8 * 1.1 = 8.8 → rounds to 9
    const result = boostedDeltas(baseDeltas, 1.1);
    expect(result.PERFECT).toBe(9);
  });

  it('rounds OK to integer on fractional multiplier', () => {
    // 3 * 1.1 = 3.3 → rounds to 3
    const result = boostedDeltas(baseDeltas, 1.1);
    expect(result.OK).toBe(3);
  });

  it('does not mutate the original deltas', () => {
    const deltas = { PERFECT: 8, OK: 3, MISS: 0, FALSE_MARK: -4 };
    boostedDeltas(deltas, 2);
    expect(deltas.PERFECT).toBe(8);
  });
});

// ── buildGameSave ─────────────────────────────────────────────────────────────

describe('buildGameSave', () => {
  const baseParams = {
    profile: newProfile(),
    roster: [makeDog('rex', ['sitt'])],
    kennelUpgradeIds: ['kennel-1'],
    difficultyMode: 'NORMAL' as const,
    unlockedPhraseIds: ['phrase-a'],
    prestigePoints: 5,
    idleTimestamp: 1000000,
  };

  it('includes profile in the save', () => {
    const save = buildGameSave(baseParams);
    expect(save.profile).toBe(baseParams.profile);
  });

  it('includes roster in the save', () => {
    const save = buildGameSave(baseParams);
    expect(save.roster).toBe(baseParams.roster);
  });

  it('includes kennelUpgradeIds in the save', () => {
    const save = buildGameSave(baseParams);
    expect(save.kennelUpgradeIds).toEqual(['kennel-1']);
  });

  it('includes difficultyMode in the save', () => {
    const save = buildGameSave(baseParams);
    expect(save.difficultyMode).toBe('NORMAL');
  });

  it('includes unlockedPhraseIds in the save', () => {
    const save = buildGameSave(baseParams);
    expect(save.unlockedPhraseIds).toEqual(['phrase-a']);
  });

  it('includes prestigePoints in the save', () => {
    const save = buildGameSave(baseParams);
    expect(save.prestigePoints).toBe(5);
  });

  it('includes idleTimestamp in the save', () => {
    const save = buildGameSave(baseParams);
    expect(save.idleTimestamp).toBe(1000000);
  });

  it('reflects HARD difficultyMode correctly', () => {
    const save = buildGameSave({ ...baseParams, difficultyMode: 'HARD' });
    expect(save.difficultyMode).toBe('HARD');
  });

  it('reflects EXPERT difficultyMode correctly', () => {
    const save = buildGameSave({ ...baseParams, difficultyMode: 'EXPERT' });
    expect(save.difficultyMode).toBe('EXPERT');
  });

  it('reflects prestigePoints 0 for a fresh save', () => {
    const save = buildGameSave({ ...baseParams, prestigePoints: 0 });
    expect(save.prestigePoints).toBe(0);
  });

  it('builds the complete GameSave shape with all required fields', () => {
    const save = buildGameSave(baseParams);
    // Structural check — all fields present (masteredTrickIds removed from top-level)
    expect(Object.keys(save)).toEqual(
      expect.arrayContaining([
        'profile',
        'idleTimestamp',
        'kennelUpgradeIds',
        'difficultyMode',
        'roster',
        'unlockedPhraseIds',
        'prestigePoints',
      ])
    );
  });
});

// ─── Cleanup Task 076: top-level masteredTrickIds removal ─────────────────────

describe('buildGameSave — removal of dead top-level masteredTrickIds', () => {
  it('does not include masteredTrickIds as an own property at the top level', () => {
    const save = buildGameSave({
      profile: newProfile(),
      roster: [{ id: 'rex', name: 'Rex', breedId: 'labrador', masteredTrickIds: ['sitt'] }],
      kennelUpgradeIds: [],
      difficultyMode: 'NORMAL' as const,
      unlockedPhraseIds: [],
      prestigePoints: 0,
      idleTimestamp: 1000000,
    });
    expect(Object.prototype.hasOwnProperty.call(save, 'masteredTrickIds')).toBe(false);
    expect(save.roster).toHaveLength(1);
    expect(save.roster[0].masteredTrickIds).toEqual(['sitt']);
  });
});

// ── restoreLearnedBar ──────────────────────────────────────────────────────────

describe('restoreLearnedBar', () => {
  it('returns the saved bar when savedDogId and savedTrickId match startDogId and startTrickId', () => {
    const result = restoreLearnedBar({
      savedDogId: 'rex',
      savedTrickId: 'sitt',
      savedBar: 70,
      startDogId: 'rex',
      startTrickId: 'sitt',
    });
    expect(result).toBe(70);
  });

  it('returns 0 when the dog differs from saved', () => {
    const result = restoreLearnedBar({
      savedDogId: 'rex',
      savedTrickId: 'sitt',
      savedBar: 70,
      startDogId: 'buddy',
      startTrickId: 'sitt',
    });
    expect(result).toBe(0);
  });

  it('returns 0 when the trick differs from saved', () => {
    const result = restoreLearnedBar({
      savedDogId: 'rex',
      savedTrickId: 'sitt',
      savedBar: 70,
      startDogId: 'rex',
      startTrickId: 'ligg',
    });
    expect(result).toBe(0);
  });

  it('returns 0 when there is no saved round (savedTrickId is null)', () => {
    const result = restoreLearnedBar({
      savedDogId: null,
      savedTrickId: null,
      savedBar: 70,
      startDogId: 'rex',
      startTrickId: 'sitt',
    });
    expect(result).toBe(0);
  });

  it('clamps a malformed saved bar above 100 to 100 on a match', () => {
    const result = restoreLearnedBar({
      savedDogId: 'rex',
      savedTrickId: 'sitt',
      savedBar: 150,
      startDogId: 'rex',
      startTrickId: 'sitt',
    });
    expect(result).toBe(100);
  });

  it('clamps a malformed saved bar below 0 to 0 on a match', () => {
    const result = restoreLearnedBar({
      savedDogId: 'rex',
      savedTrickId: 'sitt',
      savedBar: -10,
      startDogId: 'rex',
      startTrickId: 'sitt',
    });
    expect(result).toBe(0);
  });
});

// ── buildGameSave with active round fields ─────────────────────────────────────

describe('buildGameSave — active round persistence', () => {
  const baseParams = {
    profile: newProfile(),
    roster: [makeDog('rex', ['sitt'])],
    kennelUpgradeIds: ['kennel-1'],
    difficultyMode: 'NORMAL' as const,
    unlockedPhraseIds: ['phrase-a'],
    prestigePoints: 5,
    idleTimestamp: 1000000,
  };

  it('includes activeRoundDogId, activeTrickId, learnedBar when provided', () => {
    const save = buildGameSave({
      ...baseParams,
      activeRoundDogId: 'rex',
      activeTrickId: 'sitt',
      learnedBar: 55,
    });
    expect(save.activeRoundDogId).toBe('rex');
    expect(save.activeTrickId).toBe('sitt');
    expect(save.learnedBar).toBe(55);
  });

  it('defaults activeRoundDogId to null when not provided', () => {
    const save = buildGameSave(baseParams);
    expect(save.activeRoundDogId).toBe(null);
  });

  it('defaults activeTrickId to null when not provided', () => {
    const save = buildGameSave(baseParams);
    expect(save.activeTrickId).toBe(null);
  });

  it('defaults learnedBar to 0 when not provided', () => {
    const save = buildGameSave(baseParams);
    expect(save.learnedBar).toBe(0);
  });
});

// ── Resume round-trip integration (task 113) ────────────────────────────────────
//
// Spec §Round States: "Resumable: partial learned-bar progress persists." The links
// (buildGameSave, serialize/deserialize, restoreLearnedBar) are each unit-tested in
// isolation above + in save.test.ts, but nothing exercised the FULL persist→reload
// chain. A regression in any link (a dropped GameSave field, a renamed key, a default
// that clobbers the saved bar) would silently discard a player's partial progress on
// restart while the per-link suites stayed green. This block is that guard — it runs
// the real serialize/deserialize pair (no mocks), so it fails if the round-trip breaks.
describe('resume round-trip — partial learned-bar persists (buildGameSave → serialize → deserialize → restoreLearnedBar)', () => {
  const baseParams = {
    profile: newProfile(),
    roster: [makeDog('rex', [])],
    kennelUpgradeIds: [],
    difficultyMode: 'NORMAL' as const,
    unlockedPhraseIds: [],
    prestigePoints: 0,
    idleTimestamp: 1000000,
  };

  it('restores the same partial bar after a real serialize → deserialize cycle', () => {
    const save = buildGameSave({
      ...baseParams,
      activeRoundDogId: 'rex',
      activeTrickId: 'sitt',
      learnedBar: 42,
    });

    const restored = deserialize(serialize(save)); // the actual persistence path
    expect(restored).not.toBeNull();

    const bar = restoreLearnedBar({
      savedDogId: restored!.activeRoundDogId,
      savedTrickId: restored!.activeTrickId,
      savedBar: restored!.learnedBar,
      startDogId: 'rex',
      startTrickId: 'sitt',
    });
    expect(bar).toBe(42); // ← the spec promise: partial progress survives a restart
  });

  it('resumes at 0 (fresh) when no round was in progress before the save', () => {
    const save = buildGameSave(baseParams); // no active round fields → null/null/0
    const restored = deserialize(serialize(save));
    expect(restored).not.toBeNull();

    const bar = restoreLearnedBar({
      savedDogId: restored!.activeRoundDogId,
      savedTrickId: restored!.activeTrickId,
      savedBar: restored!.learnedBar,
      startDogId: 'rex',
      startTrickId: 'sitt',
    });
    expect(bar).toBe(0);
  });

  it('does not mis-apply a saved partial bar onto a different dog after reload', () => {
    const save = buildGameSave({
      ...baseParams,
      activeRoundDogId: 'rex',
      activeTrickId: 'sitt',
      learnedBar: 80,
    });
    const restored = deserialize(serialize(save));
    expect(restored).not.toBeNull();

    const bar = restoreLearnedBar({
      savedDogId: restored!.activeRoundDogId,
      savedTrickId: restored!.activeTrickId,
      savedBar: restored!.learnedBar,
      startDogId: 'buddy', // resumed a different dog
      startTrickId: 'sitt',
    });
    expect(bar).toBe(0);
  });

  it('does not mis-apply a saved partial bar onto a different trick after reload', () => {
    const save = buildGameSave({
      ...baseParams,
      activeRoundDogId: 'rex',
      activeTrickId: 'sitt',
      learnedBar: 80,
    });
    const restored = deserialize(serialize(save));
    expect(restored).not.toBeNull();

    const bar = restoreLearnedBar({
      savedDogId: restored!.activeRoundDogId,
      savedTrickId: restored!.activeTrickId,
      savedBar: restored!.learnedBar,
      startDogId: 'rex',
      startTrickId: 'ligg', // resumed a different trick
    });
    expect(bar).toBe(0);
  });
});

// ── isCallBackTap ───────────────────────────────────────────────────────────
// Names the "branch BEFORE classification" rule: when the dog has walked off
// (engagement empty → disengageBeat 'walk-off') a tap calls it back, not marks.

describe('isCallBackTap', () => {
  it('is true at an empty meter (the dog has walked off)', () => {
    expect(isCallBackTap(0)).toBe(true);
  });

  it('is false at a full meter (dog engaged)', () => {
    expect(isCallBackTap(1)).toBe(false);
  });

  it('is false at a low-but-nonzero meter (a beat, not a walk-off)', () => {
    // 0.1 → 'bark' beat; only 'walk-off' (empty) is a call-back.
    expect(isCallBackTap(0.1)).toBe(false);
  });
});

// ── tapEngagement ───────────────────────────────────────────────────────────
// Composes the mark transition and the conditional reward-latency transition in
// one tested place. Reward leg fires ONLY on PERFECT/OK with an attempt, AFTER
// the unconditional mark transition. Relational asserts survive tuning changes.

describe('tapEngagement', () => {
  const ATTEMPT: Attempt = { start: 0, end: 2000, peak: 1000, peakRadius: 80 };
  const PREV = 0.5;
  const SLOW_TNOW = 1000 + 5000; // 5s after apex → draining reward latency

  it('PERFECT with an attempt applies the mark then the reward transition', () => {
    const markOnly = engagement(PREV, { kind: 'mark', result: 'PERFECT' });
    const both = engagement(markOnly, { kind: 'reward', latencyMs: 5000 });
    expect(
      tapEngagement({ engagementMeter: PREV, result: 'PERFECT', attempt: ATTEMPT, tnow: SLOW_TNOW }),
    ).toBe(both);
  });

  it('the reward leg actually runs for PERFECT (differs from mark-only)', () => {
    const markOnly = engagement(PREV, { kind: 'mark', result: 'PERFECT' });
    expect(
      tapEngagement({ engagementMeter: PREV, result: 'PERFECT', attempt: ATTEMPT, tnow: SLOW_TNOW }),
    ).not.toBe(markOnly);
  });

  it('OK with an attempt also applies both transitions', () => {
    const both = engagement(
      engagement(PREV, { kind: 'mark', result: 'OK' }),
      { kind: 'reward', latencyMs: 5000 },
    );
    expect(
      tapEngagement({ engagementMeter: PREV, result: 'OK', attempt: ATTEMPT, tnow: SLOW_TNOW }),
    ).toBe(both);
  });

  it('MISS applies only the mark transition (no reward leg)', () => {
    const markOnly = engagement(PREV, { kind: 'mark', result: 'MISS' });
    expect(
      tapEngagement({ engagementMeter: PREV, result: 'MISS', attempt: ATTEMPT, tnow: SLOW_TNOW }),
    ).toBe(markOnly);
  });

  it('FALSE_MARK applies only the mark transition', () => {
    const markOnly = engagement(PREV, { kind: 'mark', result: 'FALSE_MARK' });
    expect(
      tapEngagement({ engagementMeter: PREV, result: 'FALSE_MARK', attempt: null, tnow: SLOW_TNOW }),
    ).toBe(markOnly);
  });

  it('skips the reward leg when attempt is null even for a PERFECT tier', () => {
    const markOnly = engagement(PREV, { kind: 'mark', result: 'PERFECT' });
    expect(
      tapEngagement({ engagementMeter: PREV, result: 'PERFECT', attempt: null, tnow: SLOW_TNOW }),
    ).toBe(markOnly);
  });
});
