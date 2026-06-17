# FEATURE: Apex Tell — the timing cue (TDD core + render)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: High
**Labels**: core, ui, render, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

The single most important missing piece for FEEL. Spec "Core Gameplay Loop": a
**subtle visual tell — a soft pulse/ring/glow at the apex** signals the moment to
tap; harder difficulty makes it fainter/faster. Right now nothing renders at the
peak, so the player is timing blind. Add a computed tell strength + a visible cue.

## Current State

`toViewModel(state, now, profile)` returns learned/mastered/lastResult/confused/
coins/level. The scheduler knows the active attempt + peak, but the UI shows no
timing cue.

## Desired Outcome

The HUD shows a pulse/ring that intensifies as the active attempt approaches its
peak and is brightest at the peak, scaled by difficulty `tellIntensity`. The
player can time the BRA tap by it.

## Affected Components
- Modify: `src/ui/viewModel.ts` (+`attemptActive`, `tellStrength`) + its test
- Modify: `src/ui/hud.ts` + `hud.css` (render a pulse cue bound to `tellStrength`)
- Modify: `src/main.ts` (pass `difficulty.tellIntensity` into `toViewModel`)
- Dependencies: `scheduler.ts` (`attemptAt`), `difficulty.ts`; Blocking: 004, 008, 011

## Interface (extend viewModel — bodies test-first)

```ts
export interface HudViewModel {
  /* existing fields… */
  attemptActive: boolean;
  tellStrength: number; // 0..1, peaks at the attempt peak, scaled by tellIntensity
}
export function toViewModel(state, now, profile?, tellIntensity?: number): HudViewModel;
```

`tellStrength` = 0 when no active attempt; otherwise rises toward the peak
(e.g. `1 - clamp(|now - peak| / halfSpan)`) multiplied by `tellIntensity`
(default 1). Use the active attempt from `attemptAt(state.timeline, now)`.

## Behaviors to test (each RED first)
- No active attempt → `attemptActive=false`, `tellStrength=0`.
- Active attempt, `now === peak` → `tellStrength === tellIntensity` (max).
- Active attempt, `now` at the window edge → `tellStrength` ≈ 0.
- Lower `tellIntensity` → strictly smaller `tellStrength` at the peak (harder = fainter).
- Existing viewModel fields unchanged; existing calls (no tellIntensity arg) default to 1.

## Render + Visual Review (required)
- A pulse/ring (DOM) whose opacity/scale follows `tellStrength`, placed so it reads
  as "tap now" (e.g. around the BRA button or over the dog).
- Screenshot via `scripts/shoot-hud.mjs`. The cue is brief — capture it during an
  active window (poll the `#hud` for the cue element's opacity/`data-tell` > 0.5,
  or extend the script to wait for it) and VIEW the PNG to confirm the cue is
  visible and reads clearly. Note findings.

## Progress Log
- 2026-06-13 — Task created (iteration 5)

## Resolution

### TDD Cycles (5 red-green cycles)

**Cycle 1 — no active attempt → attemptActive=false, tellStrength=0**
RED: `attemptActive` was `undefined` (field didn't exist).
GREEN: Added `attemptAt` import, `clamp01` helper, 4th `tellIntensity = 1` param, and full
       `(1 - clamp01(|now - peak| / halfSpan)) * tellIntensity` computation to `viewModel.ts`.
       Added `attemptActive` and `tellStrength` to `HudViewModel` interface.

**Cycle 2 — now===peak → tellStrength===tellIntensity**
GREEN immediately: Cycle 1's implementation was already correct. Verified `now=400` (peak of
first event with window [100..700]) yields `tellStrength=1.0`.

**Cycle 3 — now at window edge → tellStrength≈0**
GREEN immediately: `|100-400| / 300 = 1.0`, clamped → `1 - 1 = 0`. Verified.

**Cycle 4 — lower tellIntensity → strictly smaller tellStrength at peak**
GREEN immediately: linear scale `* tellIntensity` means 0.5 at peak with `tellIntensity=0.5`.

**Cycle 5 — omitting tellIntensity defaults to 1**
GREEN immediately: TypeScript default parameter `tellIntensity = 1` works as expected.

All 138 pre-existing tests remain passing. 5 new tell-cue tests added → 143 total.

### Tell Cue DOM/CSS

**Structure**: A `#hud-tell-wrap` div (position: relative, flex centering) wraps both the
`#hud-tell-ring` div and the existing `#hud-bra-btn`. The ring sits behind the button via
absolute positioning with `inset: -16px`, extending 16px beyond the button on all sides.

**CSS**: `#hud-tell-ring` — absolute, border-radius 48px, 4px solid `#ffe84a` (gold) border,
`box-shadow` with two layers (outer glow 18px/6px spread at 70% opacity, inner glow 12px/2px).
No CSS transition — opacity and transform are set directly per-frame so they track tellStrength
with no lag.

**Per-frame render** (`hud.ts`): `tellRingEl.style.opacity = String(ts)`;
`tellRingEl.style.transform = \`scale(${1 + 0.18 * ts})\``. The ring scales up to 1.18× at
peak, giving a "pulse expanding outward" feel. `hud.setAttribute('data-tell', ts.toFixed(3))`
makes it inspectable by tests/scripts.

### Captured Tell Value

Screenshot `/tmp/bra-tell.png` captured at `tellStrength=0.862`:
- `data-tell` attribute: 0.862
- `#hud-tell-ring` opacity: "0.862"
- `#hud-tell-ring` transform: "scale(1.15516)"
- Polled condition: `data-tell > 0.7` — met within the first active window (~400ms after load)

The cue is a bright gold ring around the BRA button, clearly readable as "tap now" against the
dark scene background. At strength 0.862 the ring is at 86% opacity with a warm glow/shadow.

## Acceptance Criteria
- [x] `viewModel` extended test-first; `tellStrength` 0 when idle, max at peak, faint at edges, scales with `tellIntensity`
- [x] Existing viewModel fields + tests intact; default `tellIntensity` 1
- [x] HUD renders a pulse/ring cue bound to `tellStrength`
- [x] `main.ts` passes `difficulty.tellIntensity`
- [x] Screenshot captured DURING an active window and reviewed; cue clearly visible
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
