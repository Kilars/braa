/**
 * Pure helper functions extracted from main.ts.
 *
 * No DOM, no Babylon, no IndexedDB. All functions are deterministic
 * given their inputs and safe to unit-test in isolation.
 */

import type { SchedulerConfig } from '../core/scheduler';
import type { EffectiveDifficulty } from '../core/difficulty';
import type { MarkResult, Attempt } from '../core/mark';
import type { Dog } from '../core/roster';
import type { Profile } from '../core/economy';
import type { DifficultyMode } from '../core/difficulty';
import type { GameSave } from '../state/save';
import { onboardingStage } from '../core/onboarding';
import { engagement, rewardLatencyMs, disengageBeat } from '../core/engagement';
import { isDisengaged } from '../core/disengage';
import { BASE_SCHEDULER_TIMING } from '../core/tuning';

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
 * Base scheduler timing applied before any difficulty/breed/trick overrides.
 * Single source of truth so the bootstrap config in main.ts and buildSchedulerCfg
 * can never drift apart. Both spread roundDifficulty.scheduler on top of this.
 *
 * Homed in the central tuning module; re-exported here so the existing
 * `./app/gameHelpers` import in main.ts stays stable.
 */
export { BASE_SCHEDULER_TIMING } from '../core/tuning';

/**
 * Assemble a SchedulerConfig from the current round difficulty and onboarding
 * state. Starts from BASE_SCHEDULER_TIMING, which is overridden by the spread of
 * roundDifficulty.scheduler, then gates the distractor rate via
 * effectiveDistractorRate.
 */
export function buildSchedulerCfg(
  masteredCount: number,
  roundDifficulty: EffectiveDifficulty,
): SchedulerConfig {
  return {
    ...BASE_SCHEDULER_TIMING,
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

// ── restoreLearnedBar ─────────────────────────────────────────────────────────

/**
 * Pure resume rule: returns the saved partial learned-bar when the starting
 * dog+trick match the saved active round, otherwise returns 0 (fresh start).
 * Clamps malformed saved values into [0, 100].
 */
export function restoreLearnedBar(args: {
  savedDogId: string | null;
  savedTrickId: string | null;
  savedBar: number;
  startDogId: string;
  startTrickId: string;
}): number {
  const match =
    args.savedTrickId !== null &&
    args.savedDogId === args.startDogId &&
    args.savedTrickId === args.startTrickId;
  if (!match) return 0;
  return Math.min(100, Math.max(0, args.savedBar));
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
  activeRoundDogId?: string | null;
  activeTrickId?: string | null;
  learnedBar?: number;
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
    activeRoundDogId: params.activeRoundDogId ?? null,
    activeTrickId: params.activeTrickId ?? null,
    learnedBar: params.learnedBar ?? 0,
  };
}

// ── Tap decisions (extracted from main.ts onBraTapCommit) ───────────────────────

/**
 * Whether a BRA tap should CALL THE DOG BACK instead of marking. True only when
 * the dog has fully disengaged (engagement empty → `disengageBeat` 'walk-off').
 * Names the loop's "branch BEFORE classification" rule (task 107) so a call-back
 * can never score or false-mark. Pure.
 */
export function isCallBackTap(engagementMeter: number): boolean {
  return isDisengaged(disengageBeat(engagementMeter));
}

/**
 * The engagement meter after a scoring tap. Applies the unconditional
 * `{ kind:'mark', result }` transition, then — only on a real reward
 * (`PERFECT`/`OK` with an `attempt`) — the subsequent `{ kind:'reward', latencyMs }`
 * transition driven by how promptly the apex was rewarded (spec §Mistakes: "slow
 * rewards drain it"). Single source of truth for the order + the reward condition,
 * so the loop's most edit-fragile composition is unit-tested. Pure.
 */
export function tapEngagement(params: {
  engagementMeter: number;
  result: MarkResult;
  attempt: Attempt | null;
  tnow: number;
}): number {
  let meter = engagement(params.engagementMeter, { kind: 'mark', result: params.result });
  if ((params.result === 'PERFECT' || params.result === 'OK') && params.attempt) {
    meter = engagement(meter, {
      kind: 'reward',
      latencyMs: rewardLatencyMs(params.tnow, params.attempt.peak),
    });
  }
  return meter;
}
