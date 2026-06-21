# REFACTOR: Home the last stray timing/balance literals in the tuning module

**Status**: DONE (2026-06-21, iteration 23) · **Priority**: Low
**Finishes**: task `110-REFACTOR-consolidate-balance-knobs-tuning` (and `105`) — the stated
goal that `src/core/tuning.ts` is the **single home** for balance/timing constants.

## Delivered
`RESULT_FLASH_MS = 700` moved from `src/ui/hud.ts` into `src/core/tuning.ts` (new "HUD UX
timing" section) and imported in `hud.ts` — same value, no behavior change; `hud.ts` had no
prior tuning import. Audited `src/ui/` + `src/render/` for other stray literals. **Kept local
(judgement calls, noted):**
- `rewardPulse.ts WINDOW_MS = 500` and `masteryFlourish.ts WINDOW_MS = 1200` — render-animation
  decay windows already single-sourced within their own pure leaf modules; centralising them
  would add a core→render import for no "one place to tune" win.
- `hud.ts:591 setTimeout(…, 600)` — paired with a CSS `just-unlocked` transition duration; local
  easing, not a balance knob.
- `scene.ts MODEL_BUDGET_MS = 10_000` (load timeout, infra) and `backdrop.ts GND_SIZE = 256`
  (texture resolution) — not balance/timing tunables.

`RESULT_FLASH_MS` is referenced only in `hud.ts` (grep-clean; no test hard-codes `700`), so the
suite stays green with no test-expectation edits.

---


## What
Tasks 105/110 centralized balance knobs into `src/core/tuning.ts`, but a scan found a
stray timing literal that escaped the sweep: `RESULT_FLASH_MS = 700` is still defined
locally in `src/ui/hud.ts:20`. It is a tunable UX-timing value (how long the mark
result flash holds) and per tech-decisions belongs in the tuning module with the other
named constants — keeping "one place to tune" honest and discoverable.

## Scope
- Move `RESULT_FLASH_MS` into `src/core/tuning.ts` and import it in `hud.ts`.
- **Audit pass:** grep `src/ui/` and `src/render/` for other un-homed numeric
  timing/balance literals that are genuine tunables (durations, thresholds, multipliers)
  and migrate the clear ones. **Do not** migrate values that are intrinsically local and
  not balance knobs (e.g. one-off layout pixels, easing magic that only reads in place) —
  note any judgement calls in this file. This is a readability/centralization pass, not a
  hunt to relocate every number.

## Out of scope
- Renaming or re-tuning any value (pure move — same number, new home).
- Refactoring `hud.ts` structure beyond the import swap.

## Technical Approach
```ts
// BEFORE — src/ui/hud.ts
const RESULT_FLASH_MS = 700;

// AFTER — src/core/tuning.ts (grouped with the other UX-timing constants, documented)
/** How long the post-mark result flash holds before clearing (HUD). */
export const RESULT_FLASH_MS = 700;

// AFTER — src/ui/hud.ts
import { RESULT_FLASH_MS } from '../core/tuning';
```
This is non-functional code (a constant move, no behavior change), so it is **not** a
TDD task — the existing suite is the regression guard: the value is unchanged, so every
test that depended on the 700ms flash timing must stay green with zero edits. Confirm no
test hard-codes a duplicate `700` that should now reference the constant.

## Done when
- `RESULT_FLASH_MS` (and any other clearly-tunable literals found in the audit) live in
  `tuning.ts`, imported where used; no behavior change.
- A grep confirms no remaining stray balance/timing literal in `src/ui/` or `src/render/`
  that should have been centralized (or the file notes why a given literal stays local).
- `bun run typecheck` · `bun run test` · `bun run build` · `bun run e2e` green (unchanged
  behavior → suite green with no test edits beyond import/reference tidy).

## Acceptance criteria
- [ ] `RESULT_FLASH_MS` moved to `tuning.ts` and imported in `hud.ts` (same value).
- [ ] Audit grep of `src/ui/` + `src/render/` for stray tunable literals; clear ones
      migrated, judgement calls (kept-local) noted in this file.
- [ ] No behavior change — full suite green without altering test expectations.
- [ ] Full verify gate green (typecheck · test · build · e2e).
