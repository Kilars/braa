# FEATURE: Trick Identity + Dog/Trick Select Shell

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: core, ui, integration, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

The game is an endless generic round — but the spec's structure is: pick a dog +
a named trick (Sitt / Ligg / Legg deg), teach it, it joins the dog's repertoire.
Add trick identity + a minimal select shell so a round is "teaching SITT to Rex"
and mastery is recorded per dog.

## Current State

`roster.ts` (addDog/recordMastery/repertoire) + `STARTER_BREED` exist but are
unused by the app. No trick identity; the round bar is anonymous; mastery isn't
recorded to any dog.

## Affected Components
- Create: `src/core/tricks.ts` + test (`Trick { id, name }`, `STARTER_TRICKS` = Sitt, Ligg, Legg deg)
- Modify: `src/state/save.ts` (`GameSave` gains `roster: Dog[]` — default one starter dog; backward-compat deserialize), `src/main.ts` (app state machine: `'select' | 'training'`; pick a trick → training round; on mastery `recordMastery` + persist + return to select), `src/ui/hud.ts`/`hud.css` (a simple select screen listing the starter dog + the 3 tricks with mastered marks; a current-trick label during training)
- Dependencies: `roster.ts`, `breeds.ts`, `round.ts`, `save.ts`; Blocking: 005, 010, 013

## Technical Approach
- `tricks.ts` is pure + trivially TDD'd (the catalog + a lookup). Keep trick→behavior
  mapping out of scope (the scheduler stays generic for now); the trick is identity/label.
- Save: default roster = `[{ id:'rex', name:'Rex', breedId: STARTER_BREED.id, masteredTrickIds: [] }]`.
- main.ts: start in `'select'`. Selecting a trick starts a `'training'` round (existing
  loop). On mastery: `recordMastery(roster, dogId, trickId)`, award (existing), persist,
  go back to `'select'`. Mastered tricks show a check in select.
- HUD: select screen (dog name + 3 trick buttons, mastered marked) and, in training,
  a "Teaching: SITT" label. Reuse existing styles.

## Visual Review (required — reuse the running dev server; do NOT pkill)
- Screenshot the select screen AND a training screen (extend the screenshot script to
  click a trick). VIEW both PNGs; confirm the select list + current-trick label read
  clearly and nothing overlaps. Note findings.

## Progress Log
- 2026-06-14 — Task created (iteration 7)

## Resolution

Completed 2026-06-14.

### Red-green cycles

**Cycle 1 — `tricks.ts` (pure catalog + lookup):**
- RED: wrote `tricks.test.ts` with 7 assertions covering `STARTER_TRICKS` shape (3 entries, Norwegian ids/names) and `lookupTrick` (hit, miss, all starters). Module not yet created — import failed.
- GREEN: created `src/core/tricks.ts` with `Trick { id, name }`, `STARTER_TRICKS = [Sitt, Ligg, Legg deg]`, `lookupTrick`. All 7 pass.

**Cycle 2 — `GameSave.roster` backward-compat:**
- Added `roster: Dog[]` to `GameSave` interface; `deserialize` defaults it to `[{ id:'rex', name:'Rex', breedId:'labrador', masteredTrickIds:[] }]` for old saves.
- Updated existing `GameSave` literals in `save.test.ts` and `storage.test.ts` to include `roster`.
- Added 2 new tests in `save.test.ts` (cycle 21): defaults on missing field + preserves on present. All 8 save tests + 6 storage tests pass.

### State-machine wiring (`main.ts`)

- `appState: 'select' | 'training'` controls the rAF tick (skips training logic in select).
- `activeTrick: Trick` set on selection.
- `onSelectTrick(trick)` → sets `activeTrick`, transitions to `'training'`, calls `startFreshRound`, calls `showTraining(trick.name)`.
- On mastery (false→true): `roster = recordMastery(roster, activeDogId, trickId)`, `completeMastery`, `persist()` (includes roster), `appState = 'select'`, `showSelect()`.
- `persist()` helper centralises all `GameSave` construction so roster is always included.

### UI summary (`hud.ts` / `hud.css`)

- `createHud` now returns `{ renderTraining, showSelect, showTraining }` instead of a single render fn.
- **Select screen** (`#hud-select`): dark semi-transparent overlay, dog name (`#hud-select-dog`), vertical list of 3 trick buttons (`.hud-trick-btn`) each with a `.hud-trick-check` span (shows `✓` if mastered) and `.hud-trick-name`. Mastered buttons get gold border via `.mastered` class.
- **Training screen**: existing HUD elements preserved unchanged, plus a `#hud-trick-label` div at the top showing `Teaching: <TrickName>` in green.
- `showSelect()` / `showTraining()` toggle `display` between the two screens.

### Screenshots

**SELECT** (`/tmp/bra-select.png`): Full-screen dark overlay centered on viewport. Top shows "Rex" in large white bold text. Below: 3 buttons stacked vertically with green border — "Sitt", "Ligg", "Legg deg" — each with an empty check column (no mastery yet). Clean, readable, no overlap.

**TRAINING** (`/tmp/bra-training.png`): Select screen hidden. Training HUD visible with "Teaching: Sitt" label in green at top. Progress bar, stats (coins/level), difficulty selector, result flash area, FLINK chip, tell ring, BRA button — all existing elements intact and functioning.

## Acceptance Criteria
- [x] `tricks.ts` written test-first; `STARTER_TRICKS` = Sitt, Ligg, Legg deg (ids + display names)
- [x] `GameSave` gains `roster: Dog[]` (default one starter dog); old saves deserialize with the default
- [x] App has `select` and `training` states; picking a trick starts a round teaching it
- [x] On mastery, the trick is recorded to the dog's repertoire (idempotent) and persisted; returns to select
- [x] HUD shows the current trick name during training and mastered marks in select
- [x] Screenshots (select + training) reviewed
- [x] `bun run test` green (186/186); `bun run typecheck` clean (0 errors); `bun run build` succeeds
