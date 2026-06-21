import { RoundState } from '../core/round';
import { isConfused } from '../core/session';
import { Profile, newProfile } from '../core/economy';
import { attemptAt } from '../core/scheduler';
import { disengageBeat, type DisengageBeat } from '../core/engagement';
import { isDisengaged } from '../core/disengage';

export interface HudViewModel {
  learnedPercent: number;
  mastered: boolean;
  lastResult: string | null;
  confused: boolean;
  coins: number;
  level: number;
  attemptActive: boolean;
  tellStrength: number;
  /** 0..1: how close `now` is to the attempt peak (1 = at the peak). Same source as tellStrength. */
  peakProximity: number;
  combo: number;
  /** 0..1 engagement meter (1 = eager). Drives the HUD mood meter + the disengage beat. */
  engagement: number;
  /** The escalating off-task beat the meter warrants (engaged → … → walk-off). */
  engagementBeat: DisengageBeat;
  /** true at walk-off: the dog has trotted off; a tap calls it back (task 107). */
  disengaged: boolean;
}

function clamp01(x: number): number {
  return x < 0 ? 0 : x > 1 ? 1 : x;
}

export function toViewModel(
  state: RoundState,
  now: number,
  profile: Profile = newProfile(),
  tellIntensity = 1,
  combo = 0,
  engagementLevel = 1,
): HudViewModel {
  const attempt = attemptAt(state.timeline, now);
  let attemptActive = false;
  let tellStrength = 0;
  let peakProximity = 0;

  if (attempt !== null) {
    attemptActive = true;
    const halfSpan = (attempt.end - attempt.start) / 2;
    // peakProximity: 1 at the apex, 0 at the window edges — same geometry as tellStrength
    // but without the tellIntensity scale (the dog's apex shape is driven by peakProximity;
    // its amplitude is then scaled by tellStrength so difficulty makes the cue fainter).
    peakProximity = 1 - clamp01(Math.abs(now - attempt.peak) / halfSpan);
    tellStrength = peakProximity * tellIntensity;
  }

  const beat = disengageBeat(engagementLevel);
  const disengaged = isDisengaged(beat);
  // A walked-off dog earns nothing from a mark, so the "mark now" apex cue must be
  // fully suppressed — otherwise the gold ring (tellStrength) and the on-dog apex
  // crest (peakProximity) contradict the call-back affordance, which is the only
  // valid action while disengaged (PO Review 2026-06-21 #4).
  if (disengaged) {
    tellStrength = 0;
    peakProximity = 0;
  }

  return {
    learnedPercent: state.session.learned,
    mastered: state.session.mastered,
    lastResult: state.lastResult,
    confused: isConfused(state.session, now),
    coins: profile.coins,
    level: profile.level,
    attemptActive,
    tellStrength,
    peakProximity,
    combo,
    engagement: engagementLevel,
    engagementBeat: beat,
    disengaged,
  };
}
