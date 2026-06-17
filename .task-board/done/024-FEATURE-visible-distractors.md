# FEATURE: Visible Distractors + onboarding/​trick wiring (TDD + render)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: core, render, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Distractors exist in the timeline but are INVISIBLE — the dog looks idle during a
distractor, so the player has no "wrong behavior" to resist. The whole "catch the
right behavior, don't mark distractors" mechanic needs the dog to visibly perform
a distractor. Also wire `distractorRate` to onboarding (0 until revealed) + the
active trick (023).

## Current State

`dogVisualState` → idle/offering/confused/happy (no distractor). `onboarding.distractors`
flag is computed but unused. Scheduler emits distractor events but they read as idle.

## Affected Components
- Modify: `src/core/scheduler.ts` (add `distractorActiveAt(timeline, now): boolean`) + test
- Modify: `src/render/dogState.ts` (add `'distractor'` to `DogVisual`; precedence mastered>confused>offering>distractor>idle) + test
- Modify: `src/render/scene.ts` (render a distinct 'distractor' look — e.g. dog turns away / different tint, clearly NOT the markable cue)
- Modify: `src/main.ts` (gate `distractorRate` by `onboarding.distractors`; combine with the trick profile from 023)
- Dependencies: `scheduler.ts`, `dogState.ts`, `onboarding.ts`, `tricks.ts`; Blocking: 015, 022, 023

## Behaviors to test (each RED first)
- `distractorActiveAt` true within a distractor event's span, false otherwise / on empty timeline.
- `dogVisualState` returns 'distractor' when a distractor is active and not confused/mastered/offering.
- Precedence: a correct attempt ('offering') wins over a distractor if both somehow overlap; mastered/confused still win.
- With `onboarding.distractors` false → effective `distractorRate` is 0 (no distractors before reveal).

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Enter training, capture a frame where a distractor is active (poll `dogVisualState`/a
  data attribute, or screenshot a few frames). VIEW the PNG; confirm the distractor look
  is visibly DIFFERENT from the 'offering' (markable) look so the player can tell them apart.

## Progress Log
- 2026-06-14 — Task created (iteration 8)

## Resolution

### Red-green cycles

**Cycle 1 — `distractorActiveAt` empty timeline** (scheduler.test.ts)
- RED: imported non-existent `distractorActiveAt` → `TypeError: distractorActiveAt is not a function`
- GREEN: added `distractorActiveAt(timeline, now): boolean` to scheduler.ts iterating distractor events

**Cycle 2 — `distractorActiveAt` span boundary + attempt non-match** (scheduler.test.ts)
- Added 6 tests: at/within/outside activeStart/activeEnd, and attempt events return false
- All passed immediately with the existing implementation — no code change needed

**Cycle 3 — `dogVisualState` returns `'distractor'`** (dogState.test.ts)
- RED: `expected 'idle' to be 'distractor'`
- GREEN: added `'distractor'` to `DogVisual` union; added `distractorActiveAt` check in precedence chain after `'offering'`

**Cycle 4 — Distractor precedence** (dogState.test.ts)
- 3 tests: offering-wins-over-distractor, confused-wins-over-distractor, mastered-wins-over-distractor
- All green immediately (precedence order in the `if` chain handles this)

### Distractor visual

Flat neutral grey (`Color3(0.55, 0.55, 0.55)`), no emissive glow, scale 0.9 (slightly withdrawn), sphere shifted right (+0.35 X) and lowered (-0.1 Y) — reads as the dog turning/leaning away. Screenshot captured at `/tmp/bra-distractor.png`.

Contrast with `offering`: warm tan/golden tint with a subtle emissive glow, scale 1.1, centered — the markable cue. The difference is visually unambiguous (grey cowering away vs. warm bright centered).

### `distractorRate` gating

Added `effectiveDistractorRate()` and `buildSchedulerCfg()` helpers in `main.ts`:
- `effectiveDistractorRate()` calls `onboardingStage(totalMasteredCount())` — returns 0 if `revealed.distractors` is false (< 1 mastered), otherwise uses `roundDifficulty.scheduler.distractorRate` (which already incorporates mode + trick's `distractorBonus` from task 023).
- `buildSchedulerCfg()` spreads `roundDifficulty.scheduler` then overrides `distractorRate` with the gated value.
- All three `SCHEDULER_CFG` rebuild sites (save-load, setMode, onSelectTrick) now call `buildSchedulerCfg()`.
- Module-level initial `SCHEDULER_CFG` also sets `distractorRate: 0` explicitly (before IIFE runs, no mastery data available).

## Acceptance Criteria
- [x] `distractorActiveAt` + `dogVisualState 'distractor'` written test-first; precedence verified
- [x] Scene shows a distinct distractor look, clearly different from the offering/markable cue
- [x] `distractorRate` is 0 until onboarding reveals distractors, then uses trick/difficulty rate
- [x] Screenshot of an active distractor reviewed (real capture — `/tmp/bra-distractor.png`)
- [x] Pure cores (scheduler/dogState) no Babylon imports
- [x] `bun run test` green (235/235); `bun run typecheck` clean; `bun run build` succeeds
