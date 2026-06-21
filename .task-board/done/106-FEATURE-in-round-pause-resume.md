# FEATURE: In-round Pause / Resume

**Status**: Done (2026-06-21)
**Created**: 2026-06-20 (iteration 18 scan)
**Priority**: High
**Labels**: ui, logic, gameplay, gap:round-states
**Estimated Effort**: Medium

## Context & Motivation

specs.md §Round States is explicit: *"Pause/resume supported; no timer forces
play."* This is a listed **v1** behavior. The app currently has **no pause** — a
`grep -ni pause src/` is empty. Round-resume **persistence** across quit/reopen
exists (task 086) and a resume-**grace** swallows stray taps after backgrounding
(task 073), but there is no way to *pause an active round in place*: the scheduler
timeline keeps advancing on every `tick()` and the dog keeps offering behaviors.

A player who looks away on mobile either eats false-mark risk (mitigated only by
the 400 ms grace) or watches the round run without them. Pause is a baseline
mobile-game affordance and a named v1 gap. It is also in a **cool domain** (UI)
— the last 15 done tasks skew render / refactor / logic.

## Current State

- `src/main.ts` drives the round: a `tick()` reads `performance.now()`-based time
  against the scheduler `timeline`; `onBraTap` classifies marks against the live
  timeline. There is no pause flag and no clock offset.
- `src/core/scheduler.ts` produces a deterministic timeline of attempts /
  distractors keyed off a round start time; time is "wall clock since round start".
- HUD (`src/ui/hud.ts`) has top-cluster controls (settings `?`, etc.) but no
  pause control and no paused overlay.

## Desired Outcome

- A **pause control** in the training HUD freezes the round: the dog holds, the
  apex tell stops advancing, and **taps are ignored while paused** (no false mark).
- A **resume** returns to exactly where it left off — the timeline must not "skip
  ahead" by the paused wall-clock duration (accumulate paused time and offset the
  round clock so the remaining timeline is intact).
- A clear **paused overlay** (dimmed scene + "Pause" label + a Resume/▶ button),
  opaque and legible on phone-portrait, reduced-motion friendly.
- No regression to resume-grace (073) or round-resume persistence (086).
- (Optional, document the call) auto-pause on `visibilitychange → hidden` so
  backgrounding pauses rather than runs; if added, resume is manual on return.

## Affected Components

### Files to Create
- `src/core/pauseClock.ts` — **pure** accumulated-pause-offset helper (TDD).
- `src/core/pauseClock.test.ts` — its tests.

### Files to Modify
- `src/main.ts` — hold a `paused` flag + a `PauseClock`; `tick()` early-returns
  while paused; `effectiveNow = pauseClock.elapsed(now)` feeds the timeline;
  `onBraTap` ignores taps while paused.
- `src/ui/hud.ts` — pause button + paused overlay + `setPaused(boolean)` on the
  handle; wire button to a `callbacks.onTogglePause`.
- `.docs/tech-decisions.md` — note the pause-clock model + the auto-pause decision.

### Dependencies
- **Internal**: scheduler timeline (read-only), resume-grace (073). None blocking.
- **External**: none.

## Technical Approach

### Architecture Decisions
- **Keep round time monotonic and pure.** Don't mutate timeline timestamps;
  instead translate wall-clock `now` through a pure offset so "round time" pauses.
  This is unit-testable without Babylon/DOM.

### Implementation Steps (TDD — `tdd` skill, vertical slices)
1. Pure `pauseClock`: `createPauseClock()` → `{ pause(now), resume(now),
   elapsed(now), isPaused() }`. One test → impl → repeat:
   - elapsed advances normally before any pause,
   - elapsed is frozen at the pause instant while paused,
   - after resume, elapsed continues from the frozen value (lost wall-time = the
     paused span), idempotent double-pause / double-resume.
2. Wire into `main.ts`: feed `elapsed(now)` to the timeline read; `tick`/`onBraTap`
   no-op while `isPaused()`.
3. HUD pause button + overlay (Visual Review).

### Before / After

**Before** (`src/main.ts`, round time is raw wall-clock):
```ts
const now = performance.now();
const sinceStart = now - roundStartedAt;   // keeps advancing even if "paused"
updateRound(sinceStart);
```

**After**:
```ts
const now = performance.now();
if (pauseClock.isPaused()) return;          // frozen: dog holds, no tell advance
const sinceStart = pauseClock.elapsed(now); // paused spans subtracted out
updateRound(sinceStart);
```

```ts
// src/core/pauseClock.ts (pure, tested)
export function createPauseClock(startNow: number) {
  let pausedAt: number | null = null;
  let lostMs = 0;
  return {
    isPaused: () => pausedAt !== null,
    pause: (now: number) => { if (pausedAt === null) pausedAt = now; },
    resume: (now: number) => { if (pausedAt !== null) { lostMs += now - pausedAt; pausedAt = null; } },
    elapsed: (now: number) => (pausedAt ?? now) - startNow - lostMs,
  };
}
```

### Risks & Considerations
- **Risk**: a tap dispatched on the exact resume frame. **Mitigation**: existing
  resume-grace already swallows the first taps after a visibility resume; reuse /
  extend that window for manual resume too.
- **Risk**: scheduler reads `now` in more than one place. **Mitigation**: route
  every round-time read through `pauseClock.elapsed`.

## Acceptance Criteria

- [x] Pure `createPauseClock` added **test-first** via `tdd` (frozen-while-paused,
      resume-continues, double-pause/resume idempotent) — behavior tested through
      the public functions, not internals.
- [x] Pausing freezes the dog + apex tell and **ignores taps** (no false mark);
      resume continues the same timeline with no skip-ahead.
- [x] Paused **overlay** is opaque, legible on a 390×844 portrait viewport, and
      reduced-motion friendly.
- [x] No regression to resume-grace (073) or round-resume persistence (086).
- [x] **Visual Review (blocking)**: real phone-portrait screenshot of the paused
      state, reviewed by an independent agent. No fabricated screenshots.
- [x] Decision recorded in `.docs/tech-decisions.md`. **specs.md untouched.**
- [x] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

## Resolution (2026-06-21)

Implemented test-first. New pure `src/core/pauseClock.ts` (+ 8 tests) models round
time as "effective time" = wall clock minus accumulated paused spans, frozen while
paused. `main.ts` routes **every** round-time read through `effNow(now) =
pauseClock.elapsed(now)` — the rAF `tick` (timeline loop, confuse expiry, view model,
dog pose) and `onBraTapCommit` (attemptAt/classifyMark/applyMark/rewardLatency/scene
notify). `tick` early-returns while paused (dog holds, tell stops, no timeline loop);
`onBraTapCommit` returns early while paused (taps ignored — no false mark). On resume
the round continues with **no skip-ahead** (verified in a real browser: bar 35 →
frozen 35 while paused → 100 after resume).

HUD: 44px ⏸ pause button (top-left; difficulty selector shifted to `left:68px` to
clear it) + opaque dimmed paused overlay (`rgba(6,12,9,0.88)`) with "Paused" label and
a yellow "▶ Resume" pill; `setPaused()` on the handle, `onTogglePause` callback,
reduced-motion drops the fade. Auto-pause on `visibilitychange → hidden` during
training (manual resume; reuses resume-grace to swallow the resume-frame tap).
Dev-only `__bra.nextPeak()` made frame-correct (adds `lostMs`; 0 when never paused, so
e2e unchanged).

**Files**: created `src/core/pauseClock.ts`, `src/core/pauseClock.test.ts`; modified
`src/main.ts`, `src/ui/hud.ts`, `src/ui/hud.css`, `src/ui/hud.test.ts` (+6 pause
tests), `.docs/tech-decisions.md`.

**Visual Review**: independent agent reviewed `/tmp/bra-paused.png`,
`/tmp/bra-training-pausebtn.png`, `/tmp/bra-pause-diff.png` → PASS-WITH-NITS (no
blocking); nits (uniform dim, 44px tap target, glyph contrast) applied + re-shot.

**Gate**: `typecheck` 0 errors · `test` 781 passed (47 files) · `build` no warnings ·
`e2e` smoke + full-loop PASS.
