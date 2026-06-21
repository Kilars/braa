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
    case "disengaged": {
      // The dog has walked off (engagement empty, task 107): it sits back-turned,
      // "done with you", until a call-back tap. The camera looks along +Z, so a
      // ~90° yaw turns the dog's RUMP toward the trainer (a true back-turn — a 180°
      // yaw would only show the other flank) AND narrows its on-screen footprint so
      // it can sit at the frame edge without clipping. The back-turn + seated crouch
      // + head-down are STATIC reads that survive reduced motion (D13 — dampened,
      // not removed); only the breathing/tail sway scales with `m`. The lateral edge
      // offset is applied in scene.ts.
      return {
        ...zero,
        bodyYaw: -Math.PI / 2,            // rump toward the trainer — shows its back
        crouchY: -0.34,                   // sat down low on its haunches
        headPitch: -0.25,                 // head dropped — dejected, not alert
        // Tail barely stirs — not soliciting attention (much calmer than idle's wag).
        tailWagAngle: wag * 0.12,
        // Slow, alive breathing so the dog never reads as frozen.
        breatheScaleY: 1 + Math.sin(now * 0.0025) * 0.02 * m,
      };
    }
    // ── Disengage beats (task 112) — the meter's escalation, read on the dog ──────
    // Graded so it stays funny, never punishing (spec §"Wrong-behavior beats"):
    //   itch  → fidgety ear-scratch    (mild "getting bored")
    //   flop  → bored lie-down forward (head down, giving up — NOT the back-turned
    //           walk-off, which is `disengaged`)
    //   bark  → head-up sass/protest   (the last beat before it walks off)
    // Static channels (headTiltZ / crouchY / headPitch) survive reduced motion; only the
    // oscillation scales with `m` (D13 — dampened, not removed).
    case "itch":
      return {
        ...zero,
        headTiltZ: 0.32,                              // head cocked toward the scratch (static read)
        // Quick rhythmic scratch wobble — faster than idle's calm sway.
        headLiftY: Math.abs(Math.sin(now * 0.03)) * 0.05 * m,
        bodyLeanX: Math.sin(now * 0.03) * 0.05 * m,
        tailWagAngle: wag * 0.4,                      // tail half-interested
      };
    case "flop":
      return {
        ...zero,
        crouchY: -0.40,                               // flopped low to the ground (static)
        headPitch: -0.30,                             // head resting down — bored (static)
        tailWagAngle: wag * 0.1,                      // tail almost still
        breatheScaleY: 1 + Math.sin(now * 0.0028) * 0.025 * m, // slow heavy breathing
      };
    case "bark":
      return {
        ...zero,
        headPitch: 0.5,                               // head up, barking at the trainer (static)
        headLiftY: 0.08,                              // chin lifted (static read)
        bounceY: Math.abs(Math.sin(now * 0.022)) * 0.09 * m, // sharp little bounces with each "woof"
        tailWagAngle: wag * 0.3,                       // stiff, not friendly
      };
    default:
      return { ...zero };
  }
}
