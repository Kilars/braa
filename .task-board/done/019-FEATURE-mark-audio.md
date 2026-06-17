# FEATURE: Mark Audio — SFX feedback (TDD core + WebAudio)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: core, audio, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec design principle: "The mark must always feel good — voice + SFX + reaction on
every successful BRA." We have visual reaction; add audio. The marker VOICE
(Maren) sourcing is deliberately deferred (tech-decisions §3), so use a synthesized
placeholder. This task: a crisp per-result SFX via WebAudio, with the sound-choice
logic unit-tested.

## Current State

No audio. Taps produce only visual feedback.

## Desired Outcome

`src/audio/markAudio.ts`: a pure `soundForResult(result)` mapping each MarkResult
to a sound spec (frequency/duration/type), plus a thin WebAudio player
`playMark(result)` that synthesizes it (no asset files needed). Wired so each tap
plays its sound. PERFECT = brightest/most satisfying; FALSE_MARK = a dull/negative blip.

## Affected Components
- Create: `src/audio/markAudio.ts` (pure `soundForResult` + a `MarkAudio` player class) + `src/audio/markAudio.test.ts`
- Modify: `src/main.ts` (call `playMark(result)` on each tap; lazily create AudioContext on first user gesture per browser autoplay rules)
- Dependencies: `mark.ts` (`MarkResult`); Blocking: 002

## Interface (signatures — bodies test-first)

```ts
export interface SoundSpec { freq: number; durationMs: number; type: OscillatorType; gain: number; }
export function soundForResult(result: MarkResult): SoundSpec;   // PURE — unit tested
export class MarkAudio { play(result: MarkResult): void; }       // thin WebAudio wrapper
```

## Behaviors to test (each RED first — test `soundForResult`, NOT the audio output)
- Each MarkResult returns a SoundSpec.
- PERFECT has a higher freq / gain than OK (brighter).
- FALSE_MARK is distinct and "negative" (e.g. lowest freq / short) vs PERFECT.
- MISS is quietest/most neutral (or silent — decide and test).
- Specs are deterministic (same result → same spec).

## Notes on verification
- The SFX logic is unit-tested. Actual audio playback cannot be verified in
  headless CI (no audio device) — confirm `bun run build` includes it and that
  `playMark` is guarded behind a user-gesture-created AudioContext (no console
  errors on load). State this honestly in Resolution.

## Risks
- Autoplay policy: create/resume the AudioContext on the first BRA tap, not on load.

## Progress Log
- 2026-06-14 — Task created (iteration 6)

## Resolution

### Red-Green Cycles

**Cycle 1** — `soundForResult` returns a SoundSpec for PERFECT
- RED: test file with import fails (module not found)
- GREEN: created `markAudio.ts` with `soundForResult` switch + `MarkAudio` class

**Cycle 2** — PERFECT brighter than OK (higher freq AND gain)
- Added test: `perfect.freq > ok.freq` AND `perfect.gain > ok.gain`
- Already GREEN from cycle 1 values (880/0.9 vs 660/0.6) — constraint documented by test

**Cycle 3** — FALSE_MARK is lowest freq of all; 4x below PERFECT
- Added two tests: FALSE_MARK < MISS < OK < PERFECT in freq; ratio >= 4
- Already GREEN from chosen values (180, 440, 660, 880 Hz; ratio = 4.89)

**Cycle 4** — MISS is quietest (lowest gain of all four)
- Added test: MISS gain < all others
- GREEN: MISS gain=0.15 < FALSE_MARK 0.5 < OK 0.6 < PERFECT 0.9

**Cycle 5** — Deterministic (same input → equal spec)
- Added test looping all four MarkResults, comparing `toEqual`
- GREEN: switch returns new object literals with same values each time

### SoundSpec values chosen
| Result     | freq (Hz) | durationMs | type      | gain |
|------------|-----------|------------|-----------|------|
| PERFECT    | 880       | 200        | sine      | 0.90 |
| OK         | 660       | 150        | sine      | 0.60 |
| MISS       | 440       | 100        | sine      | 0.15 |
| FALSE_MARK | 180       | 80         | sawtooth  | 0.50 |

### AudioContext lazy creation
`MarkAudio` holds `private ctx: AudioContext | null = null`. Inside `play()`:
1. Guard: `if (typeof AudioContext === 'undefined') return;` — safe in Node/headless
2. On first user tap: `this.ctx = new AudioContext()` (created inside user-gesture callback)
3. On subsequent taps if suspended: `this.ctx.resume()` — respects browser autoplay policy
4. Entire `play()` body wrapped in `try/catch` — silent fail if AudioContext unavailable

### Verification
- `bun run test`: 177/177 passed (171 pre-existing + 6 new)
- `bun run typecheck`: 0 errors
- `bun run build`: dist produced successfully
- Audio playback: NOT aurally verified (headless CI has no audio device). Implementation
  is present and wired; AudioContext is only created on first BRA tap (user gesture),
  satisfying autoplay policy. No console errors on load.

## Acceptance Criteria
- [x] `soundForResult` written test-first; PERFECT brighter than OK; FALSE_MARK distinct/negative; deterministic
- [x] `MarkAudio.play` synthesizes via WebAudio (no asset files); AudioContext created/resumed on first user gesture
- [x] `main.ts` plays the sound on each tap
- [x] `soundForResult` is pure (no WebAudio/DOM imports); only the player touches AudioContext
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds (audio playback not aurally verified — noted)
