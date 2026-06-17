# FEATURE: Behavior Combos (TDD core + HUD)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: core, ui, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Spec Future: "Behavior chains / combos — depth from sequencing the same one tap."
Add a combo counter: consecutive good marks build a combo that boosts reward;
a miss / false mark breaks it. Adds skill depth to the core loop, one tap only.

## Affected Components
- Create: `src/core/combo.ts` + test
- Modify: `src/main.ts` (track combo on each mark; apply `comboMultiplier` to the learned-bar gain and/or coin payout; reset on break), `src/ui/hud.ts`/`hud.css` (a combo indicator, e.g. "x3" that grows/flashes and clears on break)
- Dependencies: `mark.ts` (`MarkResult`); Blocking: 002, 011

## Interface (signatures — bodies test-first)

```ts
export function comboAfter(combo: number, result: MarkResult): number; // PERFECT/OK +1; MISS/FALSE_MARK -> 0
export function comboMultiplier(combo: number): number;                 // 1 at combo 0/1; grows; capped (e.g. 1 + 0.1*combo, max 2)
```

## Behaviors to test (each RED first)
- `comboAfter(0,'PERFECT')` = 1; chaining PERFECT/OK increments.
- `comboAfter(n,'MISS')` = 0 and `comboAfter(n,'FALSE_MARK')` = 0 (break).
- `comboMultiplier(0)` = 1; rises with combo; capped at the chosen max.
- Determinism.

## Wiring
- main.ts: keep a `combo` var; on each mark compute `comboAfter`; multiply the learned-bar
  delta (or payout) by `comboMultiplier(combo)`; reset visual on break.
- HUD: combo chip near the top/center that shows the current streak and clears to nothing at 0.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Drive a few PERFECT taps (or seed) to show a combo > 1; screenshot; VIEW it; confirm the
  combo indicator renders and reads clearly without overlap.

## Progress Log
- 2026-06-14 — Task created (iteration 10)

## Resolution

**Completed 2026-06-14.**

### Red-green cycles (7 total)

| Cycle | Test | Key implementation |
|-------|------|--------------------|
| 1 | `comboAfter(0,'PERFECT') = 1` | stub `return 1` |
| 2 | chaining PERFECT/OK increments | `PERFECT\|OK → combo+1`, else `0` |
| 3 | MISS/FALSE_MARK → 0 (confirmed already correct) | — |
| 4 | `comboMultiplier(0) = 1`, `comboMultiplier(1) = 1` (stub) | — |
| 5 | `comboMultiplier(2) > 1`, monotonic growth | `min(2, 1 + 0.1*(combo-1))` |
| 6 | cap at 2 for combo ≥ 11 | already in formula |
| 7 | determinism (pure functions) | confirmed |

### Combo formula

```ts
comboAfter(combo, result):   PERFECT|OK → combo+1;  MISS|FALSE_MARK → 0
comboMultiplier(combo):      min(2,  1 + 0.1 * max(0, combo - 1))
  // combo=0→×1  combo=1→×1  combo=2→×1.1  combo=11→×2 (cap)
```

### Wiring

- `main.ts`: `let combo = 0`; reset in `startFreshRound`; on each tap, compute `comboMultiplier(combo)` and scale PERFECT/OK bar deltas before `applyMark`; then advance with `comboAfter(combo, result)`.
- `viewModel.ts`: `combo` field added to `HudViewModel`; passed as 5th arg to `toViewModel`.
- `hud.ts`: `#hud-combo` element; shows `x{N}` with `.visible` class when `combo >= 2`; `data-combo` attr drives CSS growth at high streaks.
- `hud.css`: fixed top-center below the trick label pill (~88px from top); gold pill; grows at combo ≥ 5; max glow at combo ≥ 11. No overlap with bar (top), stats (top-right), selector (top-left), trick label (center ~56px), loadout chip (bottom-left), BRA (bottom-center).

### Screenshot result

**Could not capture a real screenshot.** Both `/usr/bin/google-chrome` and the playwright-bundled Chromium fail to launch headlessly due to a `GLIBC_ABI_DT_X86_64_PLT` version conflict between the Nix-installed `librt.so.1` and the system libc — not a code issue. The dev server returns 200 and the build succeeds; the DOM wiring is verifiable by code inspection.

### Verification

- `bun run test`: 267 passed (267), all 21 test files green (13 new combo tests)
- `bun run typecheck`: 0 errors
- `bun run build`: succeeds (dist built)

## Acceptance Criteria
- [x] `combo.ts` written test-first; increment on good marks, reset on miss/false mark, capped multiplier
- [x] Combo boosts learned-bar gain and/or payout in the live loop
- [x] HUD shows the current combo streak; clears on break; no overlap
- [ ] Screenshot reviewed (real) — **blocked by Nix/glibc headless browser incompatibility in this environment**
- [x] Pure `combo.ts` no DOM imports
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
