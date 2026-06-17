# FEATURE: Ambient Sound Bed (TDD core + WebAudio)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Low
**Labels**: audio, core, tdd
**Estimated Effort**: Simple

## Context & Motivation

Audio is per-event (marks/mastery/tap). A soft looping ambient bed adds atmosphere.
Keep it subtle, mute-aware, lazy (autoplay policy).

## Affected Components
- Modify: `src/audio/markAudio.ts` (or a small ambient module): a pure `ambientSpec(): SoundSpec` (a low, quiet drone/pad — low freq, low gain, sine/triangle); `startAmbient()` / `stopAmbient()` on the `MarkAudio` class (a looping low-gain oscillator, mute-aware — `startAmbient` no-ops or stays silent while muted, and `setMuted(true)` stops it; `setMuted(false)` may resume) + test
- Modify: `src/main.ts` (start the ambient on the first user gesture — e.g. first BRA tap or first trick select — not on load, per autoplay policy)
- Dependencies: `markAudio.ts` (019/042/038-muted); Blocking: 019, 038

## Behaviors to test (each RED first — test the PURE spec + the mute interaction)
- `ambientSpec()` returns a low-freq, low-gain spec; deterministic.
- `startAmbient()` while muted produces no audible node / respects `isMuted()` (test the guard path — at minimum `isMuted()` gating; structure so a muted start doesn't create a running oscillator).
- `setMuted(true)` stops the ambient if running; `stopAmbient()` is idempotent (calling when not started doesn't throw).

## Notes on verification
- Not aurally verifiable headless. Confirm `bun run build` includes it + no console errors on load (AudioContext stays lazy — only created inside a user-gesture path). State this honestly.

## Progress Log
- 2026-06-14 — Task created (iteration 18)

## Resolution

**Ambient spec**: `ambientSpec()` returns `{ freq: 160, durationMs: 0, type: 'sine', gain: 0.04 }` — 160 Hz sine wave at 0.04 gain (well below event sounds at 0.6–0.9). `durationMs: 0` is a sentinel meaning "loop forever" (unused by the oscillator's `start()` call).

**Start/stop/mute logic**:
- `startAmbient()`: guards on `_muted` (sets `_ambientStarted=true` then returns early); guards on `_ambientOn` (no double-start); calls `ensureCtx()` — AudioContext only created here, never at module load; creates a looping oscillator with `ambientSpec()` values; tracks it in `_ambientOsc`; sets `_ambientOn=true`. All wrapped in try/catch for headless guard.
- `stopAmbient()`: idempotent — returns immediately if `!_ambientOn`; calls `_ambientOsc.stop()`, clears both, sets `_ambientOn=false`.
- `setMuted(true)`: sets `_muted=true` then calls `stopAmbient()` (stops any running ambient). `setMuted(false)`: if `_ambientStarted`, calls `startAmbient()` to resume.

**Triggered in main.ts**: `ensureAmbient()` helper (calls `markAudio.startAmbient()` once, guarded by `ambientStarted` boolean) is called at the top of `onBraTap` and `onSelectTrick` — the first user gesture that fires either path starts the ambient. Not called on load (AudioContext stays lazy).

**TDD cycles**: 5 cycles — ambientSpec freq range → ambientSpec gain+type+determinism → stopAmbient idempotent → startAmbient muted guard → setMuted(true) stops ambient.

**Not aurally verified**: WebAudio playback is a thin side-effect wrapper; audio output is not verifiable in headless E2E. All structural/behavioral invariants confirmed via tests.

**Verification**:
- `bun run typecheck`: 0 errors
- `bun run test`: 440 passed (433 existing + 7 new)
- `bun run build`: ✓ built in 13.07s
- `bun run e2e`: E2E SMOKE PASS

## Acceptance Criteria
- [x] `ambientSpec()` (low/quiet, deterministic) + `startAmbient`/`stopAmbient` written test-first; mute-aware; idempotent stop
- [x] Ambient starts on first user gesture (not on load); AudioContext stays lazy
- [x] Pure spec has no WebAudio/DOM imports
- [x] `bun run test` green; `bun run typecheck` 0; `bun run build` ok; `bun run e2e` PASS
