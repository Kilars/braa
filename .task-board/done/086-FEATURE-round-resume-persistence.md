# FEATURE: Persist partial learned-bar so a round resumes where it was left

**Status**: Backlog
**Created**: 2026-06-17
**Priority**: High
**Labels**: feature, persistence, core-loop, tdd, spec-gap
**Estimated Effort**: Medium

## Context & Motivation

specs.md §Round States is explicit: *"Resumable: a round can be left at any time;
partial learned-bar progress **persists**. Pause/resume supported."* and §Overview:
*"progress is saved and resumable at any time."* This is a **verified v1 spec gap**:
`GameSave` (`src/state/save.ts:10–28`) has **no** field for the in-progress round
(no `activeTrickId`, no `activeRoundDogId`, no `learnedBar`). Only mastered tricks
(via `roster[].masteredTrickIds`) are saved. So a player who quits a round at 70%
returns to **0%** — directly contradicting the "snackable, resumable" promise that
is core to the product's session shape.

This is the highest-impact actionable functional gap (the Pokémon-GO visuals epic
is blocked on an owner asset gate, so this iteration builds non-gated v1 value).

## Current State

- `state.session` (the live `Session`) holds `learned` (0–100), `mastered`, etc.
  A fresh round always starts at `learned = 0` — see the round-start wiring in
  `src/main.ts` (`onSelectTrick` / round setup) and `src/core/session.ts`.
- `persist()` (`src/main.ts:211`) writes a `GameSave` via `buildGameSave(...)` on
  every meaningful action, but the payload contains nothing about the active round.
- On load (`src/main.ts:86–136`) the app rebuilds profile/roster/kennel and lands on
  the select screen with no notion of an in-flight round.

## Desired Outcome

The single in-progress round (dog + trick + partial bar) **persists across quit /
reload**. When the player next starts that **same** dog+trick round, the learned bar
**resumes** from the saved value instead of 0. Starting a *different* round, or
mastering / leaving the trick, behaves as today. Old saves without the new fields
load unchanged (forward-compatible defaults).

## Affected Components

### Files to Modify
- `src/state/save.ts` — add three optional fields to `GameSave` + default them in
  `deserialize` (back-compat). Extend `buildGameSave` input in
  `src/app/gameHelpers.ts` to accept the active-round snapshot.
- `src/app/gameHelpers.ts` — `buildGameSave(...)` gains `activeRound` params; add a
  **pure** `restoreLearnedBar(...)` helper (the testable core).
- `src/main.ts` — `persist()` captures the current `(dogId, trickId, learned)`;
  round-start initializes `session.learned` via `restoreLearnedBar(...)`; mastery /
  leaving clears the snapshot.

### Files to Create
- `src/app/gameHelpers.test.ts` already exists — add the `restoreLearnedBar` cases
  there (keep the pure helper co-located with `buildGameSave`).

## Technical Approach

### Architecture Decisions
- **One active partial round at a time.** Track only the most-recently-left round
  `(activeRoundDogId, activeTrickId, learnedBar)`. This faithfully satisfies the
  spec's "a round can be left at any time; progress persists" for the dominant case
  (close mid-round → reopen → resume) without a per-(dog,trick) progress map.
- **Pure decision, impure save.** The resume rule is a pure function
  (`restoreLearnedBar`) covered by TDD; the `persist()`/load wiring is glue.
- **Forward-compatible.** New fields are optional and default cleanly so legacy
  saves (the back-compat test in `save.test.ts`) still load — same pattern as the
  `bestCombo` / `streak` fields added before.

### Behaviours to test (TDD — write the failing test first, see `.claude/skills/tdd/SKILL.md`)
1. `restoreLearnedBar` returns the **saved bar** when start dog+trick **match** the
   saved active round.
2. Returns **0** when the dog **or** trick differs from the saved round.
3. Returns **0** when there is no saved active round (`savedTrickId === null`).
4. Clamps a malformed saved bar into `[0, 100]` (robustness against bad saves).
5. `buildGameSave(...)` includes `activeRoundDogId` / `activeTrickId` / `learnedBar`
   in its output.
6. `deserialize` defaults the three fields (`null` / `null` / `0`) for an old save
   string that lacks them, and round-trips them when present.

### Implementation Steps
1. TDD `restoreLearnedBar` through behaviours 1–4 (pure; in `gameHelpers`).
2. TDD the `GameSave` schema extension (behaviours 5–6) in `save.test.ts` /
   `gameHelpers.test.ts`.
3. Wire `persist()` to snapshot the live round; wire round-start to seed
   `session.learned` from `restoreLearnedBar`; clear the snapshot on mastery and on
   leaving to a *different* trick.
4. Manually sanity-check (dev build): start a round → tap to ~50% → reload → re-enter
   the same dog+trick → bar resumes; pick a different trick → starts at 0.

### Before / After

```ts
// save.ts — BEFORE (no active-round fields)
export interface GameSave {
  profile: Profile; idleTimestamp: number; /* …existing… */ lastPlayedYmd: string;
}

// save.ts — AFTER (+ in-progress round, optional/back-compat)
export interface GameSave {
  profile: Profile; idleTimestamp: number; /* …existing… */ lastPlayedYmd: string;
  /** Dog id of the round in progress, or null if none. Defaults null for old saves. */
  activeRoundDogId: string | null;
  /** Trick id of the round in progress, or null if none. Defaults null for old saves. */
  activeTrickId: string | null;
  /** Partial learned-bar (0–100) of the in-progress round. Defaults 0 for old saves. */
  learnedBar: number;
}
```

```ts
// gameHelpers.ts — NEW pure helper
export function restoreLearnedBar(args: {
  savedDogId: string | null; savedTrickId: string | null; savedBar: number;
  startDogId: string; startTrickId: string;
}): number {
  const match = args.savedTrickId !== null
    && args.savedDogId === args.startDogId
    && args.savedTrickId === args.startTrickId;
  if (!match) return 0;
  return Math.min(100, Math.max(0, args.savedBar));
}
```

## Risks & Considerations
- **Don't break legacy saves** — keep fields optional with defaults; the existing
  back-compat deserialize test must stay green.
- **Clearing on mastery** — once the trick is mastered the snapshot must be cleared
  so re-practicing that trick starts fresh (re-practice is a separate, full round).
- **Switch-dog mid-round** — ensure leaving a round to adopt/switch doesn't strand a
  stale snapshot that wrongly resumes an unrelated round (covered by behaviours 2–3).

## Acceptance Criteria
- [x] `restoreLearnedBar` is pure and TDD-covered (match / dog-mismatch /
      trick-mismatch / no-saved-round / clamp) — failing test written first.
- [x] `GameSave` carries `activeRoundDogId` / `activeTrickId` / `learnedBar`;
      `deserialize` defaults them for old saves (back-compat test green).
- [x] `persist()` snapshots the live round; round-start seeds the bar via
      `restoreLearnedBar`; mastery + leaving-to-a-different-trick clear the snapshot.
- [x] Quitting/reloading mid-round and re-entering the **same** dog+trick resumes the
      bar; a different round starts at 0 (manual dev-build sanity check noted).
- [x] Full verify gate green: `bun run typecheck` · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

## Resolution (2026-06-17)

Implemented test-first (12 new tests, RED → GREEN).
- `src/state/save.ts` — `GameSave` gains `activeRoundDogId` / `activeTrickId` /
  `learnedBar`; `deserialize` defaults them (`null`/`null`/`0`) so legacy saves
  load unchanged (back-compat test green).
- `src/app/gameHelpers.ts` — pure `restoreLearnedBar(...)` (returns the clamped
  0–100 saved bar only on a dog+trick match, else 0) + the three optional params
  on `buildGameSave`.
- `src/main.ts` — module-scoped `activeRoundDogId` / `activeRoundTrickId` track the
  live round (null on the select screen). `persist()` snapshots `(dogId, trickId,
  session.learned)` only while training; `onSelectTrick` seeds `session.learned`
  from the boot-time snapshot via `restoreLearnedBar` (skipped for already-mastered
  re-practice rounds); the mastery edge clears the snapshot so a mastered trick
  never resumes. Bootstrap saves persist nulls (not mid-round).
- `save.test.ts` / `storage.test.ts` — `GameSave` literals updated for the new
  required fields.

**Verify:** `verify ●●● ✓ typecheck + tests + build (585 tests)` (independently
re-run by the main agent). Full e2e gate run at iteration end. Non-visual — no
Visual Review needed.
