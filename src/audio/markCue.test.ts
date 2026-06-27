import { describe, expect, it } from 'vitest'
import { cueForTier } from './markCue'

/**
 * The mark-payoff cue decision (spec P1-6): which sound, if any, a scored tap
 * earns. Gating lives here so the player can stay a dumb no-op-on-null sink —
 * a Miss and a dead tap are silent (no penalty audio in Phase 1, P1-5), and
 * PERFECT is brighter than OK.
 */
describe('cueForTier', () => {
  it('is silent on a dead tap (NONE)', () => {
    expect(cueForTier('NONE')).toBeNull()
  })

  it('is silent on a Miss (no penalty audio in Phase 1)', () => {
    expect(cueForTier('MISS')).toBeNull()
  })

  it('plays a plain cue on OK (no sparkle)', () => {
    const cue = cueForTier('OK')
    expect(cue).not.toBeNull()
    expect(cue?.sparkle).toBe(false)
  })

  it('plays a brighter cue on PERFECT — sparkle on, intensity above OK', () => {
    const ok = cueForTier('OK')
    const perfect = cueForTier('PERFECT')
    expect(perfect).not.toBeNull()
    expect(perfect?.sparkle).toBe(true)
    // PERFECT sounds brighter than OK (P1-6).
    expect(perfect!.intensity).toBeGreaterThan(ok!.intensity)
  })

  it('keeps every intensity in the unit range', () => {
    for (const cue of [cueForTier('OK'), cueForTier('PERFECT')]) {
      expect(cue!.intensity).toBeGreaterThan(0)
      expect(cue!.intensity).toBeLessThanOrEqual(1)
    }
  })
})
