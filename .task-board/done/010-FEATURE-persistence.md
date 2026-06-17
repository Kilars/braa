# FEATURE: Persistence — save/load profile (IndexedDB + in-memory) (TDD)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: High
**Labels**: state, game-logic, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec/tech: single-player, client-side save in **IndexedDB**, plus an **idle
timestamp** for the capped idle trickle. Progress must persist (no backend). We
want the save logic testable without a browser, so define a small `Storage`
interface with an in-memory impl (TDD) and a thin IndexedDB impl behind it.

## Current State

`src/state/` is empty. Economy (009) defines `Profile`.

## Desired Outcome

`src/state/` holds a `GameSave` type, pure (de)serialize functions, a `Storage`
interface, an `InMemoryStorage` (fully tested), and an `IndexedDbStorage` (browser
impl). The app can save and reload a profile + idle timestamp.

## Affected Components
- Create: `src/state/save.ts` (types + serialize/deserialize), `src/state/save.test.ts`,
  `src/state/storage.ts` (interface + InMemoryStorage + IndexedDbStorage), `src/state/storage.test.ts`
- Dependencies: internal `economy.ts` (`Profile`); Blocking: 009
- External: `fake-indexeddb` (dev) IF used to test the IndexedDB impl; otherwise
  test the interface via InMemoryStorage and flag the IndexedDB impl as
  integration-only.

## Interface (signatures only — bodies test-first)

```ts
export interface GameSave { profile: Profile; masteredTrickIds: string[]; idleTimestamp: number; }
export function serialize(save: GameSave): string;
export function deserialize(raw: string): GameSave;            // throws/falls back on bad data

export interface Storage { load(): Promise<GameSave | null>; save(s: GameSave): Promise<void>; }
export class InMemoryStorage implements Storage { /* ... */ }
export class IndexedDbStorage implements Storage { /* ... */ }
```

## Behaviors to test (each RED first)
- serialize→deserialize round-trips a GameSave exactly.
- deserialize on malformed input does NOT throw uncaught — returns null/default (decide, test it).
- InMemoryStorage.load returns null before any save.
- InMemoryStorage save then load returns the saved GameSave.
- idleTimestamp is preserved across save/load.
- (If fake-indexeddb available) IndexedDbStorage save/load round-trips too.

## Risks
- IndexedDB in node tests needs `fake-indexeddb`; if installing it is undesirable,
  test InMemoryStorage + serialize/deserialize thoroughly and mark the IndexedDB
  impl as needing a browser/integration check (state it in Resolution).

## Progress Log
- 2026-06-13 — Task created (iteration 3)
- 2026-06-13 — Implemented via TDD (tdd skill), all acceptance criteria met

## Resolution

Six RED→GREEN cycles completed in order:

1. **Cycle 1 — serialize/deserialize round-trip**: Wrote test first; RED (save.ts missing). Implemented `serialize` (JSON.stringify) and `deserialize` (JSON.parse wrapped in try/catch). GREEN.

2. **Cycle 2 — malformed input handling**: Added two tests (invalid JSON, empty string). Implementation already handled this via the try/catch from cycle 1 — tests went straight to GREEN. The behavior was already correct from cycle 1's minimal implementation; no code change needed.

3. **Cycle 3 — InMemoryStorage load null before save**: Wrote test; RED (storage.ts missing). Implemented `Storage` interface, `InMemoryStorage`, and `IndexedDbStorage` (full IndexedDB impl). GREEN.

4. **Cycle 4 — InMemoryStorage save then load**: Added test. GREEN immediately (InMemoryStorage correctly stores and returns the value).

5. **Cycle 5 — idleTimestamp preserved**: Added test. GREEN immediately (full object equality already tested in cycle 4; this isolates idleTimestamp explicitly).

6. **Cycle 6 — IndexedDbStorage round-trip**: Added `import 'fake-indexeddb/auto'` to storage.test.ts; `bun add -d fake-indexeddb` installed v6.2.5. Wrote three IndexedDB tests (load-before-save, round-trip, idleTimestamp). GREEN — fake-indexeddb polyfills `globalThis.indexedDB` in the Node test environment so the real `IndexedDbStorage` implementation runs without mocking.

**fake-indexeddb** was used successfully (v6.2.5). `IndexedDbStorage` is fully tested in Node via the polyfill — no browser/integration check needed for the storage logic. Final state: `bun run test` 107 tests (all green, 98 pre-existing + 9 new), `bun run typecheck` 0 errors.

## Acceptance Criteria
- [x] Written test-first (RED→GREEN per behavior) using the `tdd` skill
- [x] `serialize`/`deserialize` round-trip a GameSave; malformed input handled (no uncaught throw)
- [x] `InMemoryStorage`: load null before save; save→load returns the value; idleTimestamp preserved
- [x] `IndexedDbStorage` implemented (tested with fake-indexeddb v6.2.5 — full Node unit tests, not integration-flagged)
- [x] No Babylon imports; `save.ts` is pure (no DOM)
- [x] `bun run test` green; `bun run typecheck` clean
