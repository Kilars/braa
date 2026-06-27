# FEATURE: Timing & scoring core (apex window + tap tiers) — TDD

**Status**: Done
**Created**: 2026-06-27
**Completed**: 2026-06-27
**Priority**: High (Phase 1 — the heart of the verb; pure logic, no assets)
**Labels**: logic, tdd, phase-1
**Estimated Effort**: Medium

## Context & Motivation

Phase 1 is "the perfect single mark." The scoring brain — does a tap land PERFECT / OK
/ MISS relative to a sit's apex window — is pure, deterministic logic that can and must
be built **test-first** (X-6 TDD gate), independent of the 3D scene. Building it next
(after scaffolding) lets the dog-scene task wire into a proven core.

## Desired Outcome (spec P1-4, P1-5, P1-7)

A pure module that, given a sit timeline (start → apex → end) and a tap time, returns a
tier: **PERFECT** (inside the apex band at the peak), **OK** (inside the window,
off-peak), **MISS** (just outside an active window — no penalty in Phase 1). A tap with
no window open returns "nothing to mark" (no penalty, no sound). Tuning constants live
in a named table (see tech-decisions §7a/§8 for the deprecated game's audited values as
a reference, not a binding).

## Affected Components
### Files to Create
- `src/core/mark.ts` — `scoreTap(window, tapTime) → MarkTier`
- `src/core/mark.test.ts` — red-green-refactor: boundaries, peak band, miss, dead tap
- `src/core/window.ts` — apex-window model (open/apex/close times)

## Technical Approach
- Strict TDD via the `tdd` skill: one failing test → minimal impl → repeat.
- No DOM, no Babylon — runs in the default vitest (node) environment.
- Honest apex: PERFECT band must be centered on the *actual* scoring peak (P1-4).

## Acceptance Criteria
- [x] `scoreTap` covered test-first: PERFECT band, OK window, MISS edge, dead tap
- [x] No penalty path exists in Phase 1 (confuse/penalty is explicitly out — P1-0)
- [x] Tuning constants are a single named table, not magic numbers
- [x] `bun run test` green; `bun run typecheck` 0 errors

## Progress Log

- 2026-06-27 — Taken in-progress; built test-first per the `tdd` red-green loop.

## Resolution

Built the pure Phase-1 scoring core test-first (genuine red → green: wrote
`mark.test.ts` first, confirmed it failed because the module was missing, then
wrote the minimum impl to green). Files created:

- `src/core/tuning.ts` — `MarkTuning` + `NORMAL_TUNING` (`windowWidthMs: 400`,
  `peakRadiusMs: 80`), the single named table. Values are the deprecated game's
  audited NORMAL constants (tech-decisions §8, table 7c) used as a Phase-1
  reference, not a binding. Leaf module — imports nothing from `src/core/*`.
- `src/core/window.ts` — `ApexWindow` (`open/apex/close/peakRadius`, timeline ms)
  + `windowAtApex(apexTime, tuning?)`, which straddles the apex by half the
  window width so the PERFECT band is honestly centered on the peak (P1-4).
- `src/core/mark.ts` — `MarkTier = 'PERFECT' | 'OK' | 'MISS' | 'NONE'` and the
  pure `scoreTap(window, tapTime)`. No false-mark/penalty tier exists (P1-0).

**Model / design note.** The spec distinguishes a **MISS** ("just outside an
active sit's window") from a **dead tap** ("no window open simply does nothing").
The pure core encodes this as the `window` argument: an `ApexWindow` while a sit
is active (a tap outside `[open, close]` → `MISS`) versus `null` when nothing is
active (→ `NONE`). The 800 ms `activeSpan` from §8 — *when* the scheduler hands a
window vs `null` — is a render/scheduler concern, deliberately kept out of this
pure module so it stays a deterministic function of `(window, tapTime)`. The
400 ms scoring window and 80 ms PERFECT band live inside the `ApexWindow`.

**Tests (12, in `mark.test.ts`).** windowAtApex centering + tuning-derived
bounds + parameterization by a passed table; PERFECT at apex and on both
inclusive band edges; OK just off-peak and on both inclusive window edges; MISS
just outside and far outside an active window (not NONE); NONE for `null`; a
Phase-1 scope guard sweeping the timeline asserting outcomes are *exactly*
{PERFECT, OK, MISS, NONE} (no penalty tier can appear) and that all four are
reached; and a determinism check.

**Verify gate (all green):** `typecheck` 0 errors · `test` 16 passed (4 prior +
12 new) · `build` succeeded, no warnings · `e2e` 1 passed.

**Note for task 003.** The new core is pure library code not yet imported by
`main.ts`, so Vite tree-shakes it out of the production bundle for now — expected.
The dog-scene task wires `scoreTap`/`windowAtApex` in, firing the apex tell on
`window.apex` (the real scoring peak, P1-4).
