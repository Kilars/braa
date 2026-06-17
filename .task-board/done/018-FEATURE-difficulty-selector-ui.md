# FEATURE: Difficulty-Mode Selector UI

**Status**: Done
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: ui, integration, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Difficulty is hardcoded `NORMAL` in `main.ts`. Spec: a single GLOBAL setting
(Normal / Hard / Expert) the player chooses; harder = harsher + bigger payout.
Add a selector and persist the choice so the round uses it.

## Current State

`const MODE: DifficultyMode = 'NORMAL'` in `main.ts`. `effectiveDifficulty(MODE)`
drives the scheduler/deltas/tell. No way to change it; not persisted.

## Desired Outcome

A small HUD control (e.g. a top-left segmented Normal/Hard/Expert, or a settings
button opening a chooser) sets the global mode. The choice persists in GameSave
and the active round rebuilds with the new `effectiveDifficulty`.

## Affected Components
- Modify: `src/main.ts` (mode is state, not const; changing it rebuilds the round config; persist), `src/ui/hud.ts`/`hud.css` (selector control), `src/state/save.ts` (`GameSave` gains `difficultyMode: DifficultyMode`, default 'NORMAL', backward-compatible deserialize)
- Dependencies: `difficulty.ts`, `save.ts`; Blocking: 008, 010, 011

## Technical Approach
- Keep the pure layer untouched; this is wiring + DOM. Mode lives in `main.ts`
  state; a `setMode(mode)` rebuilds `SCHEDULER_CFG`/deltas/tellIntensity and starts
  a fresh round (preserve profile). Persist mode in GameSave on change.
- Selector: 3 buttons/segments, current one highlighted; place where it won't
  collide with coins/level (top-right), the tell ring, or the BRA button.

## Visual Review (required)
- Reuse the long-lived dev server (check `curl -s localhost:5173`, start only if
  down — do NOT pkill it). Screenshot via `scripts/shoot-hud.mjs`; extend it if
  needed to click a non-Normal segment; VIEW the PNG; confirm the selector renders,
  the active mode is highlighted, and nothing overlaps. Note findings.

## Progress Log
- 2026-06-14 — Task created (iteration 6)

## Resolution

### Wiring
- `src/state/save.ts`: `GameSave` gains `difficultyMode: DifficultyMode`; `deserialize` defaults it to `'NORMAL'` for old saves.
- `src/main.ts`: `MODE` changed from `const` to `let`; `difficulty` and `SCHEDULER_CFG` likewise mutable. On load, restores saved mode and rebuilds config. `setMode(mode)` rebuilds `SCHEDULER_CFG`/`difficulty`/`tellIntensity`, starts a fresh round (preserving `profile` + `kennelUpgradeIds`), and persists to storage. Mastery save now includes `difficultyMode`.
- `src/ui/hud.ts`: `HudCallbacks` gains `onSelectMode(mode)` and `initialMode`. `createHud` builds a three-button segmented control (`#hud-diff-selector`, buttons `.hud-diff-btn[data-mode=...]`). `updateModeHighlight` toggles `.active` + `aria-pressed`. `onSelectMode` wired to `setMode` in main.ts.

### Selector DOM + CSS + Placement
- Element: `<div id="hud-diff-selector" role="group" aria-label="Difficulty">` containing three `<button class="hud-diff-btn" data-mode="NORMAL|HARD|EXPERT">` elements.
- Position: `position: fixed; top: 16px; left: 12px; z-index: 11` — top-left corner, 16px below the bar top edge.
- Measured bounding boxes at 390×844 viewport: selector x:12-202, y:16-45 / stats x:299-390, y:240 / BRA btn x:115-275, y:732 / loadout chip x:16, y:766. No overlaps.
- Active segment: `background: rgba(76,222,128,0.25); color: #4cde80; box-shadow: inset 0 0 0 1px rgba(76,222,128,0.5)`.
- Inactive segments: transparent background, muted text.

### Screenshot result
- `/tmp/bra-initial.png`: Normal segment highlighted (active) in the top-left.
- `/tmp/bra-hard.png`: Hard segment highlighted after pointerdown; DOM confirmed `activeMode = HARD`.

### Tests / Build
- `bun run test`: 171 passed (17 test files) — 169 pre-existing + 2 new (difficultyMode backward-compat).
- `bun run typecheck`: 0 errors.
- `bun run build`: success.

## Acceptance Criteria
- [x] A Normal/Hard/Expert selector renders in the HUD without overlapping coins/level, tell ring, or BRA button
- [x] Selecting a mode rebuilds the round with that `effectiveDifficulty` (tighter window/more distractors/fainter tell on harder)
- [x] The chosen mode persists in GameSave and is restored on reload (old saves default NORMAL)
- [x] Profile (coins/level) preserved across a mode change
- [x] Screenshot reviewed; selector + highlight visible
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
