import { describe, expect, it } from 'vitest'
import { SIT_TIMINGS, sitPeriodMs, sitStateAt } from './sitCycle'
import { NORMAL_TUNING } from './tuning'
import { getTrick, TRICKS, type TrickId } from './trick'

// The Phase-2 trick registry generalizes the Sitt-only brain into a list of
// TrickDefs (id, label, timings, poseKind). This task adds only the model +
// the seam; Sitt must stay byte-identical, and the registry/lookup must be
// honest (unknown ids throw rather than silently posing the wrong trick).

describe('trick registry', () => {
  it('contains Sitt as a known trick', () => {
    expect(getTrick('sitt').label).toBe('Sitt')
    expect(getTrick('sitt').poseKind).toBe('sit')
  })

  it('every registry entry has a real, positive cadence', () => {
    for (const t of TRICKS) {
      expect(t.id).toBeTruthy()
      expect(t.label).toBeTruthy()
      expect(sitPeriodMs(t.timings)).toBeGreaterThan(0)
    }
  })

  it('Sitt carries exactly the shipped SIT_TIMINGS (no feel change)', () => {
    expect(getTrick('sitt').timings).toEqual(SIT_TIMINGS)
  })

  it('throws on an unknown trick id (never silently mis-poses)', () => {
    expect(() => getTrick('nope' as TrickId)).toThrow()
  })

  it('contains Ligg as a distinct lie-down trick (task 013)', () => {
    const ligg = getTrick('ligg')
    expect(ligg.label).toBe('Ligg')
    expect(ligg.poseKind).toBe('liedown')
    // Ligg must be a genuinely different trick from Sitt, not an alias: a
    // distinct pose AND its own cadence (P2-2 — every trick performs its own).
    expect(ligg.poseKind).not.toBe(getTrick('sitt').poseKind)
    expect(ligg.timings).not.toEqual(getTrick('sitt').timings)
  })

  it('every trick keeps "looks built == is markable": holdMs <= windowWidthMs/2', () => {
    // The held apex plateau must not outlive the scoring window, or the dog would
    // "look fully built" while a tap scores an unfair MISS and the tell is dark
    // (PO C1 / task 007). This is a per-trick invariant, so it must hold for Ligg
    // and every future trick, not just Sitt.
    const halfWindow = NORMAL_TUNING.windowWidthMs / 2
    for (const t of TRICKS) {
      expect(t.timings.holdMs).toBeLessThanOrEqual(halfWindow)
    }
  })
})

describe('Sitt is byte-identical after the trick generalization', () => {
  it('state sampled across a full cycle equals sitStateAt(..., SIT_TIMINGS)', () => {
    const sitt = getTrick('sitt').timings
    const start = 0
    for (let now = 0; now < sitPeriodMs(SIT_TIMINGS) + 200; now += 37) {
      expect(sitStateAt(start, now, sitt)).toEqual(
        sitStateAt(start, now, SIT_TIMINGS),
      )
    }
  })
})
