# FEATURE: Dog foley + a real ambient bed (synthesis params, TDD)

**Status**: Backlog — queued for next round (audio is **not aurally verifiable
headless**; needs a human listen like 074)
**Created**: 2026-06-17
**Priority**: Medium
**Labels**: audio, feature, tdd, human-verify
**Estimated Effort**: Medium

## Context & Motivation

The dog is silent and the "ambient" track is a single synth drone, not a living
training-ground bed. Adding light **dog foley** (a soft pant on idle, a happy
bark/whine on mastery, a low "huff" on a false-mark) and a richer ambient pad gives
the scene life and reinforces the mark moment aurally. This is **not** the
Maren voice-likeness item (§4, owner-gated) — it is synthesised foley, so it is
non-gated and actionable. Like 074, the synthesis math is TDD-able but playback
**cannot be verified in this headless loop** — TDD the params + wiring and flag a
human on-device listen as the closing step.

## Current State

- `src/audio/` holds the WebAudio SFX (mark layers, mastery arpeggio, tap, ambient
  pad). Mark SFX already follow a pure-`markLayers` + lazy-`AudioContext` pattern
  (task 074); ambient is a lone ~160 Hz pad (task 054). All mute-aware.
- No dog-originated sound exists.

## Desired Outcome

A small pure `foleyLayers(event)` (or equivalent) mapping a dog event
(`idle-pant | mastery-bark | false-huff`) to oscillator/noise params (freq,
duration, gain, type, envelope), wired into the existing lazy/mute-aware audio
path, plus a fuller ambient bed. No call-site outside audio changes.

## Technical Approach

### Architecture (mirror task 074)
- **Pure params, impure playback.** `foleyLayers(event)` returns plain
  descriptors; the `AudioContext` scheduling is the impure shell. Keep it
  mute-aware and lazy (no ctx before first gesture).
- Reuse the noise/oscillator helpers already in `src/audio/`.

### Behaviours to test (TDD — `.claude/skills/tdd/SKILL.md`)
1. `foleyLayers('mastery-bark')` returns a non-empty, bounded layer set (freq in a
   sane canine range, duration ≤ a cap, gain ≤ 1).
2. Each event maps to a **distinct** signature (bark ≠ huff ≠ pant).
3. A false-mark "huff" is low-freq + short; a mastery bark is brighter/longer.
4. Muted → playback path is a no-op (assert no ctx nodes created), as with marks.

### Implementation Steps
1. TDD `foleyLayers` through behaviours 1–4.
2. Wire it into the audio module behind the existing mute/lazy guard; trigger on
   the same edges as the dog visual states (idle, mastery, false-mark).
3. Enrich the ambient bed (a second detuned partial / gentle LFO) — pure param
   change, TDD the param shape.

## Risks & Considerations
- **Not headless-verifiable** — do NOT claim an aural result. Close with a
  "human on-device listen recommended" note (precedent: 074).
- **Annoyance budget** — foley must be subtle and infrequent; gains well under the
  mark SFX so it never masks the praise tone. Document chosen gains in §7/§4.
- **Mute correctness** — every new sound must respect the existing mute toggle.

## Acceptance Criteria
- [x] Pure `foleyLayers(event)` TDD-covered (distinct, bounded signatures;
      muted → no-op).
- [x] Wired into the lazy/mute-aware audio path; triggers on idle/mastery/false-mark
      edges; no call-site outside `src/audio/` changes shape.
- [x] Ambient bed enriched (param-level), still mute-aware + lazy.
- [x] `bun run verify` green + `bun run e2e` PASS.
- [x] Chosen gains/durations recorded in tech-decisions §4/§7; **human on-device
      listen flagged** as the remaining verification (not done headless).

## Resolution (2026-06-17)

Shipped TDD-first (13 new tests in `src/audio/markAudio.test.ts`, written red then
made green — full suite 613 passing).

**Pure params (`src/audio/markAudio.ts`):**
- `DogFoleyEvent = 'idle-pant' | 'mastery-bark' | 'false-huff'` + `foleyLayers(event)`
  returning bounded `SoundSpec[]`:
  - `idle-pant` — two soft sine puffs (300/340 Hz, 70/60 ms, gain 0.04/0.03)
  - `mastery-bark` — bright two-syllable triangle bark (520/430 Hz, 90/110 ms, gain 0.22/0.18)
  - `false-huff` — single low short sine huff (170 Hz, 70 ms, gain 0.12)
  All gains sit well under the 0.9 PERFECT praise tone (annoyance budget); played
  sequentially like `masterySound`.
- `ambientLayers()` — three low detuned partials (160 / 163 / 240 Hz; 163 gives a
  ~3 Hz beat shimmer, 240 a soft fifth), summed gain ~0.095. `ambientSpec()` now
  delegates to `ambientLayers()[0]` (one source of truth).

**Playback shell:** added `MarkAudio.playFoley(event)` (mute-aware + lazy, mirrors
`playMastery`); `startAmbient`/`stopAmbient` rebuilt around `_ambientOscs: OscillatorNode[]`
to drive the multi-partial bed.

**Triggers (`src/main.ts`):** `mastery-bark` layered on the mastery jingle;
`false-huff` after a `FALSE_MARK`; `idle-pant` throttled to `PANT_INTERVAL_MS = 7000`
and gated to `dogVisualState(...) === 'idle'`. No existing audio call-site changed shape.

**Decision recorded** in `.docs/tech-decisions.md` → "Dog Foley + Ambient Bed —
DECIDED (2026-06-17, task 094)".

**Verification:** `bun run verify` green (613 tests, build no warnings), `bun run e2e`
PASS (smoke + full-loop). **Remaining manual step (not headless-verifiable, precedent
074): a human on-device listen** to confirm the foley is subtle, pleasant, and never
masks the praise tone.
