# FEATURE: Marker-voice clip playback pipeline + phrase-keyed selection

**Status**: Done (2026-06-21)
**Created**: 2026-06-21 (iteration 24 scan)
**Priority**: Medium-High
**Labels**: audio, feel, gap:marker-voice, phrases
**Estimated Effort**: Medium

## Context & Motivation

specs.md §Audio names the **marker voice** a *defining* requirement, and §Design
Principles says **the mark must always feel good**. Today every mark plays a **synth
ping only** — `markLayers(result)` oscillators in `src/audio/markAudio.ts`. The
clip-playback *plumbing* exists (task 074 built `registerClip(cue, buffer)` +
`shouldUseClip(cue, registry)` + `playBuffer(...)`, and `play(result)` already prefers a
registered clip over synth — `markAudio.ts:107,154,164-173`) — **but nothing ever loads
or registers a clip**: `grep -n registerClip src/` finds only the definition, never a
call. So the entire voiced-mark path is dead code.

The **real Maren recording** is owner/likeness-gated (tech-decisions §4) and stays out of
scope. But the **owner-unblocked half is the whole pipeline**: a clip *loader*
(`fetch` + `decodeAudioData`), **phrase-keyed cue selection** so each collectible phrase
can voice its own line (specs §Audio: *"each has its own line"*), and a bundled
**placeholder** clip so the path is proven end-to-end and the real recording is a
drop-in. Audio is a **cold domain** (last audio task was 094; recent work is render /
refactor / test — all saturated).

## Current State

- `src/audio/markAudio.ts`:
  - `shouldUseClip(cue, registry)` → `registry.has(cue)` (pure, tested-able).
  - `class MarkAudio` has `private clips: Map<string, AudioBuffer>`, `registerClip(cue,
    buffer)`, `playBuffer(ctx, buffer)`, and `play(result)` which does
    `if (shouldUseClip(result, this.clips)) this.playBuffer(...)` **else** synth.
  - **No** `decodeAudioData`/loader; **no** phrase awareness — the cue is the result tier
    only (`'PERFECT'|'OK'|...`), so a per-phrase line can't be selected.
- `src/main.ts` — never calls `registerClip`; `markAudio.play(result)` at the mark
  (`main.ts:484`) has no `loadedPhrase` argument.
- No `public/audio/` directory yet.

## Desired Outcome

- A **clip loader** on `MarkAudio` — `loadClip(cue, url)` → `fetch(url)` →
  `ctx.decodeAudioData` → `registerClip(cue, buf)`. Lazy + mute-safe + **graceful**: a
  missing/failed asset rejects quietly and the mark falls back to the existing synth (no
  throw, no console spam, app unaffected).
- **Phrase-keyed cue selection** — a **pure** `voiceCue(result, phraseId?)` returning the
  cue to look up: prefer a phrase-specific key (e.g. `voice:flink`) when a clip is
  registered for it, else fall back to the result-tier key, else synth. `play(...)` takes
  an optional `phraseId` and uses `voiceCue` to pick the buffer.
- One bundled **placeholder** voice clip in `public/audio/` proving the end-to-end path
  (loaded at bootstrap, plays on a scoring mark). It is explicitly a **placeholder** —
  the real Maren line drops into the same cue with no call-site change. Document the
  owner gate (§4) in the task + tech-decisions; do **not** claim the voice is final.
- No regression to the existing synth mark when no clip is registered (the default until
  an asset loads), and **zero added tap latency** (loading is at bootstrap, off the tap path).

## Affected Components

### Files to Create / Modify
- `src/audio/markAudio.ts` (+ `markAudio.test.ts`):
  - Pure `voiceCue(result, phraseId?)` (TDD) — phrase key when present in registry, else
    tier key, else a sentinel meaning "synthesize".
  - `loadClip(cue, url)` method (fetch + decodeAudioData + registerClip; rejection-safe).
  - `play(result, phraseId?)` threads `phraseId` through `voiceCue`.
- `src/main.ts` — at bootstrap, `await`/fire-and-forget `markAudio.loadClip('PERFECT',
  '/audio/bra-placeholder.webm')` (+ any phrase keys); pass `loadedPhrase.id` into the
  mark-time `play(...)` call (`main.ts:484`).
- `public/audio/bra-placeholder.{webm|mp3}` — bundled placeholder clip (small; document
  provenance/CC0 or synthesized-original in `public/audio/CREDITS.md`).
- `scripts/` — if generating the placeholder programmatically, add a tiny generator
  script + note it; otherwise document the source. Must be license-clean (no Maren voice).
- `.docs/tech-decisions.md` — record the loader + `voiceCue` selection rule and re-state
  the Maren recording as the standing owner/likeness gate (§4).

### Dependencies
- **Internal**: existing `registerClip`/`shouldUseClip`/`playBuffer` (074). None blocking.
- **External / owner-gated (named, NOT in scope)**: the real Maren marker recording
  (tech-decisions §4 — likeness/recording asset, can't be produced autonomously). This
  task delivers the pipeline + a placeholder so that asset is a drop-in.

## Technical Approach

### Implementation Steps (TDD — `tdd` skill, vertical slices)
1. Pure `voiceCue(result, phraseId?)` — one test → impl → repeat:
   - returns the phrase key (`voice:<id>`) when given a `phraseId`,
   - returns the tier key (`result`) when `phraseId` is undefined,
   - selection is registry-aware at the `play` site (a key with no registered clip ⇒
     synth) — keep `voiceCue` pure (key derivation) and let `shouldUseClip` gate fallback.
2. `loadClip(cue, url)` — decode + register; a rejected fetch/decode leaves the registry
   unchanged (assert: after a failed load, `shouldUseClip(cue, registry)` is still false).
3. `play(result, phraseId?)` threads through `voiceCue` + `shouldUseClip`; synth path
   unchanged when nothing registered.
4. `main.ts` bootstrap load + mark-time `phraseId` argument; placeholder asset added.

### Before / After

**Before** (`src/audio/markAudio.ts` — clip path exists but is never fed, no phrase key):
```ts
play(result: MarkResult): void {
  // ...
  if (shouldUseClip(result, this.clips)) {
    this.playBuffer(ctx, this.clips.get(result)!);
    return;
  }
  for (const layer of markLayers(result)) { /* synth */ }
}
// registerClip is never called anywhere; no loader; no phrase awareness.
```

**After**:
```ts
// pure, tested
export function voiceCue(result: MarkResult, phraseId?: string): string {
  return phraseId ? `voice:${phraseId}` : result;
}

async loadClip(cue: string, url: string): Promise<void> {
  try {
    const ctx = this.ensureCtx();
    const buf = await ctx.decodeAudioData(await (await fetch(url)).arrayBuffer());
    this.registerClip(cue, buf);
  } catch { /* graceful: stay on synth, no throw */ }
}

play(result: MarkResult, phraseId?: string): void {
  // ...
  const cue = voiceCue(result, phraseId);
  if (shouldUseClip(cue, this.clips)) { this.playBuffer(ctx, this.clips.get(cue)!); return; }
  if (shouldUseClip(result, this.clips)) { this.playBuffer(ctx, this.clips.get(result)!); return; }
  for (const layer of markLayers(result)) { /* synth fallback */ }
}
```
```ts
// src/main.ts bootstrap (off the tap path) + mark-time call
markAudio.loadClip('PERFECT', '/audio/bra-placeholder.webm'); // fire-and-forget
// ...at the mark:
markAudio.play(result, loadedPhrase?.id);
```

### Risks & Considerations
- **Risk**: a missing asset throws and breaks the mark. **Mitigation**: `loadClip` is
  fully try/catch'd; `play` always has the synth fallback (covered by a test asserting a
  failed load leaves the registry empty).
- **Risk**: clip load adds tap latency. **Mitigation**: load at bootstrap, never on the
  tap; `play` only does a Map lookup.
- **Risk**: shipping a placeholder that reads as "the final voice". **Mitigation**: name
  it `*-placeholder*`, document the §4 owner gate, do not claim the voice is done.
- **Audio is not headless-verifiable** (precedent 074/094): the gate is the **pure
  selection/loader tests** (clip chosen when registered, synth otherwise, graceful on
  failure) + a code-level audio review. A human on-device listen of the placeholder is the
  one non-blocking follow-up; the **real Maren line stays the owner gate**.

## Acceptance Criteria

- [x] Pure `voiceCue(result, phraseId?)` added **test-first** via `tdd` (phrase key when
      id present; tier key otherwise).
- [x] `loadClip(cue, url)` loads + registers a clip and is **rejection-safe** — a test
      proves a failed load leaves `shouldUseClip(cue, registry)` false (mark stays synth).
- [x] `play(result, phraseId?)` uses a registered phrase clip when present, else the tier
      clip, else the existing synth — proven by tests (pure `selectVoiceClip` with a stubbed
      registry: phrase→tier→null; `play` headless-safe).
- [x] `main.ts` loads the bundled placeholder at bootstrap (off the tap path) and passes
      `loadedPhrase.id` into the mark-time `play(...)`; no added tap latency.
- [x] A license-clean placeholder clip is bundled under `public/audio/` with documented
      provenance (`bra-placeholder.wav` — synthesized original, `scripts/gen-voice-placeholder.mjs`,
      `public/audio/CREDITS.md`); the real Maren recording is named as the standing
      owner/likeness gate (tech-decisions §4) — **not** claimed as delivered.
- [x] Decision recorded in `.docs/tech-decisions.md` (§4a). **specs.md untouched.**
- [x] Full gate green: `bun run typecheck` (0) · `bun run test` (862) · `bun run build`
      (no warnings) · `bun run e2e`.

## Implementation Notes (resolution)

- New pure exports in `src/audio/markAudio.ts`: `voiceCue(result, phraseId?)` (cue-key
  derivation) and `selectVoiceClip(result, phraseId, registry)` (registry-aware
  phrase→tier→null decision). `MarkAudio` gains `hasClip(cue)` (observability seam),
  `loadClip(cue, url)` (rejection-safe loader), and `play(result, phraseId?)` now threads
  through `selectVoiceClip`. 13 new tests (`markAudio.test.ts`), TDD vertical slices.
- `main.ts` bootstrap: `void markAudio.loadClip('PERFECT', \`${import.meta.env.BASE_URL}audio/bra-placeholder.wav\`)`
  (fire-and-forget, off tap path); mark site passes `loadedPhrase.id`.
- **Feel note (non-blocking):** registering the placeholder under `PERFECT` means a perfect
  mark plays the synthesized placeholder chime instead of the synth praise tone — intentional,
  proves the path end-to-end. A human on-device listen + the real Maren line are the follow-ups.

---

**Technical approach hint**: the plumbing already prefers a clip over synth — the work is
(1) a rejection-safe loader, (2) a pure phrase-keyed cue selector, (3) wiring + a
license-clean placeholder. Keep the new *logic* pure and tested; keep the I/O thin and
graceful. Do not gold-plate into a phrase-voice catalog — one placeholder + the selection
seam proves the path; per-phrase lines drop in later with no call-site change.
