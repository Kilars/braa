import type { DogVisual } from "./dogState";

export interface DogPose {
  headTiltZ: number;
  headLiftY: number;
  tailWagAngle: number;
  bodyLeanX: number;
  bounceY: number;
  breatheScaleY: number;
  /** Y-offset applied to the dog's root/body to lower it toward the ground (sit/lie/settle). Negative = lower. */
  crouchY?: number;
  /** Body roll around the forward (Z) axis — for roll-over trick. */
  bodyRollZ?: number;
  /** Body yaw rotation (Y axis) — for spin trick. */
  bodyYaw?: number;
  /** Head pitch (X rotation) — positive = head up (howl), negative = head down (sleep). */
  headPitch?: number;
  /** Head yaw (Y rotation) — idle look-around only. */
  headYaw?: number;
}

const zero: DogPose = {
  headTiltZ: 0,
  headLiftY: 0,
  tailWagAngle: 0,
  bodyLeanX: 0,
  bounceY: 0,
  breatheScaleY: 1,
};

/** Pure mapping: trick id → base pose offsets for the offering state.
 *
 * Values are intentionally bold so each pose reads as the specific trick at a glance (D11):
 *   crouchY  — negative lowers the whole dog toward the ground (sit/lie/settle)
 *   bodyRollZ — rotates the root around the forward axis (roll-over lean)
 *   bodyYaw  — rotates the root around the up axis (spin/turn-in-place)
 *   headPitch — rotates the head pivot around the lateral axis (howl up / sleep down)
 *   bodyLeanX — forward lean on the body capsule
 */
function trickPose(trickId: string | undefined): Partial<Pick<DogPose, 'crouchY' | 'bodyRollZ' | 'bodyYaw' | 'headPitch' | 'bodyLeanX'>> {
  switch (trickId) {
    // Sitt — haunches down, head up alertly. crouchY lowers the rear.
    case 'sitt':     return { crouchY: -0.28, headPitch: 0.45, bodyLeanX: 0.06 };
    // Ligg — whole body lower than sitt, head level/forward.
    case 'ligg':     return { crouchY: -0.42, headPitch: 0.10 };
    // Legg deg — fullest settle, head resting down.
    case 'legg-deg': return { crouchY: -0.46, headPitch: -0.35 };
    // Rull — bold sideways lean (roll-over cue): prominent bodyRollZ + slight crouch.
    case 'rull':     return { crouchY: -0.14, bodyRollZ: 0.75 };
    // Snurr — prominent body yaw (spin cue): dog faces ~45° off-axis.
    case 'snurr':    return { bodyYaw: 0.90, headPitch: 0.10 };
    // Sov — play dead: body down, head sharply tucked.
    case 'sov':      return { crouchY: -0.36, headPitch: -0.55 };
    // Ul — howl: head raised prominently upward.
    case 'ul':       return { crouchY: -0.06, headPitch: 0.70 };
    // No-jump — calm settled: modest crouch, neutral head.
    case 'no-jump':  return { crouchY: -0.12, headPitch: 0.05 };
    default:         return {};
  }
}

/**
 * Ease the peakProximity value (0..1 triangle) through a quarter-sine curve
 * so the head lift accelerates smoothly into the crest and decelerates out.
 * peakProximity is already symmetric (rises 0→1 to the peak, falls 1→0 after),
 * so applying sin(prox * π/2) gives a gentle ease-in/ease-out around the apex.
 */
function smoothApex(prox: number): number {
  return Math.sin(prox * Math.PI / 2);
}

export function dogPose(
  visual: DogVisual,
  now: number,
  opts: { reducedMotion: boolean; peakProximity?: number; tellStrength?: number; trickId?: string },
): DogPose {
  const m = opts.reducedMotion ? 0.15 : 1;
  const wag = Math.sin(now * 0.012) * 0.5 * m;

  switch (visual) {
    case "idle": {
      // occasional slow look-around: mostly ~0, drifts out periodically (no RNG, pure)
      const env = Math.pow(Math.max(0, Math.sin(now * 0.00037)), 3); // long quiet gaps
      const headYaw = Math.sin(now * 0.0016) * 0.35 * env * m;       // calm bounded drift
      return {
        ...zero,
        breatheScaleY: 1 + Math.sin(now * 0.003) * 0.03 * m,
        tailWagAngle: wag,
        headYaw,
      };
    }
    case "offering": {
      const prox = opts.peakProximity ?? 0;
      const strength = opts.tellStrength ?? 1;
      const apexShape = smoothApex(prox) * strength;
      // reducedMotion: scale apex motion down but retain a floor (30% of full) so the cue is
      // still readable (D13 — dampened, not removed).
      const apexMotionScale = opts.reducedMotion ? 0.30 : 1;
      const apex = apexShape * apexMotionScale;
      // Trick-specific base pose (pure mapping, all channels optional/zero-default).
      // Layered UNDER the apex channel: apex still crests on top (D6 apex composes, not fights).
      const base = trickPose(opts.trickId);
      return {
        ...zero,
        ...base,
        headLiftY: 0.06 + apex * 0.10,        // head crests up at the apex (on top of trick base)
        bodyLeanX: (base.bodyLeanX ?? 0.05) + apex * 0.04,  // forward gather at apex on top of trick lean
        tailWagAngle: wag * 1.6,
      };
    }
    case "happy":
      return {
        ...zero,
        bounceY: Math.abs(Math.sin(now * 0.004)) * 0.18 * m + 0.02,
        tailWagAngle: wag * 2,
      };
    case "confused":
      return {
        ...zero,
        // Static tilt kept regardless of reducedMotion — pose must survive amplitude damping
        headTiltZ: 0.4,
        bodyLeanX: Math.sin(now * 0.03) * 0.08 * m,
      };
    case "misbehaving":
      return {
        ...zero,
        bounceY: Math.abs(Math.sin(now * 0.02)) * 0.45 * m,
        bodyLeanX: Math.sin(now * 0.014) * 0.12 * m,
      };
    case "distractor":
      return {
        ...zero,
        bodyLeanX: -0.18,
        headTiltZ: -0.2,
      };
    default:
      return { ...zero };
  }
}
