# FEATURE: Mark payoff — voice + SFX on a successful BRA (P1-6 audio half)

**Status**: Done
**Created**: 2026-06-27
**Priority**: P0 (Phase 1 core-loop payoff — the mark is the whole game)
**Labels**: audio, gameplay, phase-1
**Estimated Effort**: Medium

## Context & Motivation

The core loop currently ends silent: a BRA tap scores a tier and flashes a readout
(`main.ts` + `shell.ts`), but **nothing is heard**. Spec P1-6 ("the mark feels good")
and the cross-cutting X-3 ("the mark always feels good") require voice + SFX on every
successful mark — this is the payoff the entire game exists to deliver (NS-1). No audio
module exists yet (`grep` of `src/` finds no WebAudio/Audio).

This task delivers the **audio half** of P1-6. The dog-reaction half is task 005; the
on-screen-feedback / never-contradicts-audio tie-together is task 006.

## Desired Outcome

- A warm, Maren-style spoken **"Bra!"** plays on a successful mark (synthesized
  placeholder is acceptable for Phase 1; the real Maren voice is an owner-gated drop-in
  behind the same cue — keep the call site asset-swappable, tech-decisions §3h).
- A crisp UI **click** sits under the voice.
- **PERFECT sounds brighter than OK** (e.g. higher gain / brighter timbre / a small
  sparkle the OK cue lacks).
- Audio is **gated correctly**: nothing plays on a **Miss** or a **dead tap** (NONE).
- Browser autoplay policy respected: the AudioContext is unlocked/resumed on the first
  user gesture so the very first successful BRA is audible.

## Affected Components

### Files to Create
- `src/audio/markCue.ts` — pure tier→cue decision (TDD) + a thin WebAudio player.
- `src/audio/markCue.test.ts` — the decision tests.

### Files to Modify
- `src/main.ts` — on a scored tap, ask `markCue` to play; unlock audio on first gesture.

## Technical Approach

**Test-first (TDD — see `.claude/skills/tdd/SKILL.md`).** Split the decision (pure,
tested) from the sound output (thin, untested glue). The decision is a pure function:

```ts
// src/audio/markCue.ts
export interface Cue {
  /** Relative voice gain / brightness, 0..1; PERFECT > OK. */
  intensity: number
  /** Whether the bright PERFECT sparkle layers in. */
  sparkle: boolean
}
// Returns null when there is nothing to celebrate (silence).
export function cueForTier(tier: MarkTier): Cue | null { /* ... */ }
```

Behaviors to test (one test → minimal impl → repeat):
- `cueForTier('NONE')` → `null` (dead tap is silent).
- `cueForTier('MISS')` → `null` (a miss is silent — no penalty audio in Phase 1, P1-5).
- `cueForTier('OK')` → a cue with `sparkle: false`.
- `cueForTier('PERFECT')` → a cue with `sparkle: true` and `intensity` strictly greater
  than the OK cue's intensity (PERFECT brighter than OK).

Then the thin player (not unit-tested; exercised via e2e smoke that audio wiring exists):

```ts
export function createMarkAudio(): {
  unlock(): void              // resume()s the context on first gesture
  play(tier: MarkTier): void  // no-op when cueForTier returns null
}
```

Use a single lazily-created `AudioContext`; synthesize the click (short noise/triangle
blip) and the "Bra!" voice (a couple of detuned oscillators with an AD envelope is a fine
Phase-1 placeholder) so there are **no binary assets to license yet**. Keep `play` a
no-op when `cueForTier` returns null so gating lives in one place.

### Before
```ts
// main.ts — scored tap shows a readout, makes no sound
braButton.addEventListener('pointerup', () => {
  const tier = scene.scoreTapNow(performance.now())
  if (tier === 'NONE') return
  tierReadout.textContent = tier
  // ...
})
```

### After
```ts
const audio = createMarkAudio()
// Unlock on the first gesture so the first BRA is audible (autoplay policy).
braButton.addEventListener('pointerdown', () => audio.unlock(), { once: true })
braButton.addEventListener('pointerup', () => {
  const tier = scene.scoreTapNow(performance.now())
  audio.play(tier)          // no-op on NONE/MISS — gating lives in cueForTier
  if (tier === 'NONE') return
  tierReadout.textContent = tier
  // ...
})
```

## Risks & Considerations
- **Risk**: e2e/headless has no real audio device. **Mitigation**: never assert audible
  output; unit-test the pure `cueForTier`, and have the player guard a missing/!secure
  `AudioContext` so it degrades to a no-op (app must still boot green).
- **Risk**: real Maren voice is owner/likeness-gated (B-4). **Mitigation**: synthesized
  placeholder behind the same `play('PERFECT'|'OK')` call site — a one-file swap later.

## Acceptance Criteria
- [x] `cueForTier` written test-first: NONE→null, MISS→null, OK→no sparkle,
      PERFECT→sparkle + intensity > OK (failing tests committed before impl)
- [x] A "Bra!" voice + click plays on OK/PERFECT; PERFECT is audibly brighter than OK
- [x] Nothing plays on Miss or dead tap (gated in one place)
- [x] AudioContext unlocks on first gesture; player no-ops without a usable context
- [x] Verify gate stays green (typecheck/test/build/e2e)

## Resolution (2026-06-27)

Done via TDD. Red→green: `src/audio/markCue.test.ts` (5 tests) written first against a
missing module, then `src/audio/markCue.ts` implemented to pass — `cueForTier` is the
single gating point (NONE/MISS → `null` silence; OK → no sparkle; PERFECT → sparkle +
intensity 1 > OK's 0.6). The thin `createMarkAudio` player synthesizes a crisp triangle
click + a warm two-saw "Bra!" voice (brighter pitch/gain on PERFECT) with an optional
high sparkle bell on PERFECT — all procedural, **no binary assets to license** (real
Maren voice is the owner-gated drop-in behind the same `play(tier)` call site,
tech-decisions §3h / B-4). It degrades to a no-op when no `AudioContext` exists (headless
e2e / insecure context), so the app still boots green.

Wired in `main.ts`: `audio.unlock()` on the first `pointerdown` (autoplay policy), and
`audio.play(tier)` on every scored `pointerup` — a no-op on Miss/dead tap. Gate green:
typecheck 0 errors · test **33 passed** · build no warnings · e2e 3 passed.

Note: audible quality is a Phase-1 placeholder; "feels good" / PERFECT-vs-OK brightness
is finally judged in the task-006 Visual/QA review of the whole loop. Audio can't be
asserted headless, so e2e covers only that the wiring boots green.
