import { describe, it, expect } from 'vitest';
import { masteryFlourish } from './masteryFlourish';
import { dogPose } from './dogPose';

describe('masteryFlourish', () => {
  // Slice 1: Peak at masteredAt, 0 past window
  it('returns peak (leapY > 0, spinYaw > 0) at now===masteredAt and 0 well past the window', () => {
    const masteredAt = 1000;
    const atMastery = masteryFlourish(masteredAt, masteredAt, { reducedMotion: false });
    expect(atMastery.leapY).toBeGreaterThan(0);
    expect(atMastery.spinYaw).toBeGreaterThan(0);
    expect(atMastery.wagBoost).toBeGreaterThan(0);

    const wellPast = masteryFlourish(masteredAt + 2000, masteredAt, { reducedMotion: false });
    expect(wellPast.leapY).toBe(0);
    expect(wellPast.spinYaw).toBe(0);
    expect(wellPast.wagBoost).toBe(0);
  });

  // Slice 2: Bigger than a normal happy bounce
  it('peak leapY exceeds the maximum happy bounce amplitude (bigger on mastery)', () => {
    const masteredAt = 1000;
    const flourish = masteryFlourish(masteredAt, masteredAt, { reducedMotion: false });

    // Compute the peak happy bounce by sampling dogPose across many timepoints
    // happy bounceY = Math.abs(Math.sin(now * 0.004)) * 0.18 * m + 0.02
    // where m = 1 for reducedMotion: false
    // Maximum is 0.18 + 0.02 = 0.20
    let maxHappyBounce = 0;
    for (let t = 0; t < 2000; t += 10) {
      const pose = dogPose('happy', t, { reducedMotion: false });
      maxHappyBounce = Math.max(maxHappyBounce, pose.bounceY);
    }

    expect(flourish.leapY).toBeGreaterThan(maxHappyBounce);
  });

  // Slice 3: null masteredAt → all 0
  it('returns all 0 when masteredAt is null', () => {
    const result = masteryFlourish(5000, null, { reducedMotion: false });
    expect(result.leapY).toBe(0);
    expect(result.spinYaw).toBe(0);
    expect(result.wagBoost).toBe(0);
  });

  // Slice 4: Decays to 0 by/after window end, 0 before event
  it('decays to 0 by/after window end (~1200ms) and is 0 before masteredAt', () => {
    const masteredAt = 1000;
    const opts = { reducedMotion: false };

    // Before the event: now < masteredAt should return all 0
    const before = masteryFlourish(masteredAt - 100, masteredAt, opts);
    expect(before.leapY).toBe(0);
    expect(before.spinYaw).toBe(0);
    expect(before.wagBoost).toBe(0);

    // Well past the window (e.g., 2000ms later) should return all 0
    const wellPast = masteryFlourish(masteredAt + 2000, masteredAt, opts);
    expect(wellPast.leapY).toBe(0);
    expect(wellPast.spinYaw).toBe(0);
    expect(wellPast.wagBoost).toBe(0);
  });

  // Slice 5: Monotonic decay within the window
  it('decays monotonically from masteredAt through the window (~1200ms)', () => {
    const masteredAt = 1000;
    const opts = { reducedMotion: false };
    const samples = [0, 300, 600, 900, 1200, 1500].map(dt =>
      masteryFlourish(masteredAt + dt, masteredAt, opts)
    );

    // leapY should be non-increasing
    for (let i = 1; i < samples.length; i++) {
      expect(samples[i].leapY).toBeLessThanOrEqual(samples[i - 1].leapY);
    }

    // spinYaw should be non-increasing
    for (let i = 1; i < samples.length; i++) {
      expect(samples[i].spinYaw).toBeLessThanOrEqual(samples[i - 1].spinYaw);
    }

    // At the end of the window (and beyond), should be 0
    expect(samples[4].leapY).toBe(0); // 1200ms is the window end
    expect(samples[4].spinYaw).toBe(0);
    expect(samples[5].leapY).toBe(0); // Well past
    expect(samples[5].spinYaw).toBe(0);
  });

  // Slice 6: reducedMotion reduces amplitude but keeps it > 0 at peak
  it('reducedMotion reduces leapY and spinYaw at peak but keeps both > 0', () => {
    const masteredAt = 1000;
    const full = masteryFlourish(masteredAt, masteredAt, { reducedMotion: false });
    const reduced = masteryFlourish(masteredAt, masteredAt, { reducedMotion: true });

    // Reduced leapY should be smaller than full but still > 0
    expect(reduced.leapY).toBeLessThan(full.leapY);
    expect(reduced.leapY).toBeGreaterThan(0);

    // Reduced spinYaw should be smaller than full but still > 0
    expect(reduced.spinYaw).toBeLessThan(full.spinYaw);
    expect(reduced.spinYaw).toBeGreaterThan(0);

    // wagBoost can vary, but should also be > 0 at peak (similar spirit to leapY/spinYaw)
    expect(reduced.wagBoost).toBeGreaterThan(0);
  });

  // Slice 7: Verify monotonic decay of leapY at specific milestones
  it('leapY at peak > leapY at mid-window > leapY well past window', () => {
    const masteredAt = 1000;
    const opts = { reducedMotion: false };

    const peak = masteryFlourish(masteredAt, masteredAt, opts);
    const midWindow = masteryFlourish(masteredAt + 600, masteredAt, opts);
    const wellPast = masteryFlourish(masteredAt + 2000, masteredAt, opts);

    expect(peak.leapY).toBeGreaterThan(midWindow.leapY);
    expect(midWindow.leapY).toBeGreaterThan(wellPast.leapY);
    expect(wellPast.leapY).toBe(0);
  });

  // Slice 8: Verify monotonic decay of spinYaw at specific milestones
  it('spinYaw at peak > spinYaw at mid-window > spinYaw well past window', () => {
    const masteredAt = 1000;
    const opts = { reducedMotion: false };

    const peak = masteryFlourish(masteredAt, masteredAt, opts);
    const midWindow = masteryFlourish(masteredAt + 600, masteredAt, opts);
    const wellPast = masteryFlourish(masteredAt + 2000, masteredAt, opts);

    expect(peak.spinYaw).toBeGreaterThan(midWindow.spinYaw);
    expect(midWindow.spinYaw).toBeGreaterThan(wellPast.spinYaw);
    expect(wellPast.spinYaw).toBe(0);
  });
});
