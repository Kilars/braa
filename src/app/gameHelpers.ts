/**
 * Pure helper functions extracted from main.ts.
 *
 * No DOM, no Babylon, no IndexedDB. All functions are deterministic
 * given their inputs and safe to unit-test in isolation.
 */

import type { SchedulerConfig } from '../core/scheduler';
import type { EffectiveDifficulty } from '../core/difficulty';
import type { MarkResult } from '../core/mark';
import type { Dog } from '../core/roster';
import type { Profile } from '../core/economy';
import type { DifficultyMode } from '../core/difficulty';
import type { GameSave } from '../state/save';
import { onboardingStage } from '../core/onboarding';

// ── totalMasteredCount ─────────────────────────────────────────────────────────

/**
 * Total number of unique tricks mastered across all dogs in the roster.
 * Each dog's masteredTrickIds is counted independently (same trick on two
 * different dogs counts twice).
 */
export function totalMasteredCount(roster: Dog[]): number {
  return roster.reduce((sum, dog) => sum + dog.masteredTrickIds.length, 0);
}

// ── effectiveDistractorRate ────────────────────────────────────────────────────

/**
 * Gate the distractor rate to 0 until onboarding reveals distractors
 * (i.e. the player has mastered at least 1 trick). After reveal, uses
 * whatever the roundDifficulty has already computed (mode × trick profile).
 */
export function effectiveDistractorRate(
  masteredCount: number,
  roundDifficulty: EffectiveDifficulty,
): number {
  const revealed = onboardingStage(masteredCount);
  return revealed.distractors ? roundDifficulty.scheduler.distractorRate : 0;
}

// ── buildSchedulerCfg ─────────────────────────────────────────────────────────

/**
 * Assemble a SchedulerConfig from the current round difficulty and onboarding
 * state. Hard-codes the base timing constants (attemptInterval, activeSpan) that
 * are overridden by the spread of roundDifficulty.scheduler, then gates the
 * distractor rate via effectiveDistractorRate.
 */
export function buildSchedulerCfg(
  masteredCount: number,
  roundDifficulty: EffectiveDifficulty,
): SchedulerConfig {
  return {
    attemptInterval: 2000,
    activeSpan: 800,
    ...roundDifficulty.scheduler,
    distractorRate: effectiveDistractorRate(masteredCount, roundDifficulty),
  };
}

// ── boostedDeltas ─────────────────────────────────────────────────────────────

/**
 * Apply a combo multiplier to the positive learned-bar deltas (PERFECT, OK).
 * MISS and FALSE_MARK are not boosted — multiplier only rewards sustained
 * correct marks.
 *
 * Values are rounded to integers so the session bar advances in whole
 * percentage points.
 */
export function boostedDeltas(
  deltas: Record<MarkResult, number>,
  comboMult: number,
): Record<MarkResult, number> {
  return {
    PERFECT: Math.round(deltas.PERFECT * comboMult),
    OK: Math.round(deltas.OK * comboMult),
    MISS: deltas.MISS,
    FALSE_MARK: deltas.FALSE_MARK,
  };
}

// ── buildGameSave ─────────────────────────────────────────────────────────────

/**
 * Pure snapshot builder: given the current mutable game state values, returns
 * the GameSave object that should be persisted. The actual `storage.save()` call
 * stays in main.ts; this function is responsible only for assembling the shape.
 *
 * Extracting this protects persistence correctness: a unit test can assert that
 * every field is present and correctly mapped from the inputs.
 */
export function buildGameSave(params: {
  profile: Profile;
  roster: Dog[];
  kennelUpgradeIds: string[];
  difficultyMode: DifficultyMode;
  unlockedPhraseIds: string[];
  prestigePoints: number;
  idleTimestamp: number;
  muted?: boolean;
  bestCombo?: number;
  streak?: number;
  lastPlayedYmd?: string;
}): GameSave {
  return {
    profile: params.profile,
    idleTimestamp: params.idleTimestamp,
    kennelUpgradeIds: params.kennelUpgradeIds,
    difficultyMode: params.difficultyMode,
    roster: params.roster,
    unlockedPhraseIds: params.unlockedPhraseIds,
    prestigePoints: params.prestigePoints,
    muted: params.muted ?? false,
    bestCombo: params.bestCombo ?? 0,
    streak: params.streak ?? 0,
    lastPlayedYmd: params.lastPlayedYmd ?? '',
  };
}
