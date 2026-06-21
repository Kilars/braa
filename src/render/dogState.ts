import type { RoundState } from '../core/round';
import type { DisengageBeat } from '../core/engagement';
import { isConfused } from '../core/session';
import { attemptAt, distractorActiveAt, untrainAttemptAt } from '../core/scheduler';

export type DogVisual =
  | 'idle' | 'offering' | 'confused' | 'happy'
  | 'distractor' | 'misbehaving' | 'disengaged'
  // task 112 — the engagement meter's intermediate escalation, read off the dog.
  | 'itch' | 'flop' | 'bark';

/**
 * The "down-family" tricks: Ligg, Legg deg, and the play-dead Sov. Their markable
 * apex must read as a distinct lie-down on the imported dog, not the generic upright
 * sit shared with Sitt (D6/D11, task 120). One tested home for the rule so both the
 * pose path and the imported clip resolver agree.
 */
const DOWN_FAMILY_TRICKS: ReadonlySet<string> = new Set(['ligg', 'legg-deg', 'sov']);

/** True when the trick is a down-family lie-down (ligg / legg-deg / sov). */
export function isDownFamilyTrick(trickId: string | undefined): boolean {
  return trickId !== undefined && DOWN_FAMILY_TRICKS.has(trickId);
}

export interface DogVisualOpts {
  untrain?: boolean; // true = untraining mode (calm = offering, distractor = misbehaving)
  /**
   * true when the engagement meter has emptied (disengage beat === 'walk-off',
   * task 107): the dog has trotted off and sits back-turned at the frame edge,
   * "done with you", until a call-back tap re-engages it. Overrides offering/
   * distractor/idle/confused; a won round (mastered → happy) still wins.
   */
  disengaged?: boolean;
  /**
   * The current engagement beat (task 112). The intermediate beats — `itch` / `flop` /
   * `bark` — replace the plain `idle` state during lulls so the meter's graded
   * escalation reads on the dog itself, not only the HUD mood pill (spec §"Wrong-
   * behavior beats & disengagement"). `engaged` (or absent) leaves the dog idle; the
   * empty-meter `walk-off` is expressed via `disengaged` (task 107), so a beat never
   * masks an active correct `offering`, a `distractor`, `confused`, or a won round.
   */
  beat?: DisengageBeat;
  /** 0..1 proximity to the attempt apex (1 = at the markable peak). Drives on-dog apex pop. */
  peakProximity?: number;
  /** 0..1 tell intensity for this difficulty (1 = full cue, lower = fainter on harder modes). */
  tellStrength?: number;
  /** Active trick id — passed through to dogPose so the offering pose is trick-specific (D11). */
  trickId?: string;
}

/**
 * Pure mapping: RoundState + now → one of seven visual states.
 *
 * Normal trick precedence (highest first):
 *   mastered → 'happy'
 *   opts.disengaged (walk-off) → 'disengaged'   (task 107 — dog has left)
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
  // Walk-off dominates the in-play states: a dog that has left isn't offering,
  // confused, or distracted — it has disengaged until called back (task 107).
  if (opts?.disengaged) return 'disengaged';
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
  // Lull: surface the escalating off-task beat instead of plain idle (task 112), so the
  // meter's runup is visible on the dog before it walks off. itch/flop/bark only — the
  // empty-meter walk-off is the `disengaged` branch above; `engaged` stays idle.
  if (opts?.beat === 'bark') return 'bark';
  if (opts?.beat === 'flop') return 'flop';
  if (opts?.beat === 'itch') return 'itch';
  return 'idle';
}
