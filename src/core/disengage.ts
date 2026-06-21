import type { DisengageBeat } from './engagement';
import { CALL_BACK_ENGAGEMENT } from './tuning';

/**
 * Disengagement rules for the shipping (procedural) dog. Pure logic only — no
 * Babylon, no DOM. Spec §"Wrong-behavior beats & disengagement": at the empty
 * meter (`walk-off`) the dog trots to the frame edge and sits back-turned; you
 * can't earn until you **call it back** (a tap), which costs tempo/combo.
 *
 * This completes the 098 engagement remainder without any licensed-Labrador
 * clips: the walk-off + call-back are expressed procedurally on the placeholder
 * dog exactly like the existing turned-away `distractor` state.
 */

/** The dog has walked off (and won't earn) only at the empty-meter walk-off beat. */
export const isDisengaged = (beat: DisengageBeat): boolean => beat === 'walk-off';

/** A mark scores only while the dog is still in play — never once it has walked off. */
export const canScoreMark = (beat: DisengageBeat): boolean => beat !== 'walk-off';

/**
 * The engagement level a call-back tap restores the dog to. Chosen comfortably
 * above the walk-off threshold (and above the adjacent `bark` band) so a single
 * subsequent bad mark can't bounce the dog straight back off — the meter has
 * slack to absorb one mistake before disengaging again. Clamped to [0, 1].
 *
 * `disengageBeat(0.5)` → 'itch' (not walk-off, not bark), leaving two beats of
 * headroom before the dog would walk off once more.
 *
 * Homed in the central tuning module; re-exported here so existing `./disengage`
 * imports stay stable.
 */
export { CALL_BACK_ENGAGEMENT } from './tuning';

export function callBackEngagement(_prev: number): number {
  return Math.max(0, Math.min(1, CALL_BACK_ENGAGEMENT));
}
