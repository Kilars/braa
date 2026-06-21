/**
 * TDD tests for the pure mapping helpers in importedDogMesh.ts.
 *
 * These helpers are pure functions (no Babylon scene, no DOM) so they can be
 * unit-tested cleanly. The mesh/material/Babylon wiring is render glue and is
 * covered by Visual Review (task 079) instead.
 *
 * Red → green order:
 *   1. fitTransform — bounds → (scale, offset) for framing the imported dog
 *   2. findBone     — case-insensitive bone-name search helper
 */

import { describe, it, expect } from 'vitest';
import { fitTransform, findBone, headBoneY } from './importedDogMesh';

// ---------------------------------------------------------------------------
// fitTransform — bounds → { scale, offset }
// ---------------------------------------------------------------------------
describe('fitTransform', () => {
  /**
   * Contract:
   *   - `scale` uniformly scales the model so its bounding height equals targetHeight.
   *   - `offset.y` re-centres the model so the foot (min.y) maps to -targetHeight/2
   *     in scaled space (i.e. feet sit at the same world-y fraction as the procedural
   *     dog — root-local y ≈ -targetHeight/2).
   *   - `offset.x` and `offset.z` re-centre the model horizontally to 0.
   */

  it('2-unit-tall bbox at targetHeight 1.2 → scale 0.6', () => {
    const { scale } = fitTransform(
      { x: -0.5, y: 0, z: -0.5 },
      { x:  0.5, y: 2, z:  0.5 },
      1.2,
    );
    expect(scale).toBeCloseTo(0.6, 5);
  });

  it('offsets x/z to centre the model at 0 when asymmetric', () => {
    // bbox shifted +1 in x — centroid is at x=1.5, so offset.x should be -1.5
    const { offset } = fitTransform(
      { x: 1, y: 0, z: -0.5 },
      { x: 2, y: 2, z:  0.5 },
      1.2,
    );
    expect(offset.x).toBeCloseTo(-1.5, 5);
    expect(offset.z).toBeCloseTo(0, 5);
  });

  it('offset.y places scaled-feet at -targetHeight/2 (feet at root-local -0.6 for targetHeight 1.2)', () => {
    // A 2-unit model with min.y = 0 (feet at 0) and targetHeight 1.2 → scale 0.6.
    // Scaled foot = 0 * 0.6 = 0. We want scaled foot at -0.6 (= -targetHeight/2).
    // Required y-offset in model space = -targetHeight/2 / scale = -0.6/0.6 = -1.0
    // But the offset is applied BEFORE scaling. The scaled result of (min.y + offset.y) * scale
    // should equal -targetHeight/2.
    // (0 + offset.y) * 0.6 = -0.6  →  offset.y = -1.0
    const { offset } = fitTransform(
      { x: 0, y: 0, z: 0 },
      { x: 1, y: 2, z: 1 },
      1.2,
    );
    // After applying: (min.y + offset.y) * scale = -targetHeight/2
    // (0 + offset.y) * 0.6 = -0.6
    expect(offset.y * 0.6).toBeCloseTo(-0.6, 5);
  });

  it('1-unit-tall bbox (already tiny) → scale 1.2', () => {
    const { scale } = fitTransform(
      { x: 0, y: 0, z: 0 },
      { x: 1, y: 1, z: 1 },
      1.2,
    );
    expect(scale).toBeCloseTo(1.2, 5);
  });

  it('symmetric bbox → offset.x and offset.z both 0', () => {
    const { offset } = fitTransform(
      { x: -1, y: -0.5, z: -1 },
      { x:  1, y:  1.5, z:  1 },
      1.2,
    );
    expect(offset.x).toBeCloseTo(0, 5);
    expect(offset.z).toBeCloseTo(0, 5);
  });
});

// ---------------------------------------------------------------------------
// findBone — case-insensitive bone-name substring search
// ---------------------------------------------------------------------------
describe('findBone', () => {
  const makeBone = (name: string) => ({ name }) as { name: string };

  it('finds a bone by case-insensitive substring match ("Tail01" matches "tail")', () => {
    const bones = [makeBone('Spine'), makeBone('Tail01'), makeBone('Head')];
    const result = findBone(bones, 'tail');
    expect(result).not.toBeNull();
    expect(result?.name).toBe('Tail01');
  });

  it('returns null when no bone matches', () => {
    const bones = [makeBone('Spine'), makeBone('Hip')];
    const result = findBone(bones, 'tail');
    expect(result).toBeNull();
  });

  it('matches regardless of case in the bone list name ("HEAD" matches "head")', () => {
    const bones = [makeBone('HEAD'), makeBone('Spine')];
    const result = findBone(bones, 'head');
    expect(result).not.toBeNull();
    expect(result?.name).toBe('HEAD');
  });

  it('matches case-insensitive keyword ("Neck" found by "neck")', () => {
    const bones = [makeBone('Bip001 Neck'), makeBone('Bip001 Spine')];
    const result = findBone(bones, 'neck');
    expect(result).not.toBeNull();
    expect(result?.name).toBe('Bip001 Neck');
  });

  it('returns first match when multiple bones match', () => {
    const bones = [makeBone('Tail_Root'), makeBone('Tail_Tip')];
    const result = findBone(bones, 'tail');
    expect(result?.name).toBe('Tail_Root');
  });

  it('returns null for empty bone list', () => {
    expect(findBone([], 'head')).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// headBoneY — bind-relative head-lift offset (no per-frame accumulation)
// ---------------------------------------------------------------------------
describe('headBoneY', () => {
  /**
   * Contract: the head bone's Y is always the captured bind-pose Y plus the
   * pose's headLiftY — a pure SET, never an accumulating +=. This guards the
   * drift bug where `headBone.position.y += pose.headLiftY` added the lift onto
   * the previous frame's value every frame, walking the head upward unboundedly.
   */

  it('returns the bind Y unchanged when there is no lift', () => {
    expect(headBoneY(0.28, 0)).toBeCloseTo(0.28, 5);
  });

  it('returns bindY + lift (bind-relative, not cumulative)', () => {
    expect(headBoneY(0.28, 0.1)).toBeCloseTo(0.38, 5);
  });

  it('is idempotent across frames — same inputs give the same Y (no drift)', () => {
    const frame1 = headBoneY(0.28, 0.1);
    const frame2 = headBoneY(0.28, 0.1);
    const frame3 = headBoneY(0.28, 0.1);
    expect(frame1).toBeCloseTo(0.38, 5);
    expect(frame2).toBe(frame1);
    expect(frame3).toBe(frame1);
  });
});
