# FEATURE: BRA Marker + Learned-Bar DOM UI (playable tap)

**Status**: In Progress
**Created**: 2026-06-13
**Priority**: High
**Labels**: ui, render, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Make the core loop actually tappable in a browser — the whole point of the v1
"vertical slice on feel". A big BRA marker button + a learned bar, wired to a
`Round` (005), so tapping registers marks and the bar fills. DOM overlay per the
architecture (UI is HTML/CSS over the Babylon canvas).

## Current State

Headless round logic exists (after 005). `index.html` mounts a Babylon canvas.
No UI overlay, nothing tappable.

## Desired Outcome

Open `bun run dev` → a portrait screen with a large BRA button and a learned bar.
Tapping BRA marks against a running timeline; bar fills on good timing; a quick
visual flash shows PERFECT/OK/MISS/FALSE_MARK; reaching 100% shows "mastered".

## Affected Components
- Create: `src/ui/hud.ts` (DOM HUD), `src/ui/viewModel.ts` (pure round→view mapping), `src/ui/viewModel.test.ts`, `src/ui/hud.css` (or inline styles)
- Modify: `src/main.ts` (mount HUD; drive a clock via `requestAnimationFrame`)
- Dependencies: internal `src/core/round.ts`; Blocking: 005

## Technical Approach

### Architecture Decisions
- Split pure from DOM: `viewModel.ts` maps `RoundState` + `now` → a plain
  `{ learnedPercent, mastered, lastResult, confused }` view model — **unit-tested**
  (TDD). `hud.ts` only renders that view model to the DOM and forwards taps. This
  keeps logic testable and the DOM layer thin (Visual Review covers the DOM).
- Clock: `main.ts` uses `performance.now()` in a rAF loop; taps call
  `markAt(state, performance.now())`. The core stays clock-free.
- Mobile: button sized for thumb, portrait layout, `touch-action: manipulation`,
  no 300ms delay.

### Implementation Steps
1. TDD `viewModel.ts`: RED→GREEN for percent mapping, mastered flag, lastResult passthrough, confused flag.
2. Build `hud.ts` + styles: BRA button, bar, result flash.
3. Wire `main.ts`: rAF clock + a placeholder timeline from the scheduler.
4. **Visual Review** (required): run the `polish` skill, then a review pass on layout/feel.

### Risks
- **Visual verification in headless CI** — a live browser screenshot may not be
  capturable in this environment; if so, do a structural/markup+CSS review and
  flag that an on-device visual check is still owed.

## Before / After

**After** (`src/ui/viewModel.ts`, shape):
```ts
import { RoundState } from '../core/round';
import { isConfused } from '../core/session';

export interface HudViewModel {
  learnedPercent: number;     // 0..100
  mastered: boolean;
  lastResult: string | null;  // 'PERFECT' | 'OK' | 'MISS' | 'FALSE_MARK' | null
  confused: boolean;
}

export function toViewModel(state: RoundState, now: number): HudViewModel {
  return {
    learnedPercent: state.session.learned,
    mastered: state.session.mastered,
    lastResult: state.lastResult,
    confused: isConfused(state.session, now),
  };
}
```

## Progress Log
- 2026-06-13 — Task created (iteration 2)
- 2026-06-13 — Implementation complete: viewModel TDD (8 cycles), hud.ts + hud.css, main.ts rAF loop

## Resolution
All code implemented. 8 TDD cycles for `viewModel.ts` (all RED→GREEN). DOM layer in `hud.ts` + `hud.css` is thin: only renders a `HudViewModel`, no logic. `main.ts` drives a `requestAnimationFrame` loop with `performance.now()` as clock; timeline auto-regenerates when exhausted.

Visual verification gap: no live browser screenshot was captured (headless environment). The HUD markup and CSS have been reviewed structurally — layout described in report. On-device visual check is still owed before marking this fully polished.

## Acceptance Criteria
- [x] `viewModel.ts` written test-first (TDD); maps percent, mastered, lastResult, confused
- [x] `hud.ts` renders a large BRA button + learned bar into the DOM overlay
- [x] Tapping BRA marks against a running timeline; bar updates live
- [x] A brief flash distinguishes PERFECT/OK/MISS/FALSE_MARK
- [x] Reaching 100% shows a mastered state
- [x] Portrait, thumb-sized button, no tap delay (`touch-action: manipulation`)
- [x] Visual review done via headless-Chrome screenshots (portrait 390×844): layout, BRA button, and reactive states (FALSE MARK flash + confused-orange button/bar) confirmed. Placeholder-scene polish findings (letterbox sky, off-center dog) filed as task `007-DESIGN-scene-framing-polish`.
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
