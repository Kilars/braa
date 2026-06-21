import { describe, it, expect } from 'vitest';
import { createRound, markAt } from '../core/round';
import { buildTimeline, SchedulerConfig } from '../core/scheduler';
import { newProfile } from '../core/economy';
import { toViewModel } from './viewModel';

const cfg: SchedulerConfig = {
  attemptInterval: 2000,
  activeSpan: 800,
  windowWidth: 600,
  peakRadius: 100,
  distractorRate: 0,
};

const rng = () => 0.5;

describe('toViewModel', () => {
  it('learnedPercent is 0 for a new round', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const vm = toViewModel(state, 0);
    expect(vm.learnedPercent).toBe(0);
  });

  it('learnedPercent reflects session.learned after a PERFECT mark', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    // peak = 400ms (window center), peakRadius=100 → tap at 400 is PERFECT (+8)
    const afterMark = markAt(state, 400);
    const vm = toViewModel(afterMark, 400);
    expect(vm.learnedPercent).toBe(8);
  });

  it('mastered is false for a new round', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const vm = toViewModel(state, 0);
    expect(vm.mastered).toBe(false);
  });

  it('mastered is true when session.learned reaches 100', () => {
    // 13 PERFECT marks × 8 = 104, capped at 100 → mastered
    const timeline = buildTimeline(cfg, rng, 13);
    let state = createRound(timeline);
    for (let i = 0; i < 13; i++) {
      // Each event starts at i * 2000ms; peak is at activeStart + 400
      state = markAt(state, i * 2000 + 400);
    }
    const vm = toViewModel(state, 13 * 2000);
    expect(vm.mastered).toBe(true);
    expect(vm.learnedPercent).toBe(100);
  });

  it('lastResult is null for a new round', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const vm = toViewModel(state, 0);
    expect(vm.lastResult).toBeNull();
  });

  it('lastResult is PERFECT after a perfect mark', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const afterMark = markAt(state, 400); // peak hit
    const vm = toViewModel(afterMark, 400);
    expect(vm.lastResult).toBe('PERFECT');
  });

  it('confused is false for a new round', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const vm = toViewModel(state, 0);
    expect(vm.confused).toBe(false);
  });

  it('confused is true during confusedUntil window after FALSE_MARK', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    // Tap at t=50000 — outside any active window → FALSE_MARK → confusedUntil=53000
    const afterFalseMark = markAt(state, 50000);
    // At t=51000 (inside the 3s confuse window) → confused=true
    const vm = toViewModel(afterFalseMark, 51000);
    expect(vm.confused).toBe(true);
  });
});

// ─── Cycle 3: viewModel exposes coins from a passed-in profile ────────────────

describe('toViewModel — profile fields', () => {
  it('coins reflects the profile passed in', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const profile = { coins: 75, xp: 0, level: 1 };
    const vm = toViewModel(state, 0, profile);
    expect(vm.coins).toBe(75);
  });

  // ─── Cycle 4: viewModel exposes level from a passed-in profile ────────────

  it('level reflects the profile passed in', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const profile = { coins: 0, xp: 300, level: 3 };
    const vm = toViewModel(state, 0, profile);
    expect(vm.level).toBe(3);
  });

  it('existing fields are unaffected when profile is provided', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const vm = toViewModel(state, 0, newProfile());
    expect(vm.learnedPercent).toBe(0);
    expect(vm.mastered).toBe(false);
    expect(vm.lastResult).toBeNull();
    expect(vm.confused).toBe(false);
  });

  it('coins defaults to 0 when no profile is provided', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const vm = toViewModel(state, 0);
    expect(vm.coins).toBe(0);
  });

  it('level defaults to 1 when no profile is provided', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const vm = toViewModel(state, 0);
    expect(vm.level).toBe(1);
  });
});

// ─── Cycle 5: tell cue — attemptActive + tellStrength ────────────────────────
// Config: activeSpan=800, attemptInterval=2000, windowWidth=600
// Event 0: activeStart=0, activeEnd=800; window [100, 700]; peak=400
// Gap between events: now=1000 is outside any active window

describe('toViewModel — tell cue', () => {
  it('no active attempt → attemptActive=false, tellStrength=0', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const vm = toViewModel(state, 1000); // in the gap between events
    expect(vm.attemptActive).toBe(false);
    expect(vm.tellStrength).toBe(0);
  });

  it('active attempt, now===peak → tellStrength equals tellIntensity (max)', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    // Event 0: activeStart=0; window=[100,700]; peak=400
    const vm = toViewModel(state, 400, newProfile(), 1);
    expect(vm.attemptActive).toBe(true);
    expect(vm.tellStrength).toBeCloseTo(1, 5);
  });

  it('active attempt, now at scoring window edge → tellStrength ≈ 0', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    // Event 0: window=[100,700]; peak=400; halfSpan=300
    // now=100 → |100-400|/300 = 1.0 → tellStrength = 0
    const vm = toViewModel(state, 100, newProfile(), 1);
    expect(vm.attemptActive).toBe(true);
    expect(vm.tellStrength).toBeCloseTo(0, 5);
  });

  it('lower tellIntensity → strictly smaller tellStrength at peak (harder = fainter)', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const fullTell = toViewModel(state, 400, newProfile(), 1.0);
    const halfTell = toViewModel(state, 400, newProfile(), 0.5);
    expect(halfTell.tellStrength).toBeLessThan(fullTell.tellStrength);
    expect(halfTell.tellStrength).toBeCloseTo(0.5, 5);
  });

  it('omitting tellIntensity defaults to 1 — tellStrength at peak is 1', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    // No 4th arg — should default to tellIntensity=1
    const vm = toViewModel(state, 400);
    expect(vm.attemptActive).toBe(true);
    expect(vm.tellStrength).toBeCloseTo(1, 5);
  });
});

// ─── Cycle 6: engagement meter passthrough + derived beat ────────────────────

describe('toViewModel — engagement', () => {
  it('exposes the engagement meter passed in', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const vm = toViewModel(state, 0, newProfile(), 1, 0, 0.3);
    expect(vm.engagement).toBe(0.3);
  });

  it('derives the disengage beat from the meter (low meter → escalated beat)', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    expect(toViewModel(state, 0, newProfile(), 1, 0, 0.9).engagementBeat).toBe('engaged');
    expect(toViewModel(state, 0, newProfile(), 1, 0, 0).engagementBeat).toBe('walk-off');
  });

  it('defaults to a full, engaged meter when omitted', () => {
    const timeline = buildTimeline(cfg, rng, 5);
    const state = createRound(timeline);
    const vm = toViewModel(state, 0);
    expect(vm.engagement).toBe(1);
    expect(vm.engagementBeat).toBe('engaged');
  });
});

// ─── Disengagement (107): a `disengaged` flag for the call-back affordance ─────

describe('toViewModel — disengaged flag', () => {
  it('is true at an empty meter (walk-off → dog has walked off)', () => {
    const state = createRound(buildTimeline(cfg, rng, 5));
    expect(toViewModel(state, 0, newProfile(), 1, 0, 0).disengaged).toBe(true);
  });

  it('is false while the dog is still in play (any non-walk-off meter)', () => {
    const state = createRound(buildTimeline(cfg, rng, 5));
    expect(toViewModel(state, 0, newProfile(), 1, 0, 0.1).disengaged).toBe(false);
    expect(toViewModel(state, 0, newProfile(), 1, 0, 1).disengaged).toBe(false);
  });

  it('defaults to not-disengaged when the meter is omitted (fresh eager dog)', () => {
    const state = createRound(buildTimeline(cfg, rng, 5));
    expect(toViewModel(state, 0).disengaged).toBe(false);
  });
});

// ─── Tell suppression while disengaged (118, PO Review 2026-06-21 #4) ──────────
// A walked-off dog earns nothing from a mark, so the "mark now" apex cue must not
// fire — it would contradict the call-back affordance. Both tellStrength (drives
// the gold ring) and peakProximity (drives the on-dog apex shape) must be 0.

describe('toViewModel — apex tell suppressed while disengaged', () => {
  it('forces tellStrength to 0 even with an attempt sitting exactly at its peak', () => {
    const state = createRound(buildTimeline(cfg, rng, 5));
    // Event 0: window=[100,700], peak=400 → at now=400 an engaged dog yields
    // tellStrength=tellIntensity (1). Empty meter (engagementLevel=0) ⇒ disengaged.
    const vm = toViewModel(state, 400, newProfile(), 1, 0, 0);
    expect(vm.disengaged).toBe(true);
    expect(vm.tellStrength).toBe(0);
  });

  it('forces peakProximity to 0 while disengaged (no on-dog apex crest)', () => {
    const state = createRound(buildTimeline(cfg, rng, 5));
    const vm = toViewModel(state, 400, newProfile(), 1, 0, 0);
    expect(vm.peakProximity).toBe(0);
  });

  it('leaves the tell intact for an engaged dog at the peak (gate is engagement-scoped)', () => {
    const state = createRound(buildTimeline(cfg, rng, 5));
    // Healthy meter (1) at the same peak — the suppression must NOT touch this.
    const vm = toViewModel(state, 400, newProfile(), 1, 0, 1);
    expect(vm.disengaged).toBe(false);
    expect(vm.tellStrength).toBeCloseTo(1, 5);
    expect(vm.peakProximity).toBeCloseTo(1, 5);
  });
});
