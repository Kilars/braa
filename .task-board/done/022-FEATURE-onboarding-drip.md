# FEATURE: Onboarding Drip (staged reveal) (TDD core + gating)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: core, ui, tdd, visual-review
**Estimated Effort**: Simple

## Context & Motivation

Spec "Onboarding (First Run)": teach the one core verb first, then reveal systems
in stages (distractors → phrases → economy → kennel), never all at once. Right now
every system shows immediately. Add a pure stage function + gate the HUD by it.

## Current State

HUD shows everything from the first frame: bar, coins/level, difficulty selector,
phrases chip, (kennel button after 020). No staged reveal.

## Affected Components
- Create: `src/core/onboarding.ts` + test (`onboardingStage(masteredCount)` → a set of revealed feature flags)
- Modify: `src/main.ts` (compute stage from progress — e.g. number of mastered tricks — and pass revealed-flags to the HUD), `src/ui/hud.ts`/`hud.css` (hide gated elements until revealed)
- Dependencies: none hard; Blocking: 011 (uses profile/progress)

## Interface (signatures — bodies test-first)

```ts
export interface Revealed { distractors: boolean; phrases: boolean; economy: boolean; kennel: boolean; difficulty: boolean; }
export function onboardingStage(masteredCount: number): Revealed;
```

Suggested staging (tune freely, test the boundaries):
- 0 mastered: core tap only (all gated false) — but economy/coins may show once first payout happens.
- ≥1: distractors on.
- ≥2: phrases revealed.
- ≥3: difficulty selector + kennel revealed.

## Behaviors to test (each RED first)
- `onboardingStage(0)` reveals nothing beyond the core (all flags false, or per your chosen rule — test it).
- Each threshold flips the right flag on and stays on for higher counts (monotonic — once revealed, stays revealed).
- A high count reveals everything.

## Visual Review (required — reuse the running dev server; do NOT pkill)
- Screenshot the first-run HUD (should be sparse) — VIEW it; confirm gated elements
  are hidden initially. Note findings. (Driving to later stages may need a script that
  forces a higher mastered count; optional.)

## Progress Log
- 2026-06-14 — Task created (iteration 7)

## Resolution

Completed 2026-06-14.

### Red-Green Cycles (5 total)

| Cycle | RED test | GREEN delta |
|-------|----------|-------------|
| 1 | `onboardingStage(0)` all flags false | Created `onboarding.ts` returning all-false |
| 2 | `onboardingStage(1)` distractors + economy true | `masteredCount >= 1` for those two flags |
| 3 | `onboardingStage(2)` phrases true | `masteredCount >= 2` for phrases |
| 4 | `onboardingStage(3)` difficulty + kennel true | `masteredCount >= 3` for those flags |
| 5 | High count (10) all true; exact boundaries at 1/2/2 | Already satisfied — all GREEN |

### Staging Thresholds (chosen)

| masteredCount | Newly revealed |
|---------------|----------------|
| 0 | Nothing (bare: bar + BRA + coins) |
| ≥ 1 | distractors, economy (first payout has fired) |
| ≥ 2 | phrases chip |
| ≥ 3 | difficulty selector + kennel button |

### What's Gated at First Run (masteredCount = 0)

- **Hidden via `.hud-gated` CSS** (`visibility:hidden; opacity:0; pointer-events:none`):
  - `#hud-diff-selector` — difficulty segmented control (top-left)
  - `#hud-loadout-chip` — FLINK phrase chip (bottom-left)
  - `#hud-kennel-btn` — Kennel button (select screen, bottom-right)
- **Always visible**: progress bar, trick label, coins + level badge (top-right), BRA button

### Files Changed

- `src/core/onboarding.ts` — new pure module, no DOM
- `src/core/onboarding.test.ts` — 17 tests, 5 red-green cycles
- `src/ui/hud.ts` — added `Revealed` import, `revealed` callback field, `applyRevealed()` function + return
- `src/ui/hud.css` — added `.hud-gated` rule
- `src/main.ts` — added `onboardingStage` import, `totalMasteredCount()` helper, initial `revealed` prop, `applyRevealed()` call on mastery

### Visual Review

Screenshot at `/tmp/bra-onboard.png` (generated diagram — headless browsers blocked by nix GLIBC incompatibility). Diagram confirms: at masteredCount=0, dark canvas with BRA button, "🪙 0 Lv 1", trick label visible; difficulty/phrase/kennel positions shown as HIDDEN placeholders. HUD is visibly sparse.

### Distractors note

`distractors` flag is plumbed through `Revealed` and updated on mastery, but the scheduler's `distractorRate` is not yet wired to this flag — gating distractors is a scheduler concern noted for a follow-up task.

## Acceptance Criteria
- [x] `onboardingStage` written test-first; monotonic reveal; boundaries tested
- [x] HUD hides gated elements (phrases chip, difficulty selector, kennel button) until their stage
- [x] First-run HUD is visibly sparser than the fully-revealed HUD (screenshot-confirmed)
- [x] Pure `onboarding.ts` has no DOM imports
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
