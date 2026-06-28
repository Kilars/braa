# FEATURE: Leave and come back — persist per-trick progress + pause/resume (P2-5)

**Status**: Done (2026-06-27)
**Created**: 2026-06-27
**Priority**: P2 — Phase-2 core; makes the game snackable (depends on 016's learned progress existing)
**Labels**: phase-2, game-logic, persistence, tdd, indexeddb
**Depends on**: 016 (the per-trick progress store + `toJSON()` snapshot this saves). Relates to X-7 (offline).

## Context & Motivation

Phase-2 story **P2-5 — Leave and come back:** *"As a player, I want to pause or quit and
return with my per-trick progress intact, so that the game is snackable."* Acceptance:
- **Per-trick learned progress persists** (introduces **IndexedDB** save).
- **Pause/resume** supported; **no timer forces play** (Round States).

Task 016 adds the in-memory per-trick learned bar but it resets every reload. This task makes
it **durable**: the progress store hydrates from IndexedDB on boot and persists on change, so
closing the tab and reopening keeps each trick's learned/mastered state. It also adds a light
**pause/resume** so the player can step away mid-session without the ambient sit loop running
on (and without any timer pressuring them — there is no countdown in this game by design).

This also advances cross-cutting **X-7 (fully offline-capable):** saves are **local only**
(IndexedDB), no backend, no account — progress survives offline and across sessions.

## Desired Outcome

Reload the app and the learned bars are exactly where you left them, per trick (Sitt's fill,
Ligg's fill, mastered flags). A **pause** control freezes the dog's loop and the scene; **resume**
continues cleanly (no snap, no lost progress, no penalty for the gap). Persistence is resilient:
a missing/blocked/corrupt store degrades to a clean empty start (never a crash) — matching how
the scene/audio degrade headlessly. No network is required at any point (X-7).

## Affected Components

### Files to Add
- `src/core/save.ts` — pure, DOM-free (de)serialization: a versioned `SaveV1` shape,
  `serialize(snapshot)` and `deserialize(raw)` with validation (unknown/old/corrupt → empty).
  No IndexedDB here — just the pure, testable codec.
- `src/core/save.test.ts` — failing-first codec invariants (TDD, red first).
- `src/app/saveStore.ts` — thin async IndexedDB adapter: `load(): Promise<SaveV1 | null>` /
  `save(snapshot): Promise<void>`, with a **graceful no-op fallback** when `indexedDB` is absent
  or throws (headless / private mode), so boot never blocks (mirrors the scene's `ready:false`).

### Files to Modify
- `src/core/progress.ts` (from 016) — accept a hydrated snapshot (the `initial` ctor arg already
  planned in 016) and expose `toJSON()` for the codec. (No behavior change to the reducer.)
- `src/main.ts` — on boot, `await saveStore.load()` → `deserialize` → seed `createProgressStore`
  before first paint; after each progress change, debounce-persist `serialize(store.toJSON())`;
  wire a pause/resume control to freeze/resume the scene loop.
- `src/render/scene.ts` — add `pause()` / `resume()` (stop/restart the render loop, holding the
  shared clock so resume doesn't jump the cadence), or expose enough for `main.ts` to gate it.
- `src/app/shell.ts` + `src/style.css` — a small pause/resume control in the portrait layout,
  clear of the BRA tap path (X-2); `:focus-visible` + `aria`; reduced-motion safe.

## Technical Approach (TDD — codec is pure game-logic, test-first per the `tdd` skill)

### Before — progress is in-memory only; reload loses everything
```ts
// main.ts
const progress = createProgressStore() // always starts empty
```

### After — hydrate on boot, persist on change, through a pure versioned codec
```ts
// src/core/save.ts (NEW) — pure, deterministic, unit-tested
import type { TrickProgress } from './progress'

export const SAVE_VERSION = 1
export interface SaveV1 {
  version: 1
  tricks: Record<string, TrickProgress> // keyed by TrickId
}

/** Serialize a progress snapshot to a stable, versioned plain object. */
export function serialize(tricks: Record<string, TrickProgress>): SaveV1 {
  return { version: SAVE_VERSION, tricks }
}

/**
 * Parse a persisted value back to a snapshot. Anything unrecognized — null, wrong
 * version, missing/garbled fields — yields an EMPTY snapshot (a clean start), so a
 * corrupt or stale save can never crash boot or smuggle in bad state.
 */
export function deserialize(raw: unknown): Record<string, TrickProgress> {
  // validate shape + version + per-trick {learned in [0,1], mastered:boolean}; else {}
}
```
```ts
// src/app/saveStore.ts (NEW) — IndexedDB with a no-op fallback
export interface SaveStore {
  load(): Promise<unknown> // raw; main.ts pipes through deserialize
  save(snapshot: SaveV1): Promise<void>
}
export function createSaveStore(dbName = 'bra'): SaveStore {
  if (typeof indexedDB === 'undefined') return { async load() { return null }, async save() {} }
  // ... minimal IDB open + single 'progress' key get/put, wrapped so any error → no-op
}
```
```ts
// main.ts — boot hydration + debounced persist
const saveStore = createSaveStore()
const seed = deserialize(await saveStore.load())
const progress = createProgressStore(seed)
shell.setLearned(progress.get(scene.activeTrickId()).learned) // reflect hydrated state
// after each progress.apply: debounce → saveStore.save(serialize(progress.toJSON()))
```

### Tests to write first (red → green)
```ts
// save.test.ts
it('round-trips a snapshot through serialize/deserialize', () => {
  const snap = { sitt: { learned: 0.6, mastered: false }, ligg: { learned: 1, mastered: true } }
  expect(deserialize(serialize(snap))).toEqual(snap)
})
it('stamps the current version', () => {
  expect(serialize({}).version).toBe(SAVE_VERSION)
})
it('returns an empty snapshot for corrupt / null / wrong-version input', () => {
  expect(deserialize(null)).toEqual({})
  expect(deserialize('garbage')).toEqual({})
  expect(deserialize({ version: 999, tricks: { sitt: { learned: 0.5, mastered: false } } })).toEqual({})
  expect(deserialize({ version: 1, tricks: { sitt: { learned: 5, mastered: 'no' } } })).toEqual({})
})
```

### Pause/resume (light — no timer in the game by design)
- `pause()` stops the render loop and holds the shared clock; `resume()` restarts it so the sit
  cadence continues from where it paused (no jump, no penalty). "No timer forces play" is already
  true (the loop is ambient) — pause just lets the player step away cleanly. Keep it minimal.
- A thin e2e: set progress via the tap path, reload, assert the bar's hydrated fill is non-zero
  (cross-checks the IDB round-trip end-to-end without sampling pixels).

## Risks & Considerations
- **Async boot without a primitive flash (P1-1).** Awaiting IDB before first paint must not show
  a blank/broken frame — the scene already "holds neutral until assembled, then fades in"; seed
  progress before reflecting it on the bar, and keep `load()` fast (single key) with a no-op
  fallback so a slow/absent IDB never blocks the dog appearing.
- **Corrupt/stale saves never crash (X-7 resilience).** `deserialize` is the firewall — validate
  hard, default to empty. The IDB adapter wraps every call so a blocked DB (private mode) is a
  no-op, not an exception.
- **Versioning.** Stamp `version: 1` now; `deserialize` drops unknown versions to empty. This is
  the migration seam for future fields (don't over-build it — one version today).
- **Local only, offline (X-7).** No network, no account, no backend. IndexedDB on the device is
  the whole store.
- **Don't regress 015/016.** Persistence wraps the progress store; it must not change the
  reducer, the bar's feel, or the scoring/seated-tail fix. Keep the codec a pure leaf.
- **Scope discipline.** Pause/resume stays light (freeze/continue); this is not the Phase-2
  anti-mash (P2-6) nor any economy — just durable progress + a clean step-away.

## Acceptance Criteria
- [x] **TDD, red first:** `save.test.ts` covers round-trip, version stamp, and corrupt/null/
      wrong-version/out-of-range → empty snapshot.
- [x] `src/core/save.ts` is a pure, versioned codec; `src/app/saveStore.ts` is a thin IndexedDB
      adapter with a graceful no-op fallback (no `indexedDB` or any error → safe no-op).
- [x] On boot, `main.ts` hydrates `createProgressStore` from the persisted snapshot before
      reflecting it; after each scored OK/PERFECT it debounce-persists the new snapshot.
- [x] Reloading the app preserves each trick's learned/mastered state (verified end-to-end).
- [x] Pause/resume freezes and cleanly continues the scene loop with no lost progress, no cadence
      jump, and no timer pressure; the control sits clear of the BRA tap path (X-2).
- [x] Fully offline: no network request is required for save/load or gameplay (X-7); headless
      boot stays green (no-op store).
- [x] Verify gate green: `typecheck` 0 · `test` · `build` no-warnings · `e2e`.

## Completion Notes (2026-06-27)

**Shipped exactly to the planned seams.**
- **Pure codec** `src/core/save.ts` (`SAVE_VERSION`, `SaveV1`, `serialize`/`deserialize`) —
  TDD red→green, 8 tests. `deserialize` is the firewall: all-or-nothing validation (one bad
  per-trick field rejects the whole save), null/non-object/array/wrong-version/out-of-range →
  `{}`. Returns a freshly-built snapshot so a mutated result never reaches the input.
- **IndexedDB adapter** `src/app/saveStore.ts` — single-key get/put, `onupgradeneeded` creates
  the `progress` store, `onblocked`/`onerror`/`onabort` and a `typeof indexedDB === 'undefined'`
  early-out all degrade to a no-op (null load / silent save). Boot never blocks on storage.
- **`main.ts`** — `start()` is now async: the scene is built first (dog reveals immediately,
  no primitive flash), then `deserialize(await saveStore.load())` seeds `createProgressStore`
  before the bar reflects it. Debounced (300 ms) persist on each scored OK/PERFECT; `flushSave()`
  cancels the debounce (used on `visibilitychange → hidden` and by e2e). Taps are gated while
  paused (no hidden scoring).
- **`scene.ts` pause/resume** — a shared `clockOffset` "holds the clock": `pause()` stops the
  render loop and records the wall instant; `resume()` advances the offset by the paused gap so
  the cadence continues from exactly where it froze (no jump). State is shared by the live and
  headless handles, so the control reflects paused state even with no GPU.
- **`shell.ts` + `style.css`** — a small round pause/resume control top-right (chip visual
  language, shared focus ring), clear of the BRA cluster (X-2); paused → solid control + a
  static scene dim (no motion, X-5). Visual sanity check on 390×844 confirmed placement +
  legibility for both states.

**Discrepancy / note:** several pre-existing timing specs (`learned.spec.ts` 016, `loop.spec.ts`
006) are flaky under heavy parallel load — the test-side `waitForFunction(HOLD)` → `dispatchEvent`
tap loses the ~200 ms scoring window when the Babylon capture specs saturate CPU (the dispatch
arrives in RELEASE/IDLE → stray MISS/NONE). They pass in isolation; adding 2 more heavy e2e tipped
them red in-suite. Fixed at the source for all three timing specs (learned/loop/persist) by
extracting a shared **`e2e/_tap.ts` → `landMark(page)`**: it spins for HOLD and dispatches the tap
in the *same* in-page turn, so no CDP round-trip can elapse between the phase check and the tap —
exactly like a real player's tap (no cross-process hop). Assertions unchanged; the P2-4 test now
runs in ~24 s instead of ~1.1 min and the suite is reliably green, not green-on-a-lucky-run.

**Gate green:** `typecheck` 0 · `test` 77 (was 69; +8 codec) · `build` clean (no warnings) ·
`e2e` 13/13.
