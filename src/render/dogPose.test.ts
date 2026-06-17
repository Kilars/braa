import { describe, it, expect } from "vitest";
import { dogPose } from "./dogPose";

describe("dogPose", () => {
  // Slice 2: offering vs distractor — opposite lean directions
  describe("offering", () => {
    it("returns positive headLiftY (perks toward trainer)", () => {
      const pose = dogPose("offering", 0, { reducedMotion: false });
      expect(pose.headLiftY).toBeGreaterThan(0);
    });

    it("returns positive bodyLeanX (lean toward trainer)", () => {
      const pose = dogPose("offering", 0, { reducedMotion: false });
      expect(pose.bodyLeanX).toBeGreaterThan(0);
    });
  });

  describe("distractor", () => {
    it("returns negative bodyLeanX (lean away — opposite of offering)", () => {
      const pose = dogPose("distractor", 0, { reducedMotion: false });
      expect(pose.bodyLeanX).toBeLessThan(0);
    });
  });

  // Slice 3: confused — non-zero headTiltZ, retained under reducedMotion
  describe("confused", () => {
    it("returns non-zero headTiltZ (dog tilts head)", () => {
      const pose = dogPose("confused", 0, { reducedMotion: false });
      expect(pose.headTiltZ).not.toBe(0);
    });

    it("retains non-zero headTiltZ when reducedMotion is true (static pose preserved)", () => {
      const pose = dogPose("confused", 0, { reducedMotion: true });
      expect(pose.headTiltZ).not.toBe(0);
    });
  });

  // Slice 4: happy bounceY is larger than idle's
  describe("happy", () => {
    it("returns larger bounceY than idle at the same timestamp", () => {
      const now = 785; // arbitrary non-zero time
      const happy = dogPose("happy", now, { reducedMotion: false });
      const idle = dogPose("idle", now, { reducedMotion: false });
      expect(happy.bounceY).toBeGreaterThan(idle.bounceY);
    });
  });

  // Slice 5: misbehaving — distinct (higher peak) bounceY from happy
  describe("misbehaving", () => {
    it("peaks higher than happy at the same timestamp near misbehaving's peak", () => {
      // now ≈ π/(2×0.02) ≈ 78.5 puts misbehaving near its bounceY peak (~0.45)
      // while happy's bounceY at that moment is much lower (~0.073)
      const now = 78.5;
      const misbehaving = dogPose("misbehaving", now, { reducedMotion: false });
      const happy = dogPose("happy", now, { reducedMotion: false });
      expect(misbehaving.bounceY).toBeGreaterThan(happy.bounceY);
    });
  });

  // Slice 6: reducedMotion — dampened amplitude, distinct states still distinguishable
  describe("reducedMotion", () => {
    it("reduces idle tailWagAngle amplitude vs full motion (compare peaks across time)", () => {
      // Sample many timestamps to find the peak for each mode
      const times = Array.from({ length: 200 }, (_, i) => i * 50);
      const peakFull = Math.max(...times.map(t =>
        Math.abs(dogPose("idle", t, { reducedMotion: false }).tailWagAngle)
      ));
      const peakReduced = Math.max(...times.map(t =>
        Math.abs(dogPose("idle", t, { reducedMotion: true }).tailWagAngle)
      ));
      expect(peakReduced).toBeLessThan(peakFull);
    });

    it("keeps confused and idle poses distinguishable under reducedMotion (headTiltZ differs)", () => {
      const now = 0;
      const confused = dogPose("confused", now, { reducedMotion: true });
      const idle = dogPose("idle", now, { reducedMotion: true });
      // confused must still have a non-zero headTiltZ that idle lacks
      expect(confused.headTiltZ).not.toBe(idle.headTiltZ);
    });
  });

  // Slice 7: apex-pop — offering builds to a peak at peakProximity=1
  describe("apex-pop (offering)", () => {
    it("returns larger headLiftY at peakProximity=1 than at peakProximity=0 (pose crests at apex)", () => {
      const atApex = dogPose("offering", 0, { reducedMotion: false, peakProximity: 1, tellStrength: 1 });
      const atEdge = dogPose("offering", 0, { reducedMotion: false, peakProximity: 0, tellStrength: 1 });
      expect(atApex.headLiftY).toBeGreaterThan(atEdge.headLiftY);
    });

    it("apex magnitude scales with tellStrength — lower tellStrength gives smaller apex pop", () => {
      const fullStrength = dogPose("offering", 0, { reducedMotion: false, peakProximity: 1, tellStrength: 1 });
      const halfStrength = dogPose("offering", 0, { reducedMotion: false, peakProximity: 1, tellStrength: 0.5 });
      expect(fullStrength.headLiftY).toBeGreaterThan(halfStrength.headLiftY);
    });

    it("non-offering states (idle) ignore peakProximity — headLiftY unchanged", () => {
      const idleAtApex = dogPose("idle", 0, { reducedMotion: false, peakProximity: 1, tellStrength: 1 });
      const idleAtEdge = dogPose("idle", 0, { reducedMotion: false, peakProximity: 0, tellStrength: 1 });
      expect(idleAtApex.headLiftY).toBe(idleAtEdge.headLiftY);
    });

    it("reducedMotion reduces apex amplitude but keeps a non-zero cue at the peak (D13)", () => {
      const fullMotion = dogPose("offering", 0, { reducedMotion: false, peakProximity: 1, tellStrength: 1 });
      const reduced = dogPose("offering", 0, { reducedMotion: true, peakProximity: 1, tellStrength: 1 });
      const noApex = dogPose("offering", 0, { reducedMotion: false, peakProximity: 0, tellStrength: 1 });
      // Reduced must be smaller than full motion apex
      expect(reduced.headLiftY).toBeLessThan(fullMotion.headLiftY);
      // Reduced must still be larger than no apex (cue retained, not zeroed)
      expect(reduced.headLiftY).toBeGreaterThan(noApex.headLiftY);
    });
  });

  // Slice 8: per-trick offering poses (D11)
  describe("per-trick poses", () => {
    it("sitt and ligg have different crouchY (distinct poses)", () => {
      const sitt = dogPose("offering", 0, { reducedMotion: false, trickId: 'sitt' });
      const ligg = dogPose("offering", 0, { reducedMotion: false, trickId: 'ligg' });
      expect(sitt.crouchY).not.toBe(ligg.crouchY);
    });

    it("snurr has non-zero bodyYaw; rull has non-zero bodyRollZ; sitt/ligg have neither", () => {
      const snurr = dogPose("offering", 0, { reducedMotion: false, trickId: 'snurr' });
      const rull  = dogPose("offering", 0, { reducedMotion: false, trickId: 'rull' });
      const sitt  = dogPose("offering", 0, { reducedMotion: false, trickId: 'sitt' });
      const ligg  = dogPose("offering", 0, { reducedMotion: false, trickId: 'ligg' });
      expect(snurr.bodyYaw).toBeGreaterThan(0);
      expect(rull.bodyRollZ).toBeGreaterThan(0);
      expect(sitt.bodyYaw ?? 0).toBe(0);
      expect(sitt.bodyRollZ ?? 0).toBe(0);
      expect(ligg.bodyYaw ?? 0).toBe(0);
      expect(ligg.bodyRollZ ?? 0).toBe(0);
    });

    it("ul raises headPitch (howl) and sov lowers it (sleep)", () => {
      const ul  = dogPose("offering", 0, { reducedMotion: false, trickId: 'ul' });
      const sov = dogPose("offering", 0, { reducedMotion: false, trickId: 'sov' });
      expect((ul.headPitch  ?? 0)).toBeGreaterThan(0);
      expect((sov.headPitch ?? 0)).toBeLessThan(0);
    });

    it("unknown trickId falls back to generic pose — no throw, no rotation channels", () => {
      // Should not throw; should return a valid pose with no trick-specific rotations
      expect(() => dogPose("offering", 0, { reducedMotion: false, trickId: 'totally-unknown' })).not.toThrow();
      const pose = dogPose("offering", 0, { reducedMotion: false, trickId: 'totally-unknown' });
      expect(pose.crouchY  ?? 0).toBe(0);
      expect(pose.bodyRollZ ?? 0).toBe(0);
      expect(pose.bodyYaw   ?? 0).toBe(0);
    });

    it("undefined trickId falls back to generic pose — same as no trickId", () => {
      const withUndefined = dogPose("offering", 0, { reducedMotion: false, trickId: undefined });
      const withoutTrickId = dogPose("offering", 0, { reducedMotion: false });
      expect(withUndefined.crouchY  ?? 0).toBe(withoutTrickId.crouchY  ?? 0);
      expect(withUndefined.bodyYaw  ?? 0).toBe(withoutTrickId.bodyYaw  ?? 0);
      expect(withUndefined.bodyRollZ ?? 0).toBe(withoutTrickId.bodyRollZ ?? 0);
    });

    it("reducedMotion retains static trick pose offset — sitt crouchY non-zero under reduced motion (D13)", () => {
      const reduced = dogPose("offering", 0, { reducedMotion: true, trickId: 'sitt' });
      // The static pose (crouchY) must still read as a sit — not zeroed by reducedMotion
      expect((reduced.crouchY ?? 0)).not.toBe(0);
    });

    it("reducedMotion retains snurr bodyYaw (static rotation still readable) (D13)", () => {
      const reduced = dogPose("offering", 0, { reducedMotion: true, trickId: 'snurr' });
      expect((reduced.bodyYaw ?? 0)).not.toBe(0);
    });

    it("trickId only affects offering — idle/confused/happy/distractor ignore trickId", () => {
      // All non-offering states should return zero trick-specific channels regardless of trickId
      const states = ['idle', 'confused', 'happy', 'distractor', 'misbehaving'] as const;
      for (const visual of states) {
        const pose = dogPose(visual, 0, { reducedMotion: false, trickId: 'snurr' });
        expect(pose.bodyYaw   ?? 0).toBe(0);
        expect(pose.bodyRollZ ?? 0).toBe(0);
        expect(pose.crouchY   ?? 0).toBe(0);
      }
    });
  });

  // Slice 1: idle — time-varying breatheScaleY + non-zero tailWagAngle
  describe("idle", () => {
    it("returns different breatheScaleY at different timestamps (never frozen)", () => {
      const a = dogPose("idle", 0, { reducedMotion: false });
      const b = dogPose("idle", 1000, { reducedMotion: false });
      expect(a.breatheScaleY).not.toBe(b.breatheScaleY);
    });

    it("returns non-zero tailWagAngle", () => {
      const pose = dogPose("idle", 500, { reducedMotion: false });
      expect(pose.tailWagAngle).not.toBe(0);
    });
  });

  // Slice 9: idle look-around — occasional headYaw (not constant, calm-bounded, reducedMotion dampened, no leak)
  describe("idle look-around", () => {
    it("idle headYaw is occasionally non-zero and sometimes near-zero (occasional, not constant)", () => {
      // Sample a wide range of timestamps to capture the periodic nature of the look-around
      const times = Array.from({ length: 160 }, (_, i) => i * 250); // 0, 250, 500, ..., 39750
      const headYaws = times.map(t => Math.abs(dogPose("idle", t, { reducedMotion: false }).headYaw ?? 0));

      // Maximum absolute headYaw should be clearly non-zero (motion is present)
      const maxYaw = Math.max(...headYaws);
      expect(maxYaw).toBeGreaterThan(0.1);

      // At least one sample should be near-zero (proving it's occasional, not constant)
      const nearZeroCount = headYaws.filter(yaw => yaw < 0.02).length;
      expect(nearZeroCount).toBeGreaterThan(0);
    });

    it("idle headYaw stays within calm bounds (|headYaw| ≤ 0.6)", () => {
      // Sample across a wide range to check all possible values
      const times = Array.from({ length: 160 }, (_, i) => i * 250); // 0, 250, 500, ..., 39750
      const headYaws = times.map(t => dogPose("idle", t, { reducedMotion: false }).headYaw ?? 0);

      headYaws.forEach(yaw => {
        expect(Math.abs(yaw)).toBeLessThanOrEqual(0.6);
      });
    });

    it("reducedMotion dampens idle headYaw peak vs full motion (compare maxima)", () => {
      // Sample many timestamps to find the peak for each mode
      const times = Array.from({ length: 160 }, (_, i) => i * 250); // 0, 250, 500, ..., 39750

      const peakFull = Math.max(...times.map(t =>
        Math.abs(dogPose("idle", t, { reducedMotion: false }).headYaw ?? 0)
      ));
      const peakReduced = Math.max(...times.map(t =>
        Math.abs(dogPose("idle", t, { reducedMotion: true }).headYaw ?? 0)
      ));

      // Peak under reducedMotion must be less than full motion
      expect(peakReduced).toBeLessThan(peakFull);
    });

    it("idle under reducedMotion is not frozen (breatheScaleY still varies, staying alive)", () => {
      // Verify breatheScaleY varies at different timestamps under reducedMotion
      const a = dogPose("idle", 0, { reducedMotion: true });
      const b = dogPose("idle", 1000, { reducedMotion: true });

      // breatheScaleY must differ between these two timestamps
      expect(a.breatheScaleY).not.toBe(b.breatheScaleY);
    });

    it("non-idle states (offering, confused, happy, distractor, misbehaving) have headYaw exactly 0", () => {
      const states = ['offering', 'confused', 'happy', 'distractor', 'misbehaving'] as const;
      const sampleTimes = [0, 500, 5000, 15000];

      for (const visual of states) {
        for (const now of sampleTimes) {
          const headYaw = dogPose(visual, now, { reducedMotion: false }).headYaw ?? 0;
          expect(headYaw).toBe(0);
        }
      }
    });
  });
});
