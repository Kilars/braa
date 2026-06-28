# FEATURE: Learned bar → mastery — well-timed BRAs train the trick (P2-4)

**Status**: Done
**Created**: 2026-06-27
**Completed**: 2026-06-27
**Priority**: P1 — Phase-2 core; the next progression mechanic (gives training a beginning/middle/end)
**Labels**: phase-2, game-logic, ui, tdd, visual-review
**Depends on**: 012 (trick registry / `TrickId`), 014 (active-trick selection). Pairs with 015 (fair scoring).

## Context & Motivation

Phase-2 story **P2-4 — Feel the dog learning:** *"As a player, I want well-timed BRAs to fill
a 'learned' bar that reaches mastery, so that training a trick has a beginning, middle, and a
satisfying end."* Acceptance:
- **PERFECT fills more than OK**; the bar only ever **stalls** — **no fail state**.
- **100 % masters** the trick with a **celebratory beat**; mastered tricks are
  **re-practiceable**.

Right now a mark gives an instant payoff (voice + reaction + tier readout) but leaves nothing
behind — every rep is identical, with no arc. This adds the *per-trick* learned bar so training
a trick accumulates toward mastery. It is keyed by `TrickId`, so each trick (Sitt, Ligg, …)
has its own progress, and the bar follows the **active** trick (the one the selector from 014
chose). This is the foundation 017 (persistence) will save.

X-2 holds: this is **not** a second verb — the bar is passive feedback, filled only by the
existing BRA tap. No fail state ever (X-3 — the mark always feels good): a MISS/dead tap simply
doesn't advance the bar; it never *empties* it.

## Desired Outcome

A slim "learned" progress bar in the portrait shell, labelled for the active trick, that fills
on each successful mark — **PERFECT visibly more than OK** — and **only ever rises** (a poor tap
stalls it, never lowers it). At 100 % the trick is **mastered**: a one-time celebratory beat
fires (a "Mestret!" flash / the bar glows full), and the trick stays masterable/re-practiceable
(the bar holds at full; the player can keep marking it). Switching tricks shows that trick's own
bar. Reduced-motion: the fill and the mastery beat are dampened, never removed (the state is
still readable). Headless boot stays green (pure model + thin DOM; no required GPU/audio).

## Affected Components

### Files to Add
- `src/core/progress.ts` — pure, DOM-free learned-progress model: a `TrickId`-keyed store with
  a deterministic `advance(state, tier)` reducer + mastery detection. No Babylon, no DOM.
- `src/core/progress.test.ts` — the failing-first invariants below (TDD, red first).

### Files to Modify
- `src/app/shell.ts` — render a `learnedBar` (track + fill + label/value) in the portrait
  layout, clear of the BRA button / apex ring / tier readout (X-2, P1-7); expose handles to set
  fill [0,1], the active-trick label, and a `mastered` flash. `data-testid` + `aria` for e2e.
- `src/main.ts` — on a scored OK/PERFECT, `advance` the **active** trick's progress, push the
  new fill to the bar; on a fresh 0.99→1.0 crossing fire the mastery beat **once** (per trick);
  re-point the bar at the active trick on a selector switch.
- `src/style.css` — bar styling + fill transition + a tasteful mastery glow; reduced-motion
  dampens (no required animation); honor `:focus-visible` if any control is added (none needed).

## Technical Approach (TDD — game-logic first per the `tdd` skill; Visual Review for the bar)

### Before — a mark gives an instant payoff but leaves no trace
```ts
// main.ts, on pointerup:
const tier = scene.scoreTapNow(now)
audio.play(tier); scene.react(tier, now)
if (tier === 'NONE') return
tierReadout.textContent = tier // ... and nothing accumulates
```

### After — a pure per-trick progress model the tap feeds; the bar mirrors it
```ts
// src/core/progress.ts (NEW) — pure, deterministic, unit-tested
import type { MarkTier } from './mark'
import type { TrickId } from './trick'

/** How much each tier fills the learned bar. PERFECT > OK; MISS/NONE never move it. */
export const LEARN_GAIN: Record<'PERFECT' | 'OK', number> = { PERFECT: 0.12, OK: 0.05 }

export interface TrickProgress {
  /** Learned fraction in [0,1]; 1 = mastered. Monotonic — only ever rises. */
  learned: number
  /** True once `learned` first reaches 1; stays true (re-practiceable, never lost). */
  mastered: boolean
}

export const EMPTY_PROGRESS: TrickProgress = { learned: 0, mastered: false }

/**
 * Apply one scored tap to a trick's progress. PERFECT fills more than OK; MISS /
 * NONE return the state unchanged (no fail state — the bar only ever stalls).
 * Clamps at 1 and latches `mastered` (mastered tricks stay mastered and keep
 * accepting practice taps at full).
 */
export function advance(state: TrickProgress, tier: MarkTier): TrickProgress {
  if (tier !== 'OK' && tier !== 'PERFECT') return state // stall, never drop
  const learned = Math.min(1, state.learned + LEARN_GAIN[tier])
  return { learned, mastered: state.mastered || learned >= 1 }
}

/** A per-trick store. `get` defaults to EMPTY_PROGRESS so unseen tricks read clean. */
export interface ProgressStore {
  get(id: TrickId): TrickProgress
  /** Apply a tap to one trick; returns the new state and whether mastery was just reached. */
  apply(id: TrickId, tier: MarkTier): { state: TrickProgress; justMastered: boolean }
  /** Plain snapshot for persistence (task 017). */
  toJSON(): Record<string, TrickProgress>
}
export function createProgressStore(
  initial?: Record<string, TrickProgress>,
): ProgressStore { /* ... */ }
```
```ts
// main.ts — feed the active trick; flash mastery once
const progress = createProgressStore()
// on a scored tap (after audio/react), for OK/PERFECT:
const { state, justMastered } = progress.apply(scene.activeTrickId(), tier)
shell.setLearned(state.learned)
if (justMastered) shell.flashMastered() // one-time celebratory beat (P2-4)
// on a selector switch: shell.setLearned(progress.get(id).learned)
```

### Tests to write first (red → green)
```ts
// progress.test.ts
it('PERFECT fills more than OK', () => {
  const p = advance(EMPTY_PROGRESS, 'PERFECT').learned
  const o = advance(EMPTY_PROGRESS, 'OK').learned
  expect(p).toBeGreaterThan(o)
})
it('never drops on MISS / NONE (only ever stalls — no fail state)', () => {
  const s = advance(EMPTY_PROGRESS, 'OK')
  expect(advance(s, 'MISS')).toEqual(s)
  expect(advance(s, 'NONE')).toEqual(s)
})
it('clamps at 1 and latches mastered (stays mastered, still practiceable)', () => {
  let s = EMPTY_PROGRESS
  for (let i = 0; i < 50; i++) s = advance(s, 'PERFECT')
  expect(s.learned).toBe(1)
  expect(s.mastered).toBe(true)
  expect(advance(s, 'OK')).toEqual(s) // re-practice at full is a no-op, never overflows
})
it('store keeps per-trick progress independent and reports just-mastered once', () => {
  const store = createProgressStore()
  store.apply('sitt', 'OK')
  expect(store.get('ligg').learned).toBe(0) // independent per trick
  let mastered = false
  for (let i = 0; i < 50; i++) mastered = mastered || store.apply('ligg', 'PERFECT').justMastered
  expect(store.get('ligg').mastered).toBe(true)
  expect(store.apply('ligg', 'PERFECT').justMastered).toBe(false) // only the crossing fires
})
```

> **Tuning note:** `LEARN_GAIN` above masters Sitt in ~9 PERFECTs / 20 OKs — a satisfying
> short arc for Phase 2. Treat the exact numbers as tunable; the *invariants* (PERFECT > OK,
> monotonic, clamp, latched mastery) are the contract the tests lock.

## Visual Review (blocking — P2-3 / X-3)
Independent review on a 390×844 portrait viewport with real screenshots:
- The learned bar is **slim and clear**, obviously a *progress* meter for the active trick;
  never overlaps the BRA button, apex ring, or tier readout (X-2, P1-7); the dog stays the focus.
- A PERFECT mark fills **visibly more** than an OK mark (capture an OK-fill vs a PERFECT-fill frame).
- The **mastery beat** reads as a celebration (full/glowing bar, "Mestret!" or equivalent) and
  is unmistakably a positive, finished feeling — fires once on reaching 100 %.
- Switching tricks (Sitt ↔ Ligg) shows each trick's **own** fill level.
- Reduced-motion: the bar still communicates fill + mastery with motion dampened.

## Risks & Considerations
- **No fail state, ever (X-3).** The bar must never decrease — MISS/NONE stall it. Don't add a
  decay or penalty here (that flirts with Phase-4 territory; out of scope).
- **One source of truth.** Progress lives in the pure store; `main.ts` mirrors it into the bar.
  Don't recompute fill in the DOM. `scene.activeTrickId()` is the key — feed the *active* trick.
- **Mastery fires once.** Guard the celebratory beat on the 0.99→1.0 crossing (`justMastered`),
  not on every full-bar tap, or re-practice re-triggers the flash.
- **Forward-compat with 017.** `toJSON()` / the `initial` ctor arg are the seam persistence will
  use — keep the snapshot a plain, versionable record. Don't build IndexedDB here (that's 017).
- **Keep it un-busy (P2-1/X-2).** One slim bar, not a stats panel. The bar is feedback, not a
  second thing to manage.

## Acceptance Criteria
- [x] **TDD, red first:** `progress.test.ts` covers PERFECT > OK, no-drop on MISS/NONE, clamp +
      latched mastery + re-practice, and per-trick independence + once-only `justMastered`.
- [x] `src/core/progress.ts` is a pure, DOM-free model with a `TrickId`-keyed store and a
      `toJSON()` snapshot (the seam 017 persists).
- [x] `shell.ts` renders a slim learned bar (track/fill/label) clear of BRA/ring/readout, with
      test ids; `main.ts` feeds the **active** trick on OK/PERFECT and re-points the bar on switch.
- [x] PERFECT fills visibly more than OK on the running app; the bar only ever rises.
- [x] Reaching 100 % fires a one-time celebratory mastery beat; the trick stays masterable and
      re-practiceable; switching tricks shows that trick's own progress.
- [x] Reduced-motion safe (fill + mastery still readable with motion dampened); headless boot green.
- [x] **Visual Review passed** by independent reviewer(s) on 390×844 with real screenshots.
- [x] Verify gate green: `typecheck` 0 · `test` · `build` no-warnings · `e2e`.

## Closeout — 2026-06-27

**Verify gate (all green):**
- `bun run typecheck` → 0 errors
- `bun run test` → 69 passed (8 files; incl. `progress.test.ts` 10 tests)
- `bun run build` → built clean, no warnings
- `bun run e2e` → 11 passed (incl. `learned.spec.ts` P2-4: a real BRA fills the bar; a dead
  IDLE tap never moves it — proves monotonic, no-fail-state behaviour end-to-end)

**Visual Review (blocking — two independent reviewers, real 390×844 screenshots):**
- Artifacts: `.screenshots/learned-01-empty.png`, `learned-02-partial.png`,
  `learned-03-mastered.png`, plus `selector-01-sitt-active.png` / `selector-02-ligg-active.png`
  for the per-trick label switch.
- Reviewer 1 → **SHIP**. Reviewer 2 → **SHIP**. Both confirmed: slim passive HUD that never
  collides with the BRA button / apex ring / tier readout; empty→partial→full progression is
  glanceable; mastery (glowing gold bar + "Mestret!" with dark outline) reads as a positive
  finished beat, not an error; the bar's label correctly follows the selector (Sitt ↔ Ligg).
- Non-blocking notes carried forward (not defects): the empty state could add a faint "0%" cue
  to read less like "no data"; the *static* mastery frame is calm — the exuberant beat is the
  `just-mastered` pop animation (in code, not capturable in a still). Neither blocks ship.

**Notes for 017 (persistence):** the seam is ready — `createProgressStore(initial)` hydrates
and `store.toJSON()` emits a plain `Record<TrickId, TrickProgress>` snapshot. `main.ts` already
mirrors the store into the bar via `reflectLearned(id)`, so hydrate-before-first-paint just needs
to seed the store and call `reflectLearned(scene.activeTrickId())`.
