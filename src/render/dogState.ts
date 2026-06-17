import type { RoundState } from '../core/round';
import { isConfused } from '../core/session';
import { attemptAt, distractorActiveAt, untrainAttemptAt } from '../core/scheduler';

export type DogVisual = 'idle' | 'offering' | 'confused' | 'happy' | 'distractor' | 'misbehaving';

export interface DogVisualOpts {
  untrain?: boolean; // true = untraining mode (calm = offering, distractor = misbehaving)
  /** 0..1 proximity to the attempt apex (1 = at the markable peak). Drives on-dog apex pop. */
  peakProximity?: number;
  /** 0..1 tell intensity for this difficulty (1 = full cue, lower = fainter on harder modes). */
  tellStrength?: number;
  /** Active trick id — passed through to dogPose so the offering pose is trick-specific (D11). */
  trickId?: string;
}

/**
 * Pure mapping: RoundState + now → one of six visual states.
 *
 * Normal trick precedence (highest first):
 *   mastered → 'happy'
 *   isConfused(session, now) → 'confused'
 *   attemptAt(timeline, now) non-null → 'offering'
 *   distractorActiveAt(timeline, now) → 'distractor'
 *   else → 'idle'
 *
 * Untraining trick (opts.untrain=true) — inverted semantics:
 *   mastered → 'happy'
 *   isConfused(session, now) → 'confused'
 *   distractorActiveAt(timeline, now) → 'misbehaving' (bad habit, do NOT mark)
 *   untrainAttemptAt(timeline, now) non-null → 'offering' (calm gap, mark this)
 *   else → 'idle'
 *
 * No Babylon imports — pure logic only.
 */
export function dogVisualState(state: RoundState, now: number, opts?: DogVisualOpts): DogVisual {
  if (state.session.mastered) return 'happy';
  if (isConfused(state.session, now)) return 'confused';

  if (opts?.untrain) {
    // Inverted: bad-habit (distractor) windows are NOT markable → misbehaving
    if (distractorActiveAt(state.timeline, now)) return 'misbehaving';
    // Calm gap → markable
    if (untrainAttemptAt(state.timeline, now) !== null) return 'offering';
    return 'idle';
  }

  // Normal trick behavior
  if (attemptAt(state.timeline, now) !== null) return 'offering';
  if (distractorActiveAt(state.timeline, now)) return 'distractor';
  return 'idle';
}
