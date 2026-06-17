# QUALITY: Remove vestigial GameSave.masteredTrickIds + dead save/import code

**Status**: Backlog
**Created**: 2026-06-17
**Priority**: Medium
**Labels**: quality, refactor, persistence, dead-code, correctness-hazard
**Estimated Effort**: Small

## Context & Motivation

CLAUDE.md mandates a readability-first, single-way-of-doing-things codebase. A
code-quality scan found a **schema-drift correctness hazard** plus several dead
exports/imports that imply public API or critical-path code where none exists.
None of these is currently user-visible, but the `GameSave.masteredTrickIds`
field is a real trap: it lives in the save interface and the `deserialize` `Pick`
constraint (implying it matters), is **always written as `[]`**, and is **never
read on load** — the actual per-dog mastery lives in `roster[n].masteredTrickIds`.
Any future code that trusts the top-level field gets garbage. Clearing this drift
now keeps the save schema honest before more save fields accrete.

## Current State (all verified by code read + grep)

- **Vestigial field** — `src/state/save.ts:12` declares `masteredTrickIds:
  string[]` on `GameSave`; `src/app/gameHelpers.ts:110` always writes
  `masteredTrickIds: []`; `main.ts` never reads `save.masteredTrickIds`.
  `deserialize` (`save.ts:37`) lists it in its required `Pick<…>`. Per-dog mastery
  (`roster[n].masteredTrickIds`) is the real, working persistence path.
- **Dead save functions** — `serialize`/`deserialize` (`save.ts:31,35`) are
  imported **only** by `save.test.ts`. Production persists via
  `IndexedDbStorage` (`state/storage.ts`) which stores the object directly (no
  JSON), so these are dead in production.
- **Dead imports in entry point** — `main.ts:16` imports `isPhraseUnlocked`
  (never called); `main.ts:25` imports `effectiveDistractorRate` (never called in
  main.ts — only used internally inside `gameHelpers.buildSchedulerCfg`).
- **Scaffolding test** — `src/core/example.test.ts` tests inline `clamp`/`progress`
  lambdas that are not part of the codebase (initial Vitest smoke test).
- **Duplicated starter-roster literal** — the `{ id: 'rex', name: 'Rex', breedId:
  STARTER_BREED.id, masteredTrickIds: [] }` dog appears both in `save.ts:7`
  (`STARTER_ROSTER`) and as the default roster fallback in `main.ts` (~:71).

## Desired Outcome

The save schema reflects only fields that are actually written **and** read; the
entry point has no dead imports; obvious scaffolding is gone; the starter-roster
literal has one source of truth. **No behavior change** — saves written by the
current build still load (back-compat), and the full game plays identically.

## Affected Components

### Files to Modify
- `src/state/save.ts` (+ `save.test.ts`) — remove `masteredTrickIds` from
  `GameSave` and the `deserialize` `Pick`; decide `serialize`/`deserialize` fate
  (see Approach); export `STARTER_ROSTER`.
- `src/app/gameHelpers.ts` — stop writing `masteredTrickIds: []` in
  `buildGameSave`.
- `src/main.ts` — drop the two dead imports; import `STARTER_ROSTER` for the
  default-roster fallback instead of re-declaring it.
- `src/core/example.test.ts` — delete.

### Dependencies
- **Internal**: touches save load/serialize. Independent of tasks 074/075.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions
- **Back-compat first.** `deserialize`/load must still accept **old** saves that
  contain a top-level `masteredTrickIds` — simply ignore the field, don't choke on
  it. Removing it from the `GameSave` type is fine because extra JSON keys are
  harmless; just don't *require* it in the `Pick`. Add/keep a test that loads a
  legacy blob (with the field) and succeeds.
- **`serialize`/`deserialize`:** prefer **keep but stop implying critical-path** —
  the cleanest minimal change is to leave the functions (they have real tests and
  are harmless) but remove the dead `masteredTrickIds` requirement from them. If
  the scan's stronger recommendation is taken (delete them as dead production
  code), do so only together with their tests. **Pick one and state it in the
  Progress Log.** Default: keep them, de-vestigialize the field.
- **Pure refactor.** Every change is type/structure only; no game logic changes.
  Lean on the existing suite as the regression net and add the legacy-load test.

### Behaviours to test (TDD where behavior exists)
1. **Legacy-load back-compat** (`save.test.ts`): deserializing a JSON blob that
   *includes* a top-level `masteredTrickIds` still returns a valid `GameSave`
   (field ignored, all other fields intact, roster preserved).
2. **Round-trip** without the field: a save built by `buildGameSave` (no
   `masteredTrickIds`) serializes/deserializes with roster mastery intact.
3. Existing `save.test.ts` / `gameHelpers.test.ts` assertions updated to not
   require the removed field, and otherwise still green.

### Implementation Steps
1. **Tests first**: add the legacy-load back-compat test (1) and the
   no-field round-trip test (2) — they should pass once the field is removed;
   write them red against the intended shape, then make changes green.
2. Remove `masteredTrickIds` from `GameSave` (`save.ts:12`) and from the
   `deserialize` `Pick` (`save.ts:37`); ensure `deserialize` still tolerates the
   key being present in input.
3. Remove `masteredTrickIds: []` from `buildGameSave` (`gameHelpers.ts:110`); fix
   `gameHelpers.test.ts` expectations.
4. Export `STARTER_ROSTER` from `save.ts`; replace the duplicated literal in
   `main.ts` with the import.
5. Delete the dead imports in `main.ts` (`isPhraseUnlocked`,
   `effectiveDistractorRate`) and delete `src/core/example.test.ts`.
6. **Verify**: full gate green.

## Before / After Examples

### Example 1: de-vestigialize the save schema
**Before** (`src/state/save.ts`):
```ts
export interface GameSave {
  profile: Profile;
  masteredTrickIds: string[];   // always [] — never read on load
  idleTimestamp: number;
  // …
}
// deserialize:
const parsed = JSON.parse(raw) as Partial<GameSave> &
  Pick<GameSave, 'profile' | 'masteredTrickIds' | 'idleTimestamp'>;
```
**After**:
```ts
export interface GameSave {
  profile: Profile;
  idleTimestamp: number;
  // … (per-dog mastery lives on roster[n].masteredTrickIds)
}
// deserialize still tolerates a legacy top-level masteredTrickIds in the JSON,
// it just isn't part of the type or the required Pick:
const parsed = JSON.parse(raw) as Partial<GameSave> &
  Pick<GameSave, 'profile' | 'idleTimestamp'>;
```

### Example 2: stop writing the dead field + single starter-roster source
**Before** (`src/app/gameHelpers.ts:108–122`):
```ts
return {
  profile: params.profile,
  masteredTrickIds: [],            // dead
  idleTimestamp: params.now,
  roster: params.roster,
  // …
};
```
**After**:
```ts
return {
  profile: params.profile,
  idleTimestamp: params.now,
  roster: params.roster,
  // …
};
```
**Before** (`src/main.ts` import block):
```ts
import { isPhraseUnlocked, /* … */ } from './core/phrases'; // isPhraseUnlocked unused
import { effectiveDistractorRate, /* … */ } from './app/gameHelpers'; // unused in main
```
**After**: both dead names dropped from the imports; `STARTER_ROSTER` imported from
`./state/save` and used for the default-roster fallback.

## Risks & Considerations
- **Risk:** breaking load of existing saves. Mitigation: the legacy-load test (1)
  pins back-compat; removing a field from a type does not stop JSON with extra keys
  from parsing.
- **Risk:** a hidden consumer of the removed field. Mitigation: grep confirms only
  `buildGameSave` writes it and nothing reads it; the type removal will surface any
  missed reader as a compile error (that's the point).
- **Scope discipline:** the scan listed many more dead exports (audio internals,
  `round.markAt`/`isMastered`, payout constants, etc.). **Out of scope** here —
  this task is limited to the save-schema hazard + the entry-point dead imports +
  example.test.ts. Note the rest for a future quality round to avoid a sprawling
  diff.

## Code References
- `src/state/save.ts:7,12,31,35,37` — `STARTER_ROSTER`, vestigial field,
  serialize/deserialize.
- `src/app/gameHelpers.ts:108–122` — `buildGameSave` writes the dead field.
- `src/main.ts:16,25,~71` — dead imports + duplicated starter-roster literal.
- `src/core/example.test.ts` — scaffolding to delete.
- `src/state/storage.ts` — the real persistence path (stores object directly).

## Progress Log
- 2026-06-17 — Task created (scan round 7). Code-quality scan confirmed:
  `GameSave.masteredTrickIds` always `[]`/never read (per-dog roster is canonical);
  `serialize`/`deserialize` imported only by tests; `isPhraseUnlocked` +
  `effectiveDistractorRate` dead imports in main.ts; `example.test.ts` is
  scaffolding; starter-roster literal duplicated in save.ts + main.ts.
- 2026-06-17 — Implemented. Decision: **kept `serialize`/`deserialize`** (de-vestigialized).
  They have real back-compat tests, zero harm in keeping them; removing would require
  deleting all save.test.ts back-compat tests. The `deserialize` return was switched
  from `{ ...parsed, <defaults> }` to explicit field-by-field construction so a legacy
  blob's top-level `masteredTrickIds` key is silently dropped rather than re-introduced.
  `STARTER_ROSTER` exported from save.ts; main.ts uses `[...STARTER_ROSTER]` for the
  default roster (spread to avoid aliasing). Dead imports `isPhraseUnlocked` and
  `effectiveDistractorRate` confirmed unused (grep: only appeared in import lines and a
  comment) and removed. `example.test.ts` deleted. All `GameSave` typed literals in
  save.test.ts, gameHelpers.test.ts, and storage.test.ts updated to drop the removed
  field. `bun run verify` → ✓ typecheck + tests + build (564 tests).

## Acceptance Criteria

- [x] `GameSave.masteredTrickIds` removed from the interface and the `deserialize`
      `Pick`; `buildGameSave` no longer writes it. Per-dog mastery
      (`roster[n].masteredTrickIds`) unchanged and still the source of truth.
- [x] **Back-compat test (test-first):** deserializing a legacy save blob that
      includes a top-level `masteredTrickIds` still loads successfully with all
      other fields + roster mastery intact.
- [x] Dead imports `isPhraseUnlocked` and `effectiveDistractorRate` removed from
      `main.ts`; `STARTER_ROSTER` exported from `save.ts` and reused for the
      default-roster fallback (no duplicated literal).
- [x] `src/core/example.test.ts` deleted.
- [x] `serialize`/`deserialize` decision recorded in the Progress Log (kept &
      de-vestigialized, or deleted with their tests).
- [x] No behavior change: the game plays identically and current saves still load.
- [x] `bun run typecheck`, `bun run test`, `bun run build`, `bun run e2e` all green.

## Resolution

Save schema de-vestigialized: the always-`[]`, never-read top-level
`GameSave.masteredTrickIds` is removed (per-dog `roster[n].masteredTrickIds`
remains the canonical mastery store). `deserialize` rebuilt with explicit fields so
legacy saves carrying the old key load fine but don't re-introduce it (back-compat
test A1 + field-removed test A2 both green). Entry point cleaned: dead
`isPhraseUnlocked` / `effectiveDistractorRate` imports dropped, `STARTER_ROSTER`
single-sourced from save.ts, scaffolding `example.test.ts` deleted.
`serialize`/`deserialize` kept (real tests, harmless). No behavior change; verify
green (564 tests).

---

**Done** — moved to `.task-board/done/`.
