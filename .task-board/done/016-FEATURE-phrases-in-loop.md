# FEATURE: Phrases in the Live Loop + Loadout (TDD + UI)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: Medium
**Labels**: core, ui, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Phrase logic exists (`phrases.ts`, 012) but the live app never uses it: marks
don't apply a phrase window bonus, cooldowns aren't enforced, and there's no
loadout. Wire phrases into the mark path and add a minimal loadout, keeping the
"still one tap" rule.

## Current State

`onBraTap` calls `markAt(state, now)` with the base attempt only. No phrase, no
cooldown, no loadout UI.

## Desired Outcome

A loaded phrase (default `BASE_PHRASE`) modifies the mark: if ready, its window
bonus widens the active attempt before classification and its cooldown starts;
if on cooldown, the base phrase is used. A small loadout chip shows the loaded
phrase + cooldown state.

## Affected Components
- Create: `src/core/markWithPhrase.ts` + test (pure: given attempt, phrase, now,
  lastUsedAt → effective attempt + whether the phrase fired) — OR add to `round.ts`
- Modify: `src/main.ts` (track loaded phrase + lastUsedAt; apply on tap), `hud.ts`/
  `hud.css` (loadout chip + cooldown indicator)
- Dependencies: `phrases.ts`, `mark.ts`, `round.ts`; Blocking: 012

## Interface (signatures — bodies test-first)

```ts
export interface PhraseMark { attempt: Attempt | null; fired: boolean; }
// If phrase ready: widen the (non-null) active attempt, fired=true. Else: base attempt, fired=false.
export function resolvePhraseMark(active: Attempt | null, phrase: Phrase, now: number, lastUsedAt: number | null): PhraseMark;
```

## Behaviors to test (each RED first)
- Ready phrase + active attempt → widened attempt, `fired=true`.
- Phrase on cooldown → base (unwidened) attempt, `fired=false`.
- `BASE_PHRASE` always fires but widens by 0 (no change).
- No active attempt → attempt stays null, fired follows readiness (still a FALSE_MARK downstream).

## main.ts wiring + Visual Review
- Track `loadedPhrase` + `lastUsedAt`; on tap, `resolvePhraseMark(...)`, mark with
  the effective attempt, update `lastUsedAt` when fired. Loadout starts with
  `BASE_PHRASE` + one cooldown phrase (per spec: few phrases at start).
- HUD: a small chip showing the loaded phrase word + a cooldown sweep/disabled state.
- Screenshot via `scripts/shoot-hud.mjs`; VIEW it; confirm the chip renders. Note findings.

## Progress Log
- 2026-06-13 — Task created (iteration 5)

## Resolution

### Red-green cycles (4)

1. **Ready phrase + active attempt → widened attempt, fired=true**
   RED: test for FLINK phrase (lastUsedAt=null) widening `start`/`end` and `fired=true`. File missing → import error.
   GREEN: Created `src/core/markWithPhrase.ts` with `resolvePhraseMark` — calls `isReady`, branches on `active !== null` + ready.

2. **Phrase on cooldown → base attempt, fired=false**
   RED: test with `lastUsedAt` 1ms before cooldown expires — expected `fired=false` and same attempt reference.
   GREEN: Already handled by initial implementation (not-ready path). No code change needed.

3. **BASE_PHRASE always fires, widens by 0 (same reference)**
   RED: test with `BASE_PHRASE` used 1ms ago — expected `fired=true` and same attempt reference.
   GREEN: Already handled — `isReady(BASE_PHRASE, ...)` is always true; `applyPhraseToAttempt` returns same ref when `windowBonusMs=0`. No code change.

4. **No active attempt → attempt stays null, fired follows readiness**
   RED: test `resolvePhraseMark(null, COOL_PHRASE, 10_000, null)` expecting `fired=true`. Failed — initial impl returned `fired=false` for null active.
   GREEN: Added early `if (active === null) return { attempt: null, fired: ready }` branch.

### Wiring (main.ts)

- Removed `markAt` import; added `attemptAt`, `classifyMark`, `applyMark`, `BASE_PHRASE`, `Phrase`, `resolvePhraseMark`.
- Defined `FLINK_PHRASE` constant (windowBonusMs=150, cooldownMs=8000) in module scope.
- Added `loadedPhrase` (defaults to `FLINK_PHRASE`) and `lastUsedAt: number | null` state variables inside async IIFE.
- `onBraTap`: computes `active = attemptAt(...)`, calls `resolvePhraseMark`, classifies with the resolved attempt, applies mark, sets `lastUsedAt = now` when `fired && cooldownMs > 0`.
- Added `getPhrase()` callback to `HudCallbacks` interface.

### Chip (hud.ts / hud.css)

- DOM: `<div id="hud-loadout-chip">` appended to `#hud` before `#hud-bottom`.
- Each render frame: reads `phrase.word` into `textContent`; toggles `.on-cooldown`; sets `--cooldown-pct` CSS variable (remaining ms as % of cooldownMs).
- CSS: `position: fixed; bottom: 48px; left: 16px; z-index: 11` — bottom-left corner, well clear of coins/level badge (top-right) and BRA button (bottom-center). Background uses a hard-stop linear-gradient (`#1a7a40 var(--cooldown-pct), #4cde80 var(--cooldown-pct)`) to show the drained vs remaining cooldown portion directly in the background without any pseudo-elements. `.on-cooldown` dims the text color.

### Screenshot

Initial: chip shows "FLINK" in bright green (ready), bottom-left, no overlap.
Active (after repeated false taps): chip visible in dimmed state alongside the confused orange BRA button; still clearly separated from all other HUD elements.

## Acceptance Criteria
- [x] `resolvePhraseMark` written test-first; ready→widened+fired, cooldown→base+not-fired, base→fires+no-change
- [x] `main.ts` applies the loaded phrase on tap and tracks cooldown (`lastUsedAt`)
- [x] HUD shows a loadout chip with cooldown state
- [x] Screenshot reviewed; chip visible, doesn't overlap other HUD elements
- [x] Pure core has no DOM imports
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
