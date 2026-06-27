# FEATURE: Pick-a-trick selector — choose the active trick, one page, one verb (P2-1)

**Status**: Done
**Created**: 2026-06-27
**Completed**: 2026-06-27
**Priority**: P1 — Phase-2 core (makes the two tricks player-selectable)
**Labels**: phase-2, ui, game-logic, tdd, visual-review
**Estimated Effort**: Medium
**Depends on**: 012 (trick registry + `setTrick`), 013 (a real second trick to switch to).

## Context & Motivation

Phase-2 story **P2-1**: *"As a player, I want to choose which trick to train from a small,
clear selector, so that I can grow a dog's repertoire without the game becoming busy."*
Acceptance: the selector "stays one-page, portrait, one-verb — it is **not** a second
gameplay verb during the round." Cross-cutting **X-2** ("one verb, always") is the
guardrail: the BRA tap stays the only *gameplay* action; the selector is a between-attempts
chooser, not a second thing to time.

Tasks 012/013 give a registry of tricks (Sitt, Ligg) and the scene's `setTrick(id)`. This
task adds the **player-facing chooser** that drives it: a small, clear trick selector in the
portrait shell. The selection logic is pure and deterministic → **test-first** (`tdd`
skill); the chip UI gets a **Visual Review** pass.

## Desired Outcome

A compact trick selector in the shell (e.g. a single horizontal chip row of the registry's
tricks, labelled in Norwegian — "Sitt", "Ligg"), reachable one-handed in portrait, clearly
showing which trick is **active**. Tapping a chip calls `scene.setTrick(id)`, and the dog
begins performing that trick on its next cycle. It never competes with the BRA tap for the
timing moment (it sits clear of the marker and is not part of the apex read). Selecting a
trick is a calm, obvious "which trick am I training" choice — the round stays one tap.

## Affected Components

### Files to Add
- `src/app/trickSelector.ts` — pure selection state: `createTrickSelection(tricks,
  initialId)` → `{ activeId, select(id), list }` with change notification; no DOM.
- `src/app/trickSelector.test.ts` — selection-state invariants (TDD, red first).

### Files to Modify
- `src/app/shell.ts` — render the chip row from `TRICKS`, expose a `trickBar` handle +
  per-chip elements (with `data-testid`/`aria` + an active state); keep it clear of the
  marker group so it never overlaps the BRA button or the apex read (X-2, P1-7).
- `src/main.ts` — wire chip taps → `selection.select(id)` → `scene.setTrick(id)`; reflect
  the active chip; reuse the `__braSetTrick` / `__braTricks` probes from 012 for e2e.
- `src/style.css` — chip styling (active vs inactive, thumb-friendly hit targets, portrait
  layout); honor `:focus-visible` (the ring pattern added in the Phase-1 close-out).

## Technical Approach (TDD for the selection state; Visual Review for the chip UI)

### Before — no selector; the trick is fixed to Sitt
```ts
// shell.ts returns only { canvas, braButton, apexRing, tierReadout }
// main.ts never changes the trick.
```

### After — a pure selection model drives setTrick
```ts
// src/app/trickSelector.ts (NEW) — pure, DOM-free, unit-tested
import type { TrickDef, TrickId } from '../core/trick'

export interface TrickSelection {
  readonly list: readonly TrickDef[]
  readonly activeId: TrickId
  /** Select a trick by id; returns true if the active trick changed. */
  select(id: TrickId): boolean
  /** Subscribe to active-trick changes (for the shell to re-style chips). */
  onChange(fn: (id: TrickId) => void): void
}

export function createTrickSelection(
  list: readonly TrickDef[],
  initialId: TrickId,
): TrickSelection { /* ... */ }
```
```ts
// main.ts — chips drive the scene; one source of truth for the active trick
const selection = createTrickSelection(TRICKS, 'sitt')
selection.onChange((id) => {
  scene.setTrick(id)
  shell.setActiveChip(id) // restyle chips; never touches the BRA tap path
})
shell.trickChips.forEach((chip) =>
  chip.addEventListener('pointerup', () => selection.select(chip.dataset.trickId as TrickId)),
)
```

### Tests to write first (red → green)
```ts
// trickSelector.test.ts
it('starts on the initial trick and lists the registry', () => {
  const sel = createTrickSelection(TRICKS, 'sitt')
  expect(sel.activeId).toBe('sitt')
  expect(sel.list.map((t) => t.id)).toContain('ligg')
})
it('select changes the active trick and fires onChange once', () => {
  const sel = createTrickSelection(TRICKS, 'sitt')
  let fired: string | null = null
  sel.onChange((id) => (fired = id))
  expect(sel.select('ligg')).toBe(true)
  expect(sel.activeId).toBe('ligg')
  expect(fired).toBe('ligg')
})
it('re-selecting the active trick is a no-op (no spurious onChange)', () => {
  const sel = createTrickSelection(TRICKS, 'sitt')
  let count = 0
  sel.onChange(() => count++)
  sel.select('sitt')
  expect(count).toBe(0)
})
```

## Visual Review (blocking — P2-3 / X-2 guardrail)

Independent review on a 390×844 portrait viewport with real screenshots:
- The selector is small, clear, and obviously a **trick chooser**, not a second BRA.
- The **active** trick is unmistakable (selected chip state); switching is visible.
- It is thumb-reachable in portrait and never overlaps the BRA button, the apex ring, or
  the tier readout (X-2, P1-7); the dog stays the focus.
- Selecting Ligg then Sitt swaps the dog's performed trick (cross-check with task 013).

## Risks & Considerations
- **Don't add a second verb.** The selector must not become part of the timing skill — keep
  it out of the apex read and the BRA hit area; it is a calm between-attempts choice (X-2).
- **One source of truth.** The active trick lives in `createTrickSelection`; `main.ts`
  mirrors it into the scene and the chip styling. Don't let the scene and the UI drift.
- **Keep it un-busy (P2-1).** Two chips now; the row must scale to a few more tricks without
  the page feeling cluttered — plan the layout for ~3–6 chips, not a grid of dozens.
- **Switch timing.** Decide and document whether a switch takes effect immediately or at the
  next idle/cycle boundary; avoid snapping the dog mid-build (prefer applying at the next
  cycle start so there is no pose pop).

## Acceptance Criteria
- [x] `src/app/trickSelector.ts` is a pure, DOM-free selection model; `trickSelector.test.ts`
      covers initial state, change + single `onChange`, and the no-op re-select (red first).
- [x] `shell.ts` renders a labelled chip per registry trick with an active state and test
      ids; `main.ts` wires chip taps → `select` → `scene.setTrick`, reflecting the active chip.
- [x] Selecting a trick changes the dog's performed trick on the running app (Sitt ↔ Ligg).
- [x] The selector is one-page, portrait, thumb-reachable, and never overlaps the BRA
      button / apex ring / tier readout (X-2); the BRA tap path is untouched.
- [x] `:focus-visible` ring honored on chips; reduced-motion safe (no required animation).
- [x] **Visual Review passed** by independent reviewer(s) on 390×844 with real screenshots;
      blocking findings fixed.
- [x] TDD followed (failing selection tests first).
- [x] Verify gate green: `typecheck` · `test` · `build` · `e2e`.

## Completion Notes (2026-06-27)

**Done.** Status: **Done**. Verify gate green: `typecheck` 0 errors · `test` 57 pass
(6 new in `trickSelector.test.ts`) · `build` no warnings · `e2e` 9 pass
(2 new in `selector.spec.ts`).

- **TDD (red→green):** wrote `trickSelector.test.ts` first (failed: module missing),
  then the pure `createTrickSelection` model. Covers initial state + registry list,
  change-fires-onChange-once, no-op re-select, multi-subscriber notify, and throw-on-
  unknown (id and initial id) — the model never silently selects nothing.
- **One source of truth:** `createTrickSelection` is the only place the active trick
  lives. `main.ts` mirrors `onChange` into BOTH the chip styling (`shell.setActiveChip`)
  and the scene, so UI and dog can't drift. `scene.activeTrickId()` (new) is the
  deterministic read the e2e asserts against.
- **Switch timing — applied at the next IDLE, not immediately.** The chip flips active
  the instant it's tapped (a calm chooser response), but `scene.setTrick` is deferred via
  a `requestAnimationFrame` pump in `main.ts` until the dog returns to IDLE (standing),
  so a mid-build switch never snaps the pose (the "no pose pop" consideration). The
  capture probe `__braSetTrick` stays immediate so Visual-Review freezing still works.
- **X-2 guardrail:** the chip row renders in a `.bottom-stack` ABOVE the marker group
  with a 40px gap; `selector.spec.ts` asserts the row's bottom edge sits at/above the BRA
  button, the apex ring, and the tier readout, and within the 390px viewport. The chooser
  is wired to `pointerup` like any chip — it is never part of the timed BRA tap path.
- **Un-busy / scaling:** chips use `flex-wrap: wrap` + centred, so 3–6 future tricks wrap
  calmly (the reviewer's only — non-blocking — note, already handled).
- **Visual Review: SHIP** (independent reviewer, real 390×844 screenshots
  `selector-01-sitt-active.png` / `selector-02-ligg-active.png`): chooser reads as a
  distinct, small control vs the orange BRA; active chip (solid white pill) unmistakable
  and visibly moves Sitt→Ligg; no overlap with BRA/ring/readout; legible both states.
- Files: ADD `src/app/trickSelector.ts` + `.test.ts`, `e2e/selector.spec.ts`;
  MODIFY `src/app/shell.ts`, `src/main.ts`, `src/render/scene.ts` (added
  `activeTrickId()`), `src/style.css`, `e2e/_capture.spec.ts` (selector capture).
