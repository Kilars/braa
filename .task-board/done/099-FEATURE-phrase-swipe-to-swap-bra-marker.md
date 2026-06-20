# FEATURE: Swipe the BRA marker to swap phrase

**Status**: Backlog · **Priority**: High · **Type**: FEATURE (v1 spec gap)
**Created**: 2026-06-19 (iteration 13 scan) · **Depends on**: none

## What
Implement the **second, named** phrase-selection gesture from the spec: swapping the
loaded marker phrase **by swiping the BRA marker itself**. Today only the loadout-chip
*tap* cycles phrases (`hud.ts` `loadoutChipEl` → `onCyclePhrase`); the BRA button only
fires the mark on `pointerdown`. The swipe gesture is a v1 mechanism that is currently
**missing**.

> specs.md §Marker Phrases: *"Selection without extra buttons: a phrase is loaded
> outside the round (a loadout), **or swapped by swiping the BRA marker itself**; the
> round is still one tap. Base 'bra' is always the default…"*

tech-decisions.md §7 still lists the loadout/selection UI as **open** ("Pick and
prototype one; confirm it never competes with the timing tap"). This closes that item
with the swipe path alongside the existing chip tap.

## Why now
- It is an explicit, named **v1** selection mechanism that is not implemented — a real
  spec gap, not polish.
- The pure gesture core is small and TDD-friendly; the only risk (mark-tap latency) has
  a clean, documented solution (below). UI/interaction is an unsaturated domain this
  round (last-15-done skew: quality/refactor ×4, logic ×4).
- Builds directly on existing seams (`onCyclePhrase`, `getLoadoutState`), so it is
  progressive, not a leap.

## The one real risk — and the resolution
This is a **timing game**: the mark currently fires on `pointerdown` for zero input
latency. Naively deferring the mark to `pointerup` to detect a swipe would blunt timing
precision. **Resolution:** record the `pointerdown` timestamp but commit the decision on
`pointerup`/`pointercancel`:
- If the pointer moved past the horizontal swipe threshold → it was a **swipe**: cycle
  the phrase by direction, **suppress** the mark.
- Otherwise → it was a **tap**: fire the mark **using the recorded `pointerdown`
  timestamp**, so scoring precision is identical to today.

A held-but-never-lifted pointer is a non-case for taps; `pointercancel` commits as a tap.

## Technical Approach

### 1. Pure gesture core (TDD) — `src/core/swipeGesture.ts` (new)
A horizontal-dominant drag past a pixel threshold is a swipe; anything else is a tap.

```ts
// NEW
export const SWIPE_THRESHOLD_PX = 40;

export type SwipeOutcome =
  | { type: 'tap' }
  | { type: 'swipe'; dir: 'next' | 'prev' };

export function classifySwipe(
  dx: number,
  dy: number,
  thresholdPx: number = SWIPE_THRESHOLD_PX,
): SwipeOutcome {
  if (Math.abs(dx) >= thresholdPx && Math.abs(dx) > Math.abs(dy)) {
    return { type: 'swipe', dir: dx < 0 ? 'next' : 'prev' }; // swipe-left = next
  }
  return { type: 'tap' };
}
```

Cycling already exists for "next"; add a direction-aware index helper (or extend the
existing cycle) so a right-swipe goes back:

```ts
// NEW (pure) — wraps both directions over the available-phrase list
export function cycleIndex(current: number, length: number, dir: 'next' | 'prev'): number {
  if (length <= 1) return current;
  return dir === 'next' ? (current + 1) % length : (current - 1 + length) % length;
}
```

### 2. HUD wiring — `src/ui/hud.ts`
Add a `onSwapPhrase(dir)` callback and replace the BRA `pointerdown`-only handler with a
down/up pair that uses `classifySwipe`.

```ts
// BEFORE (hud.ts, ~line 415)
braBtn.addEventListener('pointerdown', (e) => {
  e.preventDefault();
  callbacks.onBraTap();
});
```
```ts
// AFTER
let downX = 0, downY = 0, downPending = false;
braBtn.addEventListener('pointerdown', (e) => {
  e.preventDefault();
  downX = e.clientX; downY = e.clientY; downPending = true;
  callbacks.onBraTapDown(); // records the pointerdown instant for precise scoring
});
const commit = (e: PointerEvent) => {
  if (!downPending) return;
  downPending = false;
  const outcome = classifySwipe(e.clientX - downX, e.clientY - downY);
  if (outcome.type === 'swipe') callbacks.onSwapPhrase(outcome.dir);
  else callbacks.onBraTapCommit(); // marks using the recorded pointerdown instant
};
braBtn.addEventListener('pointerup', commit);
braBtn.addEventListener('pointercancel', commit);
```

### 3. main.ts — split `onBraTap` into down/commit so scoring uses the press instant
```ts
// BEFORE: onBraTap() { ... const now = performance.now(); ... }
```
```ts
// AFTER (sketch)
let pendingDownAt: number | null = null;
onBraTapDown() { pendingDownAt = performance.now(); },
onBraTapCommit() {
  const now = pendingDownAt ?? performance.now();
  pendingDownAt = null;
  /* …existing onBraTap body, unchanged, using `now`… */
},
onSwapPhrase(dir) {
  // reuse the existing loadout-cycle path, direction-aware (cycleIndex)
},
```
Keep the existing `onCyclePhrase` (chip tap) working unchanged — `onSwapPhrase` can
delegate to the same loadout-mutation logic with a direction argument.

### 4. Visual affordance (Visual Review gate)
A swipe must read as a phrase change: animate the loaded-phrase label on the marker
sliding horizontally (in the swipe direction) to the new word, respecting
`prefers-reduced-motion` (cross-fade instead of slide). The marker should hint
swipeability subtly (e.g. the loaded word shown on the marker, or faint chevrons) only
once phrases are revealed (`revealed.phrases`).

## Out of scope
- Voice/SFX changes (phrase audio already exists).
- The loadout chip tap — keep it; this **adds** the swipe path, not replaces it.
- Any change to phrase balance / catalog.

## TDD behaviors (write the failing test first)
- `classifySwipe`: left drag ≥ threshold & horizontal-dominant → `swipe/next`; right →
  `swipe/prev`; sub-threshold → `tap`; vertical-dominant drag → `tap`; exactly at
  threshold → swipe (boundary).
- `cycleIndex`: next/prev wrap correctly; `length <= 1` returns `current` (no-op when
  only base "bra" is available).
- Scoring precision unchanged: a tap commits the mark using the **pointerdown** instant
  (a regression guard so the swipe split never adds latency).

## Acceptance criteria
- [ ] `src/core/swipeGesture.ts` exists with `classifySwipe` + `cycleIndex`, written
      **test-first** (red → green → refactor via the `tdd` skill).
- [ ] Swiping the BRA marker left/right swaps to the next/previous **available** phrase;
      a sub-threshold or vertical movement still fires a normal **mark**.
- [ ] Marking still uses the `pointerdown` instant — a test asserts no scoring-time
      regression; `bun run e2e` (smoke + full-loop) stays green.
- [ ] The chip-tap cycle path still works (no regression).
- [ ] Swipe shows a readable phrase-change animation; `prefers-reduced-motion`
      cross-fades instead of sliding.
- [ ] Swipe affordance only appears once phrases are revealed (`revealed.phrases`).
- [ ] **Visual Review** (phone-portrait screenshots) confirms the swap reads clearly and
      the marker still feels like a precise timing tap. Findings are blocking.
- [ ] Gate green: `bun run typecheck` · `bun run test` · `bun run build` (no warnings) ·
      `bun run e2e`.
- [ ] Decision (gesture thresholds + the down/commit timing split) recorded in
      tech-decisions.md §7, marking the "loadout/selection UI" item resolved.
