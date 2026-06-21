# TEST: Resume round-trip — partial learned-bar survives save → serialize → deserialize → restore

**Status**: DONE (2026-06-21, iteration 23) · **Priority**: Medium

## Delivered
Added a `resume round-trip` integration `describe` to `src/app/gameHelpers.test.ts` (4 tests)
exercising the real `buildGameSave → serialize → deserialize → restoreLearnedBar` chain (no
mocks): a 42% partial bar survives a serialize/deserialize cycle and restores to 42; a fresh
save (no in-progress round) restores to 0; a saved partial bar is **not** mis-applied when the
resumed dog **or** trick differs. The existing persistence code round-trips correctly — the guard
passed on first run (a pure characterization guard; **no source bug surfaced**, so no red phase).
`gameHelpers.test.ts` 46 → **50 tests**. Note: `savedBar`/`learnedBar` are on a **0–100 percent**
scale (clamped in `restoreLearnedBar`), not 0–1 — the task's illustrative `0.42` was corrected to
`42` in the implementation.

---


## What
Spec §Round States promises: *"Resumable: a round can be left at any time; partial
learned-bar progress **persists**."* The pieces are unit-tested in isolation —
`buildGameSave` and `restoreLearnedBar` (`src/app/gameHelpers.ts`), and
`serialize`/`deserialize` shape + per-field backward-compat (`src/state/save.test.ts`).
But **no test exercises the full resume chain end-to-end**:

```
mid-round (partial bar) → buildGameSave → serialize → deserialize → restoreLearnedBar
                                                                        ↑ partial bar still there?
```

A regression in any link (a field dropped from `GameSave`, a key renamed, a default that
silently clobbers the saved bar) would **silently discard a player's partial progress on
restart** — the most frustrating failure mode for a casual save-anywhere game — and the
current suite would stay green. This task adds the missing integration guard. Pure logic;
no Babylon, no DOM, no IndexedDB driver (use the existing in-memory `serialize`/
`deserialize` pair).

## Out of scope
- Re-testing what `save.test.ts` already covers (field-by-field backward-compat).
- The IndexedDB storage driver itself (`IndexedDbStorage`) — bypass it; the round-trip is
  about the pure save/restore data path, not the persistence backend.

## Technical Approach (TDD — `tdd` skill)
Add an integration `describe` block (in `src/app/gameHelpers.test.ts`, beside the existing
`buildGameSave`/`restoreLearnedBar` unit tests). Build a save *as if mid-round* with a
partial learned bar, push it through the real serialize/deserialize pair, restore, and
assert the partial bar (and the round identity it belongs to) survives byte-for-byte.

```ts
// NEW — integration round-trip (illustrative; mirror the real param shapes)
describe('resume round-trip — partial learned-bar persists', () => {
  it('restores the same partial bar after serialize → deserialize', () => {
    const save = buildGameSave({ /* …roster, coins, xp…, */
      learnedBar: 0.42, activeDogId: /* … */, activeTrickId: /* … */ });

    const restored = deserialize(serialize(save));      // the real persistence path
    expect(restored).not.toBeNull();

    const bar = restoreLearnedBar({ save: restored!, /* …dog, trick… */ });
    expect(bar).toBeCloseTo(0.42);                      // ← the spec promise
  });

  it('resumes at 0 (fresh) when no round was in progress', () => { /* … */ });
  it('does not resume a partial bar onto a different dog/trick', () => { /* … */ });
});
```
Follow the red-green-refactor loop: write one failing assertion, make it pass against the
real `buildGameSave`/`restoreLearnedBar`/`serialize`/`deserialize` (do **not** mock them —
the point is the integration), then add the next slice. If a genuine bug surfaces (a field
not round-tripping), fix the source minimally and note it in this file.

## Done when
- New integration tests prove the partial learned-bar survives the full
  buildGameSave → serialize → deserialize → restoreLearnedBar chain.
- Edge cases covered: fresh (no in-progress round → 0) and mismatched dog/trick
  (a saved partial bar is not mis-applied to a different round).
- Tests are behavior-level (public functions only) so they survive refactors.
- `bun run typecheck` · `bun run test` · `bun run build` · `bun run e2e` green.

## Acceptance criteria
- [ ] Failing test first: a 0.42 partial bar round-tripped through serialize/deserialize
      then restored must equal ~0.42 (currently unguarded).
- [ ] Test: fresh save with no in-progress round restores to 0.
- [ ] Test: a saved partial bar is not applied when the active dog/trick differs.
- [ ] Tests use the real `buildGameSave`/`serialize`/`deserialize`/`restoreLearnedBar`
      (no mocks) — true integration.
- [ ] Any source bug surfaced is fixed minimally and noted here.
- [ ] Full verify gate green (typecheck · test · build · e2e).
