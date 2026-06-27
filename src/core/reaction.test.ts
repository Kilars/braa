import { describe, expect, it } from 'vitest'
import { reactionAt, REACTION_MS } from './reaction'

/**
 * The mark-reaction envelope (spec P1-6 / D8): the time-shape of the dog's
 * happy perk-up after a successful BRA. Pure so the *timing* is tested here and
 * the mesh application stays a thin visual layer. Amplitudes are normalized
 * 0..1; a higher `strength` (PERFECT) peaks higher than a lower one (OK).
 */
describe('reactionAt', () => {
  const START = 1000

  it('rests when no reaction is active', () => {
    expect(reactionAt(null, 5000, 1)).toEqual({ bounce: 0, wag: 0, pop: 0 })
  })

  it('rests before the reaction starts', () => {
    expect(reactionAt(START, START - 10, 1)).toEqual({ bounce: 0, wag: 0, pop: 0 })
  })

  it('is active (bounce > 0) shortly after the start', () => {
    const r = reactionAt(START, START + 60, 1)
    expect(r.bounce).toBeGreaterThan(0)
    expect(r.wag).toBeGreaterThan(0)
  })

  it('decays back to rest after the reaction window', () => {
    const r = reactionAt(START, START + REACTION_MS + 50, 1)
    expect(r).toEqual({ bounce: 0, wag: 0, pop: 0 })
  })

  it('peaks higher for PERFECT than for OK', () => {
    // Sample both at the same instant near the attack peak.
    const at = START + 0.14 * REACTION_MS
    const perfect = reactionAt(START, at, 1)
    const ok = reactionAt(START, at, 0.55)
    expect(perfect.bounce).toBeGreaterThan(ok.bounce)
  })

  it('keeps amplitudes within the unit range', () => {
    for (let t = 0; t <= REACTION_MS; t += 25) {
      const r = reactionAt(START, START + t, 1)
      expect(r.bounce).toBeGreaterThanOrEqual(0)
      expect(r.bounce).toBeLessThanOrEqual(1)
      expect(r.wag).toBeGreaterThanOrEqual(0)
      expect(r.wag).toBeLessThanOrEqual(1)
      expect(r.pop).toBeGreaterThanOrEqual(0)
      expect(r.pop).toBeLessThanOrEqual(1)
    }
  })

  // PO Review I1 — the celebration must read as a celebration on its own. The
  // grounded `pop` (squash-and-settle) channel carries the unmistakable, still-
  // grounded energy and must be DISTINCTLY punchier for PERFECT than for OK.
  describe('pop — grounded squash-and-settle (PO I1)', () => {
    it('pops shortly after the mark, then settles back to rest before the window ends', () => {
      expect(reactionAt(START, START + 0.08 * REACTION_MS, 1).pop).toBeGreaterThan(0)
      // settled (grounded again) well before the reaction window closes
      expect(reactionAt(START, START + 0.8 * REACTION_MS, 1).pop).toBe(0)
    })

    it('is silent for a non-celebration (strength 0) and when no reaction is active', () => {
      expect(reactionAt(START, START + 0.1 * REACTION_MS, 0).pop).toBe(0)
      expect(reactionAt(null, START, 1).pop).toBe(0)
    })

    it('is DISTINCTLY punchier for PERFECT than OK (>= 1.6x at the peak)', () => {
      // compare each channel at its own peak strength-scaling
      const at = START + 0.05 * REACTION_MS // near the pop peak
      const perfect = reactionAt(START, at, 1).pop
      const ok = reactionAt(START, at, 0.55).pop
      expect(ok).toBeGreaterThan(0)
      expect(perfect).toBeGreaterThanOrEqual(ok * 1.6)
    })
  })
})
