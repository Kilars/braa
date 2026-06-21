/**
 * TDD tests for dogAnimationMap.ts — the PURE state → clip resolver and the
 * reduced-motion damping factor for the imported Labrador's skeletal clips
 * (task 080). No Babylon import: the actual AnimationGroup.play() glue is render
 * glue, covered by Visual Review.
 *
 * Clip names in the real rig are prefixed with the armature, e.g.
 * `Arm_Labrador|Idle_1`, `Arm_Labrador|Sitting_loop_1`. The resolver must match
 * by the clip's own name (after any `armature|` prefix), case-insensitively, so
 * it works across the CC0 placeholder rig and the licensed Labrador alike.
 */

import { describe, it, expect } from 'vitest';
import { resolveStateClip, clipMotionScale, clipLoops } from './dogAnimationMap';

// Real Labrador clip subset (full armature-prefixed names from out_anim.glb).
const LAB_CLIPS = [
  'Arm_Labrador|Idle_1',
  'Arm_Labrador|Idle_2',
  'Arm_Labrador|Idle_6',
  'Arm_Labrador|Sitting_loop_1',
  'Arm_Labrador|Sitting_start',
  'Arm_Labrador|Scratching',
  'Arm_Labrador|Bark',
  'Arm_Labrador|Digging_loop',
] as const;

describe('resolveStateClip — idle', () => {
  it('prefers the STANDING idle (Idle_2) over the seated Idle_1', () => {
    // On the licensed Labrador rig Idle_1 is a SEATED idle — visually identical to
    // the seated `offering`. Idle_2 is the standing calm idle, so idle reads as
    // clearly distinct from offering. (task 080 Visual Review finding.)
    expect(resolveStateClip('idle', LAB_CLIPS)).toBe('Arm_Labrador|Idle_2');
  });

  it('falls back to the seated Idle_1 when no standing Idle_2 exists', () => {
    const clips = ['Arm_Labrador|Idle_1', 'Arm_Labrador|Bark'];
    expect(resolveStateClip('idle', clips)).toBe('Arm_Labrador|Idle_1');
  });
});

describe('resolveStateClip — disengage beats (task 112)', () => {
  it('itch → the ear-scratch clip', () => {
    expect(resolveStateClip('itch', LAB_CLIPS)).toBe('Arm_Labrador|Scratching');
  });

  it('bark → the protest Bark clip', () => {
    expect(resolveStateClip('bark', LAB_CLIPS)).toBe('Arm_Labrador|Bark');
  });

  it('flop → a Lie clip when present (bored lie-down)', () => {
    const clips = [...LAB_CLIPS, 'Arm_Labrador|Lie_loop'];
    expect(resolveStateClip('flop', clips)).toBe('Arm_Labrador|Lie_loop');
  });

  it('flop → falls back to a standing Idle when no Lie clip exists', () => {
    // LAB_CLIPS has no Lie/Lying clip → second preference (Idle_2) wins.
    expect(resolveStateClip('flop', LAB_CLIPS)).toBe('Arm_Labrador|Idle_2');
  });
});

describe('resolveStateClip — distinct clip per state', () => {
  it('offering → the attentive Sitting loop', () => {
    expect(resolveStateClip('offering', LAB_CLIPS)).toBe('Arm_Labrador|Sitting_loop_1');
  });

  it('confused → Scratching', () => {
    expect(resolveStateClip('confused', LAB_CLIPS)).toBe('Arm_Labrador|Scratching');
  });

  it('happy → Bark', () => {
    expect(resolveStateClip('happy', LAB_CLIPS)).toBe('Arm_Labrador|Bark');
  });

  it('core states resolve to mutually distinct clips (tellable apart)', () => {
    const states = ['idle', 'offering', 'confused', 'happy'] as const;
    const resolved = states.map((s) => resolveStateClip(s, LAB_CLIPS));
    expect(new Set(resolved).size).toBe(states.length);
  });
});

describe('resolveStateClip — trick-aware down-family offering (task 120)', () => {
  // Sitt, Ligg and Legg deg all map `offering` → Sitting on a trick-blind resolver,
  // so three different commands look identical on the imported dog. For the down
  // family the apex must read as a distinct lie-down (D6/D11). The lie clip lives
  // alongside the sitting clips on the rig (the `flop` beat already references it).
  const CLIPS_WITH_LIE = [...LAB_CLIPS, 'Arm_Labrador|Lie_loop'] as const;

  it('offering + a down-family trick prefers the Lie clip', () => {
    expect(resolveStateClip('offering', CLIPS_WITH_LIE, { trickId: 'ligg' }))
      .toBe('Arm_Labrador|Lie_loop');
    expect(resolveStateClip('offering', CLIPS_WITH_LIE, { trickId: 'legg-deg' }))
      .toBe('Arm_Labrador|Lie_loop');
    expect(resolveStateClip('offering', CLIPS_WITH_LIE, { trickId: 'sov' }))
      .toBe('Arm_Labrador|Lie_loop');
  });

  it('offering + Sitt still resolves to the Sitting loop (down rule is opt-in)', () => {
    expect(resolveStateClip('offering', CLIPS_WITH_LIE, { trickId: 'sitt' }))
      .toBe('Arm_Labrador|Sitting_loop_1');
  });

  it('offering with no trickId still resolves to the Sitting loop (regression)', () => {
    expect(resolveStateClip('offering', CLIPS_WITH_LIE)).toBe('Arm_Labrador|Sitting_loop_1');
  });

  it('down-family but no Lie clip present → falls back to Sitting (graceful degrade)', () => {
    // LAB_CLIPS has no Lie/Lying clip; the procedural deep-crouch still tilts the dog
    // down, but the resolver must not crash or return null — it falls through to the
    // normal offering preference (the sitting clip).
    expect(resolveStateClip('offering', LAB_CLIPS, { trickId: 'ligg' }))
      .toBe('Arm_Labrador|Sitting_loop_1');
  });

  it('the down-family rule only applies to offering, not other states', () => {
    // A down-family trick must not redirect e.g. `happy` away from Bark.
    expect(resolveStateClip('happy', CLIPS_WITH_LIE, { trickId: 'ligg' }))
      .toBe('Arm_Labrador|Bark');
  });
});

describe('resolveStateClip — family fallback', () => {
  it('falls back to the next preference when the first is absent (idle → Idle_6)', () => {
    // No Idle_1; only Idle_6 present → matches the `Idle` family preference.
    const clips = ['Arm_Labrador|Idle_6', 'Arm_Labrador|Bark'];
    expect(resolveStateClip('idle', clips)).toBe('Arm_Labrador|Idle_6');
  });

  it('matches a key-prefix family (offering → Sitting_start when no loop)', () => {
    const clips = ['Arm_Labrador|Sitting_start', 'Arm_Labrador|Bark'];
    expect(resolveStateClip('offering', clips)).toBe('Arm_Labrador|Sitting_start');
  });

  it('does not mistake Crouch_Idle for an Idle-family match', () => {
    // `crouch_idle_loop_1` starts with `crouch`, not `idle` → no false idle hit.
    expect(resolveStateClip('idle', ['Arm_Labrador|Crouch_Idle_loop_1'])).toBeNull();
  });
});

describe('resolveStateClip — missing clip → null (keep procedural pose)', () => {
  it('returns null when no preferred clip is present', () => {
    expect(resolveStateClip('happy', ['Arm_Labrador|Walk_F_IP'])).toBeNull();
  });

  it('returns null for an empty clip list without throwing', () => {
    expect(resolveStateClip('idle', [])).toBeNull();
  });

  it('matches unprefixed names too (CC0 rig without an armature prefix)', () => {
    expect(resolveStateClip('idle', ['Idle_1', 'Bark'])).toBe('Idle_1');
  });
});

describe('clipMotionScale — reduced-motion damping (D13: dampen, not remove)', () => {
  it('plays at full speed (1) under normal motion', () => {
    expect(clipMotionScale(false)).toBe(1);
  });

  it('dampens but never removes motion under prefers-reduced-motion', () => {
    const scale = clipMotionScale(true);
    expect(scale).toBeGreaterThan(0); // not removed — D13
    expect(scale).toBeLessThan(1); // dampened
  });
});

describe('clipLoops — looping vs one-shot per state', () => {
  it('loops sustained states (idle, offering)', () => {
    expect(clipLoops('idle')).toBe(true);
    expect(clipLoops('offering')).toBe(true);
  });

  it('loops the sustained happy/mastery state', () => {
    expect(clipLoops('happy')).toBe(true);
  });
});
