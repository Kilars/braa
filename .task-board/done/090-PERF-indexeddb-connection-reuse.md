# PERF/QUALITY: Reuse one IndexedDB connection instead of opening per operation

**Status**: ✅ Done (2026-06-17)
**Created**: 2026-06-17

> **Outcome:** `IndexedDbStorage.openDb()` now memoises the open in a
> `dbPromise` field; `load`/`save`/`clear` reuse one connection. A rejected open
> nulls the memo (retryable). TDD red→green: new `connection reuse` describe in
> `storage.test.ts` spies `indexedDB.open` and asserts 1 call across 4 ops
> (was 4), plus a reuse-then-clear round-trip. 9 storage tests green, behaviour
> unchanged. `InMemoryStorage` untouched.

**Priority**: Medium (persistence robustness)
**Labels**: perf, persistence, robustness, tdd
**Estimated Effort**: Small

## Context & Motivation

`IndexedDbStorage` (`src/state/storage.ts`) calls `await this.openDb()` at the
top of **every** `load()`, `save()`, and `clear()`. The game persists on most
state changes (every mark via `persist()`, mode switches, adopts, purchases,
streak/idle bootstrap), so a normal session opens and discards dozens of
`IDBDatabase` connections. Each `indexedDB.open()` is a fresh async round-trip;
churning connections is wasteful and, under rapid successive saves, needlessly
racy.

Caching a single connection is a cheap, well-contained robustness/perf win on a
core v1 system (persistence), with no API or save-format change.

## Desired Outcome

`IndexedDbStorage` opens the database **once** and reuses the connection for all
subsequent operations. Concurrent first-calls share a single in-flight open
(no double-open race). Behaviour is otherwise identical; all existing
`storage.test.ts` round-trips stay green.

## Affected Components

### Files to Modify
- `src/state/storage.ts` — memoise the `openDb()` promise.
- `src/state/storage.test.ts` — add coverage that repeated save/load reuse one
  connection and still round-trip correctly.

## Technical Approach

Persistence is testable logic → **test-first (TDD)**, per
[`.claude/skills/tdd`](../../.claude/skills/tdd/SKILL.md). `fake-indexeddb` is
already wired into the test env.

### Behaviours to test (TDD)
1. Two sequential `save()` then `load()` round-trip the latest value (existing
   behaviour preserved under reuse).
2. `openDb` is invoked **once** across multiple ops — assert via a spy/counter
   (e.g. count `indexedDB.open` calls, or wrap `openDb`) that N saves trigger a
   single open.
3. After `clear()`, a subsequent `load()` still works on the reused connection
   (connection is not closed out from under later ops).

### Before
```ts
private openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(this.dbName, 1);
    request.onupgradeneeded = () => request.result.createObjectStore(this.storeName);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async save(s: GameSave): Promise<void> {
  const db = await this.openDb();   // fresh connection every call
  ...
}
```

### After
```ts
private dbPromise: Promise<IDBDatabase> | null = null;

private openDb(): Promise<IDBDatabase> {
  // Memoise the first open; reuse the same connection for all later ops.
  // Concurrent first-callers share one in-flight promise (no double-open).
  this.dbPromise ??= new Promise((resolve, reject) => {
    const request = indexedDB.open(this.dbName, 1);
    request.onupgradeneeded = () => request.result.createObjectStore(this.storeName);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  return this.dbPromise;
}

async save(s: GameSave): Promise<void> {
  const db = await this.openDb();   // reused connection
  ...
}
```

## Risks & Considerations
- **Open failure caching**: if the first open rejects, null the memo so a later
  call can retry (don't cache a rejected promise permanently). Add a `.catch`
  that resets `dbPromise = null` on failure.
- **No `db.close()`** is introduced — the connection lives for the page lifetime,
  which is the intended behaviour for a single-tab PWA save store.
- Keep `InMemoryStorage` untouched.

## Acceptance Criteria
- [x] Failing test written first asserting a single `openDb`/`indexedDB.open` across multiple ops (TDD red → green).
- [x] `openDb()` memoises the connection; all of `load`/`save`/`clear` reuse it.
- [x] A rejected first open is not cached (retryable) — `.catch` nulls `dbPromise`.
- [x] Existing `storage.test.ts` round-trips remain green; behaviour unchanged.
- [x] `bun run verify` green; `bun run e2e` green (full gate at iteration end).
