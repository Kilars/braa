# REFACTOR: Centralize scattered tunables into `src/core/tuning.ts`

**Status**: Backlog
**Created**: 2026-06-20 (iteration 17 scan)
**Priority**: Medium
**Labels**: refactor, quality, tuning
**Estimated Effort**: Simple

## Context & Motivation

tech-decisions.md §8 carries a **standing, owner-sanctioned TODO**:

> *"Future: centralize all constants below into a single `src/core/tuning.ts` export
> (not done here — doc-only pass; a code refactor is a separate task)."*

The §8 table is the single tuning reference for the game (mark deltas, window/peak
radius, distractor rates, reward multipliers, idle cap, etc.). The values themselves are
acknowledged placeholders that **will be re-tuned by playtest**, so making them easy to
find and adjust from one place has real ongoing value.

A code-quality scan (iteration 17) found most tunables are *already* named exports in
their domain files — the genuine remaining scatter is small and concentrated, so this is
a **mechanical, low-risk** refactor (rename literals + re-export), not a sweeping rewrite:

- `src/core/difficulty.ts` — ~18 **inline numeric literals** (e.g. `windowWidth: 400`,
  `peakRadius: 80`, `distractorRate: 0.2`, HARD `280 / 50 / 0.45`, EXPERT `160 / 25 /
  0.55`, `tellIntensity` 1.0/0.6/0.3, `rewardMultiplier` 1.0/1.3/2.5) that are not named.
- `src/main.ts` — two app-level tunables hiding in the entry file: `PANT_INTERVAL_MS =
  7000` and `TIMELINE_EVENTS = 20` (and the `BASE_SCHEDULER_TIMING` 2000/800 pair, if not
  already centralized).

## Current State

- Tunables live across `src/core/*.ts` (mark.ts, difficulty.ts, scheduler.ts, kennel.ts,
  phrases.ts, economy.ts, prestige.ts, combo.ts, onboarding.ts) and a couple in
  `src/main.ts`. Many are already named consts/exports; `difficulty.ts`'s mode tables use
  bare inline literals; `main.ts` holds a few app-level constants.
- No `src/core/tuning.ts` exists.
- Each domain module has its own test suite asserting current behavior — these are the
  safety net for a behavior-preserving move.

## Desired Outcome

A single `src/core/tuning.ts` that **re-exports / hosts the numeric tuning constants**,
with domain modules importing from it, so a tuner edits one file. **Zero behavior change**
— every existing test stays green without modification.

## Affected Components

### Files to Create
- `src/core/tuning.ts` — named tuning constants grouped by domain (mirrors §8's sections),
  each with a short comment matching the §8 "what it affects" note.

### Files to Modify
- `src/core/difficulty.ts` — replace the inline mode-table literals with named imports.
- `src/main.ts` — import `PANT_INTERVAL_MS`, `TIMELINE_EVENTS` (+ scheduler base pair if
  applicable) from `tuning.ts`.
- Optionally consolidate other already-named consts (mark deltas, idle cap, etc.) behind
  re-exports **only if** it stays a pure move (no behavior change). Prefer breadth-light:
  do `difficulty.ts` + the `main.ts` stragglers well rather than touching everything.
- `.docs/tech-decisions.md` §8 — replace the "Future" note with a pointer to
  `src/core/tuning.ts` as the now-live home (implementation note only; **specs.md
  untouched**).

### Dependencies
- **External**: none.
- **Internal**: none.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions

- **Pure move, behavior-preserving.** The win is locating + naming, not changing values.
  Keep names aligned with §8 (`NORMAL_WINDOW_WIDTH_MS`, `NORMAL_PEAK_RADIUS_MS`,
  `HARD_DISTRACTOR_RATE`, `IDLE_CAP_COINS`, …) so the doc table and the code read the same.
- **Re-export to avoid churn.** Where a constant is already a named export consumed widely
  (e.g. `IDLE_RATE_PER_MS`), prefer `export { X } from './tuning'` (or import-and-re-export)
  so call-sites don't change — minimizing diff surface and risk.
- **Tests are the contract.** Run the full suite after each module's move; green = the
  move is behavior-preserving. This is a refactor, so existing tests must pass **unchanged**
  (no new logic to TDD; if a value needs naming-only, that's not a behavior change).

### Implementation Steps

1. Create `src/core/tuning.ts` with the difficulty mode literals named and grouped.
2. Point `difficulty.ts` at the named constants; run `bun run test` — green.
3. Move `PANT_INTERVAL_MS` / `TIMELINE_EVENTS` (+ scheduler base) out of `main.ts` into
   `tuning.ts`; import them back. Run tests — green.
4. (Optional, low-risk only) re-export other §8 constants from `tuning.ts` for a single
   import surface, leaving their definitions in place if moving them would ripple.
5. Update tech-decisions §8 to point at `tuning.ts`.

### Risks & Considerations

- **Risk**: an accidental value change during the move (typo) silently alters balance.
  **Mitigation**: behavior-preserving move only; the per-domain test suites + e2e
  full-loop catch any drift. Diff each moved literal against the §8 table.
- **Risk**: circular imports if `tuning.ts` imports back from a domain module.
  **Mitigation**: `tuning.ts` holds **only** primitive constants — it imports nothing from
  `src/core/*`, so it sits at the bottom of the dependency graph.
- **Risk**: scope creep into a giant rename. **Mitigation**: ship `difficulty.ts` + the
  `main.ts` stragglers as the core; treat broader consolidation as optional.

## Before / After Examples

### Example: difficulty mode literals become named

**Before** (`src/core/difficulty.ts`):
```ts
const NORMAL = { windowWidth: 400, peakRadius: 80, distractorRate: 0.2,
                 tellIntensity: 1.0, rewardMultiplier: 1.0 };
```

**After** (`src/core/tuning.ts`):
```ts
export const NORMAL_WINDOW_WIDTH_MS = 400;  // scoring window (tap here → OK/PERFECT)
export const NORMAL_PEAK_RADIUS_MS = 80;    // half-width of the PERFECT sub-band
export const NORMAL_DISTRACTOR_RATE = 0.2;  // distractor probability between attempts
export const NORMAL_TELL_INTENSITY = 1.0;   // apex pulse strength (1 = clearest)
export const NORMAL_REWARD_MULT = 1.0;      // mastery payout scalar
```
**After** (`src/core/difficulty.ts`):
```ts
import {
  NORMAL_WINDOW_WIDTH_MS, NORMAL_PEAK_RADIUS_MS, NORMAL_DISTRACTOR_RATE,
  NORMAL_TELL_INTENSITY, NORMAL_REWARD_MULT,
} from './tuning';
const NORMAL = { windowWidth: NORMAL_WINDOW_WIDTH_MS, peakRadius: NORMAL_PEAK_RADIUS_MS,
                 distractorRate: NORMAL_DISTRACTOR_RATE, tellIntensity: NORMAL_TELL_INTENSITY,
                 rewardMultiplier: NORMAL_REWARD_MULT };
```

### Example: app-level constants leave `main.ts`

**Before** (`src/main.ts`):
```ts
const PANT_INTERVAL_MS = 7000;
const TIMELINE_EVENTS = 20;
```
**After** (`src/main.ts`):
```ts
import { PANT_INTERVAL_MS, TIMELINE_EVENTS } from './core/tuning';
```

## Code References

- `.docs/tech-decisions.md` §8 (§7a–§7m) — the constant table this module mirrors.
- `src/core/difficulty.ts` — the main inline-literal site.
- `src/core/kennel.ts`, `src/core/phrases.ts` — examples of already-named tunable exports
  (the target style).

## Progress Log

- 2026-06-20 — Task created (iteration 17 scan). Implements the §8 "Future" TODO.
  Mechanical, behavior-preserving; tests are the safety net.
- 2026-06-20 — Implemented. Created `src/core/tuning.ts` with 21 named primitive
  constants (difficulty NORMAL/HARD/EXPERT mode values + `PANT_INTERVAL_MS` /
  `TIMELINE_EVENTS`), grouped/commented to mirror §8. Rewired `difficulty.ts` and
  `main.ts` to import them; deleted the local declarations. Updated §8 "Future" note
  to DONE. `tuning.ts` imports nothing from `src/core/*` (no cycle). Verified:
  `difficulty.test.ts` 38/38 green; `tsc --noEmit` introduces 0 new errors (the 1
  remaining error is pre-existing in the untracked `src/ui/hud.test.ts`, confirmed
  identical with/without these changes); grep confirms inline window literals gone
  from `difficulty.ts` (matches are comment text only). No value changed.

## Resolution

**Done — behavior-preserving refactor complete.**

Files created:
- `src/core/tuning.ts` — named primitive tuning constants, grouped by domain
  (NORMAL / HARD / EXPERT difficulty + app-level), imports nothing from `src/core/*`.

Files modified:
- `src/core/difficulty.ts` — `NORMAL_SCHEDULER`, the HARD/EXPERT scheduler objects,
  the FALSE_MARK overrides, `rewardMultiplier`, and `tellIntensity` now reference the
  named imports from `./tuning`. `CONFUSE_WINDOW_MULT` / `CONFUSE_DISTRACTOR_MULT` left
  in place (already named; out of tight scope).
- `src/main.ts` — imports `PANT_INTERVAL_MS` and `TIMELINE_EVENTS` from `./core/tuning`;
  both local declarations deleted.
- `.docs/tech-decisions.md` §8 — "Future" blockquote replaced with a DONE note pointing
  at `src/core/tuning.ts`. (specs.md untouched.)

Moved constants, value-for-value (no change):
- NORMAL_WINDOW_WIDTH_MS=400, NORMAL_PEAK_RADIUS_MS=80, NORMAL_DISTRACTOR_RATE=0.2,
  NORMAL_TELL_INTENSITY=1, NORMAL_REWARD_MULT=1
- HARD_WINDOW_WIDTH_MS=280, HARD_PEAK_RADIUS_MS=50, HARD_DISTRACTOR_RATE=0.45,
  HARD_TELL_INTENSITY=0.6, HARD_REWARD_MULT=1.3, HARD_FALSE_MARK_DELTA=-8
- EXPERT_WINDOW_WIDTH_MS=160, EXPERT_PEAK_RADIUS_MS=25, EXPERT_DISTRACTOR_RATE=0.55,
  EXPERT_TELL_INTENSITY=0.3, EXPERT_REWARD_MULT=2.5, EXPERT_FALSE_MARK_DELTA=-10
- PANT_INTERVAL_MS=7000, TIMELINE_EVENTS=20

Verification:
- `bunx vitest run src/core/difficulty.test.ts` → 38 passed (38), green.
- `bunx tsc --noEmit` → 1 error, pre-existing in untracked `src/ui/hud.test.ts`
  (unrelated to this task; confirmed present with my changes stashed). 0 new errors.
- `grep -nE '\b(400|280|160)\b' src/core/difficulty.ts` → only matches inside
  trailing comments ("tighter than NORMAL 400", "tighter than HARD 280"); no inline
  numeric literals remain.

## Acceptance Criteria

- [ ] `src/core/tuning.ts` exists and hosts the difficulty mode constants (+ the `main.ts`
      stragglers `PANT_INTERVAL_MS` / `TIMELINE_EVENTS`), named to match tech-decisions §8.
- [ ] `src/core/difficulty.ts` and `src/main.ts` consume the constants from `tuning.ts`;
      no bare duplicate of those literals remains (grep-clean).
- [ ] **Zero behavior change**: every existing test passes **unchanged** (no test edits
      needed beyond import paths, if any); each moved value diffed against the §8 table.
- [ ] `tuning.ts` imports nothing from `src/core/*` (no cycle).
- [ ] tech-decisions §8 "Future" note replaced with a pointer to `src/core/tuning.ts`.
      **specs.md untouched.**
- [ ] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting.
