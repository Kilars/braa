import { describe, expect, it } from 'vitest'
import { scoreTap, type MarkTier } from './mark'
import { windowAtApex } from './window'
import { NORMAL_TUNING } from './tuning'

// Phase-1 scoring core (spec P1-4, P1-5, P1-7). A sit peaks at an apex; a BRA
// tap scores by closeness to that peak. These tests are the contract: written
// first (red), the impl is the minimum that turns them green.
//
// Geometry under NORMAL_TUNING (the deprecated game's audited reference,
// tech-decisions §8): a 400 ms scoring window (±200 ms) with an 80 ms PERFECT
// sub-band (±80 ms), both centered honestly on the apex.

const APEX = 1000 // an arbitrary timeline ms; nothing depends on it being zero
const win = windowAtApex(APEX) // NORMAL: open=800, apex=1000, close=1200, peakRadius=80

describe('windowAtApex', () => {
  it('centers the scoring window honestly on the apex', () => {
    // P1-4: the band marks the *actual* peak, not slightly before/after it.
    expect(win.apex).toBe(APEX)
    expect(win.apex - win.open).toBe(win.close - win.apex)
  })

  it('derives open/close from the tuning window width', () => {
    expect(win.open).toBe(APEX - NORMAL_TUNING.windowWidthMs / 2)
    expect(win.close).toBe(APEX + NORMAL_TUNING.windowWidthMs / 2)
    expect(win.peakRadius).toBe(NORMAL_TUNING.peakRadiusMs)
  })

  it('is parameterized by a passed tuning table, not magic numbers', () => {
    const tight = windowAtApex(APEX, { windowWidthMs: 100, peakRadiusMs: 10 })
    expect(tight.open).toBe(950)
    expect(tight.close).toBe(1050)
    expect(tight.peakRadius).toBe(10)
  })
})

describe('scoreTap — PERFECT (apex band)', () => {
  it('scores a tap exactly on the apex as PERFECT', () => {
    expect(scoreTap(win, APEX)).toBe('PERFECT')
  })

  it('includes both edges of the PERFECT band (inclusive)', () => {
    expect(scoreTap(win, APEX - win.peakRadius)).toBe('PERFECT')
    expect(scoreTap(win, APEX + win.peakRadius)).toBe('PERFECT')
  })
})

describe('scoreTap — OK (inside window, off-peak)', () => {
  it('scores just outside the PERFECT band as OK', () => {
    expect(scoreTap(win, APEX - win.peakRadius - 1)).toBe('OK')
    expect(scoreTap(win, APEX + win.peakRadius + 1)).toBe('OK')
  })

  it('includes the scoring-window edges (inclusive) as OK', () => {
    expect(scoreTap(win, win.open)).toBe('OK')
    expect(scoreTap(win, win.close)).toBe('OK')
  })
})

describe('scoreTap — MISS (active sit, mistimed)', () => {
  it('scores just outside the scoring window as MISS', () => {
    expect(scoreTap(win, win.open - 1)).toBe('MISS')
    expect(scoreTap(win, win.close + 1)).toBe('MISS')
  })

  it('scores far outside an active window as MISS, not NONE', () => {
    // The sit is active (a window was passed); the player simply mistimed.
    expect(scoreTap(win, win.open - 5000)).toBe('MISS')
    expect(scoreTap(win, win.close + 5000)).toBe('MISS')
  })
})

describe('scoreTap — NONE (nothing to mark / dead tap)', () => {
  it('returns NONE when no window is open', () => {
    // P1-5: a tap with no window open simply does nothing — no feedback, no
    // sound, no penalty. This is distinct from MISS.
    expect(scoreTap(null, APEX)).toBe('NONE')
  })
})

describe('Phase-1 scope guard (P1-0)', () => {
  it('never produces a penalty tier — outcomes are exactly PERFECT/OK/MISS/NONE', () => {
    // Sweep the whole timeline around an active window plus the dead-tap case;
    // assert no fifth (penalty / false-mark) outcome can ever appear.
    const allowed: ReadonlySet<MarkTier> = new Set(['PERFECT', 'OK', 'MISS', 'NONE'])
    const seen = new Set<MarkTier>()
    seen.add(scoreTap(null, APEX))
    for (let t = win.open - 600; t <= win.close + 600; t += 5) {
      const tier = scoreTap(win, t)
      expect(allowed.has(tier)).toBe(true)
      seen.add(tier)
    }
    // The sweep should genuinely exercise all four tiers (proves the bands exist).
    expect(seen).toEqual(allowed)
  })

  it('is deterministic — same window and tap time give the same tier', () => {
    expect(scoreTap(win, APEX + 30)).toBe(scoreTap(win, APEX + 30))
  })
})
