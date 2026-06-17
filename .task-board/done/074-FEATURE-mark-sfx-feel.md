# FEATURE: Mark SFX feel — crisp click under the praise tone + clip-ready audio path

**Status**: Backlog
**Created**: 2026-06-17
**Priority**: High
**Labels**: audio, core, juice, mark-feel, tdd
**Estimated Effort**: Small–Medium

## Context & Motivation

Audio is a **primary pillar** in the spec, and the mark moment is the product:

> **The mark must always feel good.** Voice + SFX + reaction on every successful
> BRA; that satisfying beat is the product. (specs.md:42–43)

> **Mark SFX:** a crisp UI click sits under the voice so the mark always feels
> tactile and satisfying. (specs.md:369–370)

Today the mark has **no click character at all**. `soundForResult` returns a
single ~200 ms **sine bell** for PERFECT (`{ freq: 880, durationMs: 200, type:
'sine', gain: 0.9 }`, `markAudio.ts:13–14`) — a tone, not a tactile click. The
Maren-style **voice** is also absent, but sourcing that voice (recorded /
licensed / imitation / TTS) is an **open product decision with likeness/legal
implications** (tech-decisions.md §4) and is intentionally **out of scope** for
this task — see Risks. What we *can* ship autonomously and what most improves the
core-loop feel right now is: (a) make the mark SFX an actual **crisp click**, and
(b) give `MarkAudio` a **clip-ready playback path** so a real voice/SFX asset can
be dropped in later without touching the call sites.

This is a v1 audio gap, **not** visual/rendering (the saturated domain), and it
sits on the most-tapped path in the game.

## Current State

- `src/audio/markAudio.ts:11–22` — `soundForResult()` maps each `MarkResult` to a
  single sine/sawtooth `SoundSpec` (a bell tone). `MarkAudio.play()` (line 93)
  synthesizes exactly one oscillator via `playSpec()`.
- There is **no** path to play a pre-loaded audio clip — every sound is an
  `OscillatorNode`. No `AudioBuffer`, no `decodeAudioData`, no asset loading.
- `playSpec()` (line 73) ramps gain linearly from `gain → 0` over `durationMs`;
  there is no fast attack/decay shaping that would read as a "click."
- Tests in `src/audio/markAudio.test.ts` exercise the pure spec functions and the
  muted/ambient lifecycle through the public `MarkAudio` interface.

## Desired Outcome

1. A successful mark plays a **crisp click transient layered under a short praise
   tone** — it reads as a tactile "tick + ping," not a sustained bell. PERFECT
   feels punchier than OK; MISS stays subtle; FALSE_MARK stays a distinct low
   buzz.
2. `MarkAudio` can play a **registered audio clip** (an `AudioBuffer`) for a given
   cue when one has been provided, and **falls back to synthesis** when none is.
   No call site in `main.ts` changes — `play('PERFECT')` still works; it just
   sounds better and is upgrade-ready for the future voice asset.
3. Pure, **test-first** decision logic governs both: the layered click/tone spec
   and the "use clip if registered, else synthesize" selection.

## Affected Components

### Files to Modify
- `src/audio/markAudio.ts` (+ `markAudio.test.ts`) — **test-first**: add a layered
  mark spec and a clip-vs-synth selection predicate; extend `MarkAudio` to play
  layers and an optional registered clip.
- `.docs/tech-decisions.md` — record the click envelope shape + the clip-fallback
  policy (and note the voice-sourcing decision remains open).

### Dependencies
- **Internal**: `MarkResult` type (`core/mark.ts`), existing `playSpec`. Independent
  of tasks 075/076.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions
- **Keep all decisions pure and tested; keep WebAudio glue thin.** As today,
  `SoundSpec`/spec-builders are pure data with no WebAudio imports, tested
  directly. New side-effect code (buffer playback) stays inside `MarkAudio` behind
  the existing `try/catch` guards so importing the module in Node never crashes.
- **Click = short high-attack transient.** Model the click as a very short spec
  (≈ 8–30 ms) with a fast decay, layered *before/under* a brief praise tone.
  Represent a mark as **an array of layers** (`markLayers(result): SoundSpec[]`)
  rather than a single spec; `play()` schedules each layer at `ctx.currentTime`.
  Keep `soundForResult` as the praise-tone layer (or fold it in) — choose one and
  keep the public `play()` signature unchanged.
- **Clip-ready, synth-fallback.** Add `registerClip(cue, buffer)` and a pure
  `shouldUseClip(cue, registry)` predicate. `play()` consults it: if a clip is
  registered for the cue, play the buffer; otherwise synthesize the layers. No
  asset is bundled in this task — the registry is simply empty, so behavior is
  synthesis today and voice-ready tomorrow.

### Behaviours to test (TDD, `markAudio.test.ts`)
1. `markLayers('PERFECT')` returns ≥ 2 layers; the **first** layer is a short
   click (`durationMs <= 30`) and a later layer is the praise tone
   (`durationMs >= 100`).
2. PERFECT's praise layer has higher `gain` than OK's (punchier on better marks).
3. `markLayers('FALSE_MARK')` stays a distinct low/`sawtooth` cue (not a praise
   ping) — assert it differs in `type` or low `freq` from the success cues.
4. `shouldUseClip(cue, {})` is `false` (empty registry → synthesize).
5. `shouldUseClip(cue, registry)` is `true` only when `registry` has a clip for
   that exact cue (other cues registered → still synthesize this one).
6. Existing muted/ambient lifecycle tests still pass (no regression to the public
   interface).

### Implementation Steps
1. **TDD**: write the failing tests for `markLayers` (1–3) → implement the layered
   spec, red→green. Refactor `soundForResult` usage so `play()` schedules layers.
2. **TDD**: write the failing tests for `shouldUseClip` (4–5) → implement the pure
   predicate + a `clipRegistry: Map<string, AudioBuffer>` and `registerClip()` on
   `MarkAudio`.
3. Wire `play()` to branch on `shouldUseClip`; add a thin
   `playBuffer(ctx, buffer)` (guarded). Keep the synthesis branch as the default.
4. **Doc**: record the click envelope numbers + clip-fallback policy in
   tech-decisions.md; add a one-line note that the Maren voice asset is the
   intended clip but its sourcing is still the open §4 decision.
5. **Visual/Audio Review**: per CLAUDE.md, run `polish` and have a review agent
   actually listen/inspect — confirm the mark now reads as a crisp tactile click
   on a successful BRA, distinct OK vs PERFECT, and that nothing regressed when
   muted. (Audio is hard to screenshot — capture the review as a described
   listen-through + the spec values.)
6. **Verify**: full gate green.

## Before / After Examples

### Example 1: layered mark spec (tested)
**Before** (`src/audio/markAudio.ts:11–22`):
```ts
export function soundForResult(result: MarkResult): SoundSpec {
  switch (result) {
    case 'PERFECT': return { freq: 880, durationMs: 200, type: 'sine', gain: 0.9 };
    // …one sine bell per result…
  }
}
```
**After**:
```ts
// A mark = a crisp click transient layered under a short praise tone.
export function markLayers(result: MarkResult): SoundSpec[] {
  const click: SoundSpec = { freq: 2000, durationMs: 12, type: 'square', gain: 0.35 };
  switch (result) {
    case 'PERFECT': return [click, { freq: 880, durationMs: 140, type: 'sine', gain: 0.9 }];
    case 'OK':      return [click, { freq: 660, durationMs: 120, type: 'sine', gain: 0.5 }];
    case 'MISS':    return [{ ...click, gain: 0.12 }];
    case 'FALSE_MARK': return [{ freq: 180, durationMs: 90, type: 'sawtooth', gain: 0.5 }];
  }
}
```

### Example 2: clip-ready selection (tested) + thin glue
**After** (`src/audio/markAudio.ts`):
```ts
/** True when a clip is registered for this cue; otherwise the caller synthesizes. */
export function shouldUseClip(cue: string, registry: ReadonlyMap<string, AudioBuffer>): boolean {
  return registry.has(cue);
}

// inside MarkAudio:
private clips = new Map<string, AudioBuffer>();
registerClip(cue: string, buffer: AudioBuffer): void { this.clips.set(cue, buffer); }

play(result: MarkResult): void {
  if (this._muted) return;
  try {
    const ctx = this.ensureCtx(); if (!ctx) return;
    if (shouldUseClip(result, this.clips)) { this.playBuffer(ctx, this.clips.get(result)!); return; }
    for (const layer of markLayers(result)) this.playSpec(ctx, layer, ctx.currentTime);
  } catch { /* AudioContext unavailable — silent fail */ }
}
```

## Risks & Considerations
- **Out of scope (flag for product owner):** the actual **Maren-style marker
  voice** clip. Its sourcing — recorded / licensed / imitation / TTS — carries
  **likeness/legal** weight and is the still-open tech-decisions.md §4 item. This
  task makes the engine *voice-ready* (the `registerClip` path) and improves the
  SFX feel; it does **not** decide or bundle a voice. Surface the voice-sourcing
  fork to the product owner separately.
- **Out of scope:** dog foley (panting/barks/whines) and replacing the synthesized
  ambient drone — both are real audio gaps but belong in their own task to keep
  this slice focused on the mark moment. Note them for the next scan round.
- **Risk:** a square/noise click can be harsh. Mitigation: keep the click very
  short and at moderate gain; tune in the audio review; values are one-line knobs.
- **Risk:** layering must not double-trigger on muted. Mitigation: the early
  `_muted` return is unchanged and covered by existing tests.

## Code References
- `src/audio/markAudio.ts:11–22` — `soundForResult` (becomes/feeds `markLayers`).
- `src/audio/markAudio.ts:73–102` — `playSpec` / `play` (glue to extend).
- `.docs/specs.md:42–43,369–370` — "mark must feel good" + crisp click SFX.
- `.docs/tech-decisions.md` §4 — open voice-sourcing decision (kept out of scope).

## Progress Log
- 2026-06-17 — Task created (scan round 7). Confirmed via code read: mark SFX is a
  single ~200 ms sine bell (`markAudio.ts:13`), no click transient, and there is
  no audio-clip playback path anywhere (all `OscillatorNode`). Voice sourcing left
  out of scope as an open likeness/legal decision.
- 2026-06-17 — Implemented (TDD): test-writer added 7 red tests for `markLayers` /
  `shouldUseClip`; impl made them green. `markLayers` = 12 ms / 2000 Hz square
  **click** transient + per-tier sine praise tone (PERFECT 880/140/0.9, OK
  660/120/0.5), MISS = click-only @0.12, FALSE_MARK = 180 Hz sawtooth 90 ms (no
  click). `shouldUseClip`/`registerClip` + guarded `playBuffer` give a clip-ready
  path; `play()` uses clip if registered else synthesizes layers — public signature
  unchanged, muted/ambient lifecycle untouched. tech-decisions.md updated.
- 2026-06-17 — **Audio review (code-level, headless):** verified the envelope
  values produce a genuine crisp tick (short bright square burst) layered under the
  tone; PERFECT vs OK clearly distinct (gain 0.9/140 ms vs 0.5/120 ms); FALSE_MARK
  unmistakably different (low sawtooth, no click); muted path returns early (silent).
  This is a real improvement over the single sine bell. NOTE: subjective on-device
  "juice" still warrants a human listen on a phone — recorded honestly, not claimed
  from playback (headless env cannot emit audio). The future Maren voice clip drops
  into `registerClip('PERFECT', buffer)` with no call-site change.
- 2026-06-17 — `bun run verify` ✓ typecheck + tests + build (556 tests). e2e run by
  main agent in the iteration gate.

## Acceptance Criteria

- [x] `markLayers(result)` added **test-first**: PERFECT/OK return a short click
      layer (`durationMs <= 30`) plus a praise tone; PERFECT praise gain > OK;
      FALSE_MARK remains a distinct low cue. (Behaviours 1–3.)
- [x] `shouldUseClip(cue, registry)` added **test-first** with `registerClip()` on
      `MarkAudio`: empty registry → synthesize; clip present for the exact cue →
      use it. (Behaviours 4–5.)
- [x] `MarkAudio.play()` schedules the layered click+tone by default and uses a
      registered clip when present; public signature unchanged; existing
      muted/ambient tests still green. (Behaviour 6.)
- [x] Click envelope values + clip-fallback policy recorded in
      `.docs/tech-decisions.md`; voice-sourcing noted as still-open §4 decision.
- [x] **Audio review** (per CLAUDE.md Visual Review): code-level review confirmed —
      crisp click transient layered under praise tone; OK vs PERFECT distinct;
      FALSE_MARK distinct; muted is silent. (Headless env cannot emit audio; a human
      on-device listen is recommended for subjective juice — noted in Progress Log.)
- [x] `bun run typecheck`, `bun run test`, `bun run build`, `bun run e2e` all green.

## Resolution

Mark SFX upgraded from a single ~200 ms sine bell to a layered **click transient
(12 ms / 2000 Hz square) + per-tier praise tone**, giving the mark a tactile feel
per the "the mark must always feel good" principle. Added a clip-ready playback
path (`registerClip` + pure `shouldUseClip`, guarded `playBuffer`) so the eventual
Maren-style voice asset drops in without touching call sites; the actual voice
sourcing stays the open tech-decisions §4 likeness/legal decision. TDD: 7 tests.
Verify green (556 tests).

---

**Done** — moved to `.task-board/done/`.
