/**
 * dogAnimationMap.ts — PURE state → embedded-clip resolution for the imported
 * Labrador (task 080). No Babylon import: this is the test-first logic that
 * decides WHICH AnimationGroup plays for a given visual state and how reduced
 * motion damps it. The actual AnimationGroup.play()/blend glue lives in
 * importedDogMesh.ts and is covered by Visual Review.
 */

import { isDownFamilyTrick, type DogVisual } from './dogState';

/** Strip any `armature|` prefix and lowercase, so `Arm_Labrador|Idle_1` → `idle_1`. */
function clipKey(name: string): string {
  const bar = name.lastIndexOf('|');
  return (bar >= 0 ? name.slice(bar + 1) : name).toLowerCase();
}

/**
 * Resolve the best embedded clip name for a visual state, or `null` when no
 * suitable clip exists (caller then keeps the procedural pose).
 *
 * Matches each preference (in priority order) first by exact key, then by
 * key-prefix family (e.g. `sitting` → `sitting_loop_1`), comparing past any
 * `armature|` prefix and case-insensitively. Returns the clip's full original
 * name so the caller can look the AnimationGroup up directly.
 */
export function resolveStateClip(
  state: DogVisual,
  clips: readonly string[],
  opts?: { trickId?: string },
): string | null {
  // Down-family tricks (Ligg / Legg deg / Sov) must read as a distinct lie-down at
  // the offering apex, not the generic upright sit shared with Sitt (D6/D11, task
  // 120). Prefer a Lie/Lying clip first, then fall through to the normal offering
  // preference so a rig without a lie clip degrades to Sitting (the procedural
  // deep-crouch still carries the "down" read). Opt-in: every other state/trick is
  // unchanged.
  const prefs =
    state === 'offering' && isDownFamilyTrick(opts?.trickId)
      ? ['Lie', 'Lying', ...STATE_CLIP_PREFERENCES.offering]
      : STATE_CLIP_PREFERENCES[state] ?? [];
  for (const pref of prefs) {
    const p = pref.toLowerCase();
    const exact = clips.find((c) => clipKey(c) === p);
    if (exact) return exact;
    const family = clips.find((c) => clipKey(c).startsWith(p));
    if (family) return family;
  }
  return null;
}

/**
 * Speed-ratio applied to a playing clip. `prefers-reduced-motion` slows the clip
 * to a calmer pace rather than freezing it (D13: dampen, not remove). Baked clips
 * can't have their amplitude reduced like the procedural channels, so we damp the
 * playback rate — the dog still moves, just gently.
 */
export function clipMotionScale(reducedMotion: boolean): number {
  return reducedMotion ? REDUCED_MOTION_CLIP_SCALE : 1;
}

/** Reduced-motion clip playback rate — calm but still moving (D13). */
const REDUCED_MOTION_CLIP_SCALE = 0.5;

/**
 * Whether a state's clip should loop. Every core visual state here is a
 * *sustained* condition (idle, offering/holding the behaviour, confused,
 * sustained-happy/mastery, distracted, misbehaving), so all loop. Transient
 * "pop" feedback on a successful mark stays a procedural additive pulse in
 * scene.ts, layered over the looping clip.
 */
export function clipLoops(_state: DogVisual): boolean {
  return true;
}

// Ordered clip-name preferences per visual state (first match wins).
const STATE_CLIP_PREFERENCES: Record<DogVisual, readonly string[]> = {
  // Idle_2 first: on the licensed Labrador rig, Idle_1 is a SEATED idle (visually
  // identical to the seated `offering`), while Idle_2 is the STANDING calm idle —
  // so idle (standing) reads as clearly distinct from offering (sitting). Discovered
  // via task 080 Visual Review. Falls back to Idle_1, then any Idle-family clip.
  idle: ['Idle_2', 'Idle_1', 'Idle'],
  offering: ['Sitting_loop_1', 'Sitting'],
  confused: ['Scratching'],
  happy: ['Bark'],
  distractor: ['Digging_loop', 'Digging'],
  misbehaving: ['Digging_loop', 'Bark'],
  // Disengaged (walk-off, task 107): the dog has sat down, "done with you". A seated
  // idle reads as settled/withdrawn; the back-turn is applied via yaw, not the clip,
  // so this mirrors the procedural seated pose. Falls back to a lie/idle clip.
  disengaged: ['Sitting_loop_1', 'Sitting', 'Lie', 'Idle_1'],
  // Disengage beats (task 112): the meter's escalation. On the imported rig these map
  // to literal clips — itch=ear-scratch, flop=lie-down (bored), bark=protest bark — so
  // the same escalation reads on either dog. Each falls back to an Idle clip if absent.
  itch: ['Scratching', 'Idle_2', 'Idle'],
  flop: ['Lie', 'Lying', 'Idle_2', 'Idle'],
  bark: ['Bark', 'Idle_2', 'Idle'],
};
