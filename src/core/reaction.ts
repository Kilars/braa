/**
 * The mark-reaction envelope (spec P1-6 / D8): the pure time-shape of the dog's
 * happy perk-up after a successful BRA. Kept pure so the *timing* is unit-tested
 * here while the mesh application (a grounded hop + a livelier tail wag) stays a
 * thin visual layer in `src/render/dog.ts`.
 *
 * `reactionAt` returns normalized amplitudes in [0,1]: `bounce` (a quick hop
 * that eases back to rest) and `wag` (how hard the tail wags on top of its idle
 * sway). `strength` scales the peak so PERFECT reads bigger than OK; outside the
 * reaction window — or with no reaction active — everything is at rest (0), so
 * the dog sits still until the next mark.
 */

/** Total duration of one reaction, in ms (quick attack, gentle ease-back). */
export const REACTION_MS = 650

/** Fraction of the window spent rising to the peak before easing back down. */
const ATTACK = 0.14

/**
 * The grounded squash-and-settle ("pop", spec P1-6 / PO Review I1) is snappier
 * than the head/tail envelope: a fast rise then a settle back to rest *before*
 * the wag finishes, so a successful mark reads as a quick, unmistakable puff of
 * joy rather than a slow swell — while the dog never leaves the ground (D12).
 */
const POP_ATTACK = 0.1
const POP_SETTLE = 0.45 // settles at p = POP_ATTACK + POP_SETTLE = 0.55 (< 1)

/**
 * Offset from a reaction's start to its peak amplitude, in ms. Lets a frozen
 * Visual-Review capture place the clock exactly on the perk-up's apex.
 */
export const REACTION_PEAK_MS = ATTACK * REACTION_MS

export interface ReactionState {
  /** Vertical hop amplitude, 0..1 (scaled by strength). */
  bounce: number
  /** Tail-wag intensity, 0..1, on top of the idle sway. */
  wag: number
  /**
   * Grounded squash-and-settle amplitude, 0..1 (scaled by strength). Carries the
   * unmistakable, still-grounded celebration: the body puffs proud and settles,
   * never lifting the paws off the contact shadow (D12). PERFECT pops distinctly
   * harder than OK.
   */
  pop: number
}

const REST: ReactionState = { bounce: 0, wag: 0, pop: 0 }

function clamp01(n: number): number {
  return Math.max(0, Math.min(1, n))
}

/**
 * The reaction amplitudes at `now` for a reaction begun at `startTime` (or
 * `null` for none). `strength` in [0,1] sets the peak (PERFECT 1 > OK ~0.55).
 */
export function reactionAt(
  startTime: number | null,
  now: number,
  strength: number,
): ReactionState {
  if (startTime === null) return { ...REST }
  const t = now - startTime
  if (t < 0 || t >= REACTION_MS) return { ...REST }

  const p = t / REACTION_MS
  // Quick rise to the peak, then a smooth ease back to rest at the window's end.
  const env = p < ATTACK ? p / ATTACK : 1 - (p - ATTACK) / (1 - ATTACK)
  // Pop: a snappier rise + settle to rest before the wag finishes (grounded).
  const popEnv =
    p < POP_ATTACK ? p / POP_ATTACK : Math.max(0, 1 - (p - POP_ATTACK) / POP_SETTLE)
  const s = clamp01(strength)
  return { bounce: clamp01(s * env), wag: clamp01(env), pop: clamp01(s * popEnv) }
}
