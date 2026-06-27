import type { MarkTier } from '../core/mark'

/**
 * The mark-payoff audio (spec P1-6 / X-3: "the mark always feels good"). Split
 * in two so all the gating lives in one pure, tested place:
 *
 *  - `cueForTier` — a pure decision: a scored tier → the cue to play, or `null`
 *    when there is nothing to celebrate (a Miss and a dead tap are silent — no
 *    penalty audio in Phase 1, P1-5). PERFECT is brighter than OK.
 *  - `createMarkAudio` — a thin WebAudio player that synthesizes a warm "Bra!"
 *    plus a crisp click. It is a no-op whenever `cueForTier` returns `null`, and
 *    degrades to a silent no-op where no usable `AudioContext` exists (headless
 *    e2e, insecure context), so the app always boots green.
 *
 * The synthesized voice is a Phase-1 placeholder; the real Maren voice is an
 * owner-gated drop-in behind this same `play(tier)` call site (tech-decisions
 * §3h, B-4) — a one-file swap, no call-site change.
 */

export interface Cue {
  /** Relative voice gain / brightness in (0,1]; PERFECT > OK. */
  intensity: number
  /** Whether the bright PERFECT sparkle layers in on top of the voice. */
  sparkle: boolean
}

/** Decide the cue for a scored tap, or `null` for silence (NONE / MISS). */
export function cueForTier(tier: MarkTier): Cue | null {
  switch (tier) {
    case 'PERFECT':
      return { intensity: 1, sparkle: true }
    case 'OK':
      return { intensity: 0.6, sparkle: false }
    // A Miss is shown on screen but stays silent; a dead tap does nothing (P1-5).
    case 'MISS':
    case 'NONE':
      return null
  }
}

export interface MarkAudio {
  /** Resume the context on the first user gesture (browser autoplay policy). */
  unlock(): void
  /** Play the payoff for a scored tier; a no-op when the tier earns no cue. */
  play(tier: MarkTier): void
}

type AudioCtor = typeof AudioContext

function resolveAudioContext(): AudioCtor | null {
  if (typeof window === 'undefined') return null
  const w = window as unknown as {
    AudioContext?: AudioCtor
    webkitAudioContext?: AudioCtor
  }
  return w.AudioContext ?? w.webkitAudioContext ?? null
}

/**
 * Build the payoff player. All synthesis is procedural, so there are no binary
 * assets to license yet. If the platform has no `AudioContext`, every method is
 * a safe no-op.
 */
export function createMarkAudio(): MarkAudio {
  const Ctor = resolveAudioContext()
  if (!Ctor) {
    return { unlock() {}, play() {} }
  }

  let ctx: AudioContext | null = null
  const ensureCtx = (): AudioContext | null => {
    if (!ctx) {
      try {
        ctx = new Ctor()
      } catch {
        ctx = null
      }
    }
    return ctx
  }

  /** A short percussive click — the crisp UI layer under the voice (P1-6). */
  const playClick = (c: AudioContext, t0: number, gain: number) => {
    const osc = c.createOscillator()
    const g = c.createGain()
    osc.type = 'triangle'
    osc.frequency.setValueAtTime(1400, t0)
    osc.frequency.exponentialRampToValueAtTime(600, t0 + 0.04)
    g.gain.setValueAtTime(0.0001, t0)
    g.gain.exponentialRampToValueAtTime(gain, t0 + 0.005)
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.06)
    osc.connect(g).connect(c.destination)
    osc.start(t0)
    osc.stop(t0 + 0.07)
  }

  /**
   * A warm, two-syllable "Bra!" placeholder: a pair of detuned saw voices with a
   * quick rise-then-fall on the formant, brighter when `intensity` is higher so
   * PERFECT outshines OK. The optional sparkle adds a high bell on PERFECT.
   */
  const playVoice = (c: AudioContext, t0: number, cue: Cue) => {
    const peak = 0.18 + cue.intensity * 0.22
    const base = 250 + cue.intensity * 40 // brighter pitch on PERFECT
    for (const detune of [-6, 6]) {
      const osc = c.createOscillator()
      const g = c.createGain()
      osc.type = 'sawtooth'
      osc.detune.setValueAtTime(detune, t0)
      // "Bra" — an open vowel sweeping up then settling.
      osc.frequency.setValueAtTime(base, t0)
      osc.frequency.linearRampToValueAtTime(base * 1.5, t0 + 0.08)
      osc.frequency.linearRampToValueAtTime(base * 1.15, t0 + 0.26)
      g.gain.setValueAtTime(0.0001, t0)
      g.gain.exponentialRampToValueAtTime(peak, t0 + 0.03)
      g.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.34)
      osc.connect(g).connect(c.destination)
      osc.start(t0)
      osc.stop(t0 + 0.36)
    }
    if (cue.sparkle) {
      const bell = c.createOscillator()
      const bg = c.createGain()
      bell.type = 'sine'
      bell.frequency.setValueAtTime(1760, t0)
      bell.frequency.linearRampToValueAtTime(2640, t0 + 0.12)
      bg.gain.setValueAtTime(0.0001, t0)
      bg.gain.exponentialRampToValueAtTime(0.12, t0 + 0.02)
      bg.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.22)
      bell.connect(bg).connect(c.destination)
      bell.start(t0)
      bell.stop(t0 + 0.24)
    }
  }

  return {
    unlock() {
      const c = ensureCtx()
      if (c && c.state === 'suspended') void c.resume()
    },
    play(tier) {
      const cue = cueForTier(tier)
      if (!cue) return // gating lives in cueForTier — Miss / dead tap are silent
      const c = ensureCtx()
      if (!c) return
      if (c.state === 'suspended') void c.resume()
      const t0 = c.currentTime + 0.001
      playClick(c, t0, 0.18 + cue.intensity * 0.12)
      playVoice(c, t0 + 0.02, cue)
    },
  }
}
