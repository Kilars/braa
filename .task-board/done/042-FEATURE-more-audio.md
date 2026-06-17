# FEATURE: More Audio — mastery jingle + tap SFX (TDD core + WebAudio)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Low
**Labels**: audio, core, tdd
**Estimated Effort**: Simple

## Context & Motivation

Audio is sparse: only per-mark SFX (019). Spec values the "mark feels good" beat and
a satisfying loop. Add a **mastery jingle** (a short rewarding arpeggio when a trick is
mastered) and a soft **button-tap** click for UI buttons. (Voice/ambient remain deferred —
Maren voice is tech-decisions §3; ambient is optional.)

## Affected Components
- Modify: `src/audio/markAudio.ts` — add pure `masterySound(): SoundSpec[]` (a short ascending arpeggio = an ordered list of SoundSpecs) and a pure `tapSound(): SoundSpec`; add `playMastery()` and `playTap()` methods (respect the `muted` flag from 038). + test the pure spec builders.
- Modify: `src/main.ts` — call `playMastery()` on the mastered false→true transition; optionally `playTap()` on BRA/menu taps (keep it subtle; don't double up with the mark SFX on BRA — use tap only for menu buttons).
- Dependencies: `mark.ts`; Blocking: 019, 038 (muted)

## Behaviors to test (each RED first — test the PURE spec builders, not playback)
- `masterySound()` returns an ordered arpeggio (length ≥ 3) with ascending frequencies (rewarding feel) and finite gains.
- `tapSound()` is a short, low-gain click (deterministic spec).
- Both are deterministic (same call → equal spec).
- `playMastery`/`playTap` no-op when muted (guarded — same pattern as `play`).

## Notes on verification
- SFX specs are unit-tested. Actual audio isn't aurally verifiable headless — confirm
  `bun run build` includes it + no console errors on load (the AudioContext stays lazy).

## Progress Log
- 2026-06-14 — Task created (iteration 14)

## Resolution

Implemented 2026-06-14 via 6 red-green TDD cycles.

### Red-green cycles

1. `masterySound()` length ≥ 3 → exported function returning 3-note literal array
2. Strictly ascending frequencies → same literals (523→659→784 Hz) satisfy it; test locks the contract
3. All gains finite + positive → literals satisfy; contract locked
4. `masterySound()` deterministic → toEqual check passes immediately
5. `tapSound()` gain < 0.2, durationMs ≤ 60 → RED (not a function), GREEN with `{freq:600, durationMs:40, type:'sine', gain:0.08}`
6. `tapSound()` deterministic → toEqual passes immediately

### Mastery arpeggio spec (masterySound)

| Note | freq (Hz) | durationMs | gain |
|------|-----------|------------|------|
| 1    | 523 (C5)  | 120        | 0.5  |
| 2    | 659 (E5)  | 120        | 0.5  |
| 3    | 784 (G5)  | 200        | 0.6  |

A C-major triad arpeggio (C5→E5→G5), ~440 ms total. Notes played sequentially via cursor offset in `playMastery()`.

### Tap click spec (tapSound)

`{ freq: 600, durationMs: 40, type: 'sine', gain: 0.08 }` — very short, very quiet.

### Wiring in main.ts

- `markAudio.playMastery()` — called inside the `!prevMastered && currentlyMastered` branch in `tick()`, immediately after `recordMastery()`, before `completeMastery()`.
- `markAudio.playTap()` — called at the top of `onSelectTrick()` and `onSelectDog()` callbacks (menu selections only; BRA tap still uses `play(result)` unchanged).

### Verification

- `bun run test`: 355 passed (349 existing + 6 new), 23 test files, 0 failures
- `bun run typecheck`: 0 errors (tsc --noEmit, silent exit)
- `bun run build`: built in 13.04s, dist/assets/index-COibklMd.js 31.21 kB

## Acceptance Criteria
- [x] `masterySound()` (ascending arpeggio, ≥3 notes) + `tapSound()` written test-first; deterministic
- [x] `playMastery()` fires on mastery; `playTap()` available for menu buttons; both respect mute
- [x] Pure spec builders have no WebAudio/DOM imports; AudioContext stays lazy
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
