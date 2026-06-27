import { describe, expect, it } from 'vitest'
import { NORMAL_TUNING } from './tuning'
import { windowAtApex } from './window'
import { scoreTap } from './mark'
import {
  SIT_TIMINGS,
  sitPeriodMs,
  sitStateAt,
  type SitTimings,
} from './sitCycle'

// A small, round table so boundaries are easy to reason about in the tests.
const T: SitTimings = { idleMs: 1000, buildMs: 600, holdMs: 400, releaseMs: 600 }
// period = 2600; apex (fully-seated instant) at idle+build = 1600 into a cycle.
const START = 10_000

describe('sitPeriodMs', () => {
  it('is the sum of the four phase durations', () => {
    expect(sitPeriodMs(T)).toBe(2600)
  })
})

describe('sitStateAt', () => {
  it('starts idle, standing, with the apex one build away', () => {
    const s = sitStateAt(START, START, T)
    expect(s.phase).toBe('IDLE')
    expect(s.sitAmount).toBe(0)
    expect(s.cycleIndex).toBe(0)
    expect(s.apexTime).toBe(START + 1000 + 600)
  })

  it('clamps times before the start to the first idle', () => {
    const s = sitStateAt(START, START - 500, T)
    expect(s.phase).toBe('IDLE')
    expect(s.sitAmount).toBe(0)
    expect(s.cycleIndex).toBe(0)
  })

  it('builds toward the seat: BUILD, strictly rising 0→1', () => {
    const early = sitStateAt(START, START + 1100, T) // 100ms into build
    const late = sitStateAt(START, START + 1500, T) // 500ms into build
    expect(early.phase).toBe('BUILD')
    expect(late.phase).toBe('BUILD')
    expect(early.sitAmount).toBeGreaterThan(0)
    expect(early.sitAmount).toBeLessThan(1)
    expect(late.sitAmount).toBeGreaterThan(early.sitAmount)
  })

  it('is fully seated through the hold (the apex plateau)', () => {
    const atApex = sitStateAt(START, START + 1600, T)
    const midHold = sitStateAt(START, START + 1800, T)
    expect(atApex.phase).toBe('HOLD')
    expect(atApex.sitAmount).toBeCloseTo(1, 6)
    expect(midHold.phase).toBe('HOLD')
    expect(midHold.sitAmount).toBeCloseTo(1, 6)
  })

  it('releases back up: RELEASE, strictly falling 1→0', () => {
    const early = sitStateAt(START, START + 2100, T) // 100ms into release
    const late = sitStateAt(START, START + 2500, T) // 500ms into release
    expect(early.phase).toBe('RELEASE')
    expect(late.phase).toBe('RELEASE')
    expect(early.sitAmount).toBeLessThan(1)
    expect(early.sitAmount).toBeGreaterThan(0)
    expect(late.sitAmount).toBeLessThan(early.sitAmount)
  })

  it('loops: the next cycle is idle again with a later apex', () => {
    const s = sitStateAt(START, START + 2600, T)
    expect(s.phase).toBe('IDLE')
    expect(s.sitAmount).toBe(0)
    expect(s.cycleIndex).toBe(1)
    expect(s.apexTime).toBe(START + 2600 + 1600)
  })

  it('pose is continuous at the build→hold and hold→release seams (no snap)', () => {
    const eps = 1
    const beforeHold = sitStateAt(START, START + 1600 - eps, T)
    const afterHold = sitStateAt(START, START + 1600 + eps, T)
    expect(Math.abs(beforeHold.sitAmount - afterHold.sitAmount)).toBeLessThan(0.02)

    const holdEnd = START + 1600 + 400
    const beforeRel = sitStateAt(START, holdEnd - eps, T)
    const afterRel = sitStateAt(START, holdEnd + eps, T)
    expect(Math.abs(beforeRel.sitAmount - afterRel.sitAmount)).toBeLessThan(0.02)
  })
})

describe('sitCycle wired to the scoring core (task 002)', () => {
  it("the apex it reports IS the window's honest scoring peak", () => {
    const s = sitStateAt(START, START + 1600, T)
    const w = windowAtApex(s.apexTime, NORMAL_TUNING)
    expect(w.apex).toBe(s.apexTime)
    // A tap exactly on the reported apex is PERFECT.
    expect(scoreTap(w, s.apexTime)).toBe('PERFECT')
  })

  it('a tap during IDLE has no window to mark (NONE)', () => {
    const s = sitStateAt(START, START + 500, T)
    const w = s.phase === 'IDLE' ? null : windowAtApex(s.apexTime)
    expect(scoreTap(w, START + 500)).toBe('NONE')
  })

  it('tapping early in an active sit, before the window opens, is a MISS', () => {
    // 50ms into build: a sit is active, but well before open (apex-200).
    const now = START + 1050
    const s = sitStateAt(START, now, T)
    const w = s.phase === 'IDLE' ? null : windowAtApex(s.apexTime)
    expect(scoreTap(w, now)).toBe('MISS')
  })

  it('ships a real shared timing table', () => {
    expect(sitPeriodMs(SIT_TIMINGS)).toBeGreaterThan(0)
    expect(SIT_TIMINGS.buildMs).toBeGreaterThan(0)
  })
})

describe('PO C1 — "looks seated" == "is markable" (no dead seated tail)', () => {
  // The bug the PO play-test found: the dog held fully seated (sitAmount===1)
  // for longer than the scoring window stayed open, so a tap on the clearly
  // seated dog scored an unfair MISS while the tell was dark. The invariant:
  // every instant the *shipped* cadence holds the dog fully seated must be
  // markable under the *shipped* window (P1-3 — mark off the dog itself).
  it('every fully-seated (HOLD) instant of the shipped cadence scores at least OK', () => {
    const start = 0
    const apex = SIT_TIMINGS.idleMs + SIT_TIMINGS.buildMs // first-cycle apex
    const w = windowAtApex(apex) // shipped NORMAL window
    for (let tp = apex; tp < apex + SIT_TIMINGS.holdMs; tp += 5) {
      const st = sitStateAt(start, tp) // default = SIT_TIMINGS
      expect(st.phase).toBe('HOLD') // genuinely, fully seated ...
      expect(st.sitAmount).toBeCloseTo(1, 6)
      const tier = scoreTap(w, tp) // ... so a tap must score, never MISS/NONE
      expect(tier === 'OK' || tier === 'PERFECT').toBe(true)
    }
  })

  it('keeps PERFECT centered on the apex', () => {
    const apex = SIT_TIMINGS.idleMs + SIT_TIMINGS.buildMs
    const w = windowAtApex(apex)
    expect(scoreTap(w, apex)).toBe('PERFECT')
    expect(scoreTap(w, apex - NORMAL_TUNING.peakRadiusMs)).toBe('PERFECT')
    expect(scoreTap(w, apex + NORMAL_TUNING.peakRadiusMs)).toBe('PERFECT')
    expect(scoreTap(w, apex - NORMAL_TUNING.peakRadiusMs - 1)).toBe('OK')
  })
})
