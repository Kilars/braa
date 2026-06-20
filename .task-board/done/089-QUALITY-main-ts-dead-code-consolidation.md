# QUALITY: Consolidate dead code & duplication in main.ts

**Status**: ✅ Done (2026-06-17)
**Created**: 2026-06-17

> **Outcome:** (1) Dead `getPhrase` removed from both `HudCallbacks` (`hud.ts`)
> and `main.ts` — `grep getPhrase src/` is now empty. (2) `getStats` uses
> `totalMasteredCount(roster)` (no inline reduce). (3) Resolved by task 091 —
> the graduation path now uses `graduationTrickIds(...)`, so the duplicated
> `STARTER_TRICKS.map(t => t.id)` is gone (verified absent). (4) New
> `BASE_SCHEDULER_TIMING` const in `gameHelpers.ts` consumed by both
> `buildSchedulerCfg` and `main.ts`'s initial config; `2000`/`800` now live in
> one place. No behaviour change — full suite green with no test edits.

**Priority**: Medium (readability / maintainability)
**Labels**: quality, refactor, cleanup, main.ts
**Estimated Effort**: Small

## Context & Motivation

`src/main.ts` has accumulated small duplications and one dead callback that the
last scan verified. None change behaviour; all are low-risk, test-backed
readability wins that reduce the chance of the three save/scheduler spellings
drifting apart.

Verified findings:
1. **Dead `getPhrase` callback** — `main.ts:375` implements `getPhrase()` and
   `hud.ts:18` declares it on the props interface, but nothing ever **calls**
   it (grep: only the declaration + the implementation, no call site).
2. **`getStats` re-implements `totalMasteredCount`** — `main.ts:543` reduces
   `roster` by `masteredTrickIds.length`, which is exactly the imported
   `totalMasteredCount(roster)` (`app/gameHelpers.ts`).
3. **`STARTER_TRICKS.map(t => t.id)` duplicated** at `main.ts:517` and `:522`
   (the graduation path). *(Note: task 091 reworks this path to
   `graduationTrickIds(...)`; if 091 lands first this item may already be
   resolved — verify and skip if so.)*
4. **Scheduler base constants duplicated** — `attemptInterval: 2000,
   activeSpan: 800` appear both in the initial `SCHEDULER_CFG` literal
   (`main.ts:50`) and inside `buildSchedulerCfg` (`gameHelpers.ts:56`). One
   source of truth avoids silent drift.

## Desired Outcome

`main.ts` is free of the dead callback and the duplicated reduce; the scheduler
base timing has a single named source. No behaviour change — the full existing
suite (589 tests) and e2e stay green throughout.

## Affected Components

### Files to Modify
- `src/ui/hud.ts` — drop `getPhrase` from the `HudCallbacks` interface.
- `src/main.ts` — delete the `getPhrase()` impl; use `totalMasteredCount(roster)`
  in `getStats`; consume the shared scheduler-timing constant.
- `src/app/gameHelpers.ts` (or `core/scheduler.ts`) — export a
  `BASE_SCHEDULER_TIMING` (`{ attemptInterval: 2000, activeSpan: 800 }`) used by
  both `buildSchedulerCfg` and the `main.ts` initial config.

## Technical Approach

This is a **behaviour-preserving refactor**; the existing test suite is the
guard (no new behaviour to TDD). Where a pure helper is touched
(`buildSchedulerCfg`), its existing tests must stay green. Run `bun run verify`
after each step.

### Before
```ts
// main.ts — dead callback
getPhrase() {
  return { phrase: loadedPhrase, lastUsedAt };
},

// main.ts — getStats re-implements totalMasteredCount
getStats() {
  const tricksMastered = roster.reduce(
    (sum, dog) => sum + dog.masteredTrickIds.length, 0,
  );
  return { prestigePoints, coins: profile.coins, level: profile.level, tricksMastered, streak };
},

// main.ts — magic numbers also in gameHelpers.buildSchedulerCfg
let SCHEDULER_CFG: SchedulerConfig = {
  attemptInterval: 2000,
  activeSpan: 800,
  ...difficulty.scheduler,
  distractorRate: 0,
};
```

### After
```ts
// hud.ts — getPhrase removed from the interface (no call site)

// main.ts — getStats reuses the pure helper
getStats() {
  return {
    prestigePoints,
    coins: profile.coins,
    level: profile.level,
    tricksMastered: totalMasteredCount(roster),
    streak,
  };
},

// gameHelpers.ts — single source of truth
export const BASE_SCHEDULER_TIMING = { attemptInterval: 2000, activeSpan: 800 } as const;
export function buildSchedulerCfg(...) {
  return { ...BASE_SCHEDULER_TIMING, ...roundDifficulty.scheduler, distractorRate: ... };
}

// main.ts — consume the shared constant
let SCHEDULER_CFG: SchedulerConfig = {
  ...BASE_SCHEDULER_TIMING,
  ...difficulty.scheduler,
  distractorRate: 0,
};
```

## Risks & Considerations
- **Sequence with 091**: item 3 overlaps the graduation rework in task 091. If
  091 is done first, re-verify item 3 and skip if already gone — do not reintroduce
  `STARTER_TRICKS.map`.
- **`getPhrase` removal** must drop it from both the interface and the impl, and
  confirm no hud-internal usage (grep first). `Phrase`/loadout state is still read
  via `getLoadoutState`, which stays.
- Pure no-op refactor: any test that goes red means a behaviour changed — stop
  and reassess rather than editing the test to pass.

## Acceptance Criteria
- [x] `grep -rn getPhrase src/` returns nothing after the change (interface + impl both gone).
- [x] `getStats().tricksMastered` is computed via `totalMasteredCount(roster)` (no inline reduce).
- [x] Scheduler base timing (`2000`/`800`) is defined once (`BASE_SCHEDULER_TIMING`) and consumed by both `main.ts` and `buildSchedulerCfg`.
- [x] No behaviour change: full existing suite stays green (596) with no test edits to "make it pass".
- [x] `bun run verify` green (typecheck + 596 tests + build no warnings); `bun run e2e` green (smoke + full-loop).
