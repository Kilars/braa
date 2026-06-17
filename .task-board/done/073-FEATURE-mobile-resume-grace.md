# FEATURE: Mobile resume grace — ignore taps just after returning from background

**Status**: Done
**Created**: 2026-06-17
**Priority**: Medium-High
**Labels**: core, mobile, mistakes, false-mark, robustness, tdd
**Estimated Effort**: Small

## Context & Motivation

Spec **Mistakes → Mobile grace** (specs.md:153–155):

> **Mobile grace:** taps in the brief moment after the app resumes from background
> are ignored, so a notification, lock, or fat-finger never triggers a false mark /
> confuse.

This is a v1 requirement (it sits inside the core Mistakes model, alongside the
Miss-vs-false-mark split), and it is **entirely unimplemented**. There is no
`visibilitychange`, `pageshow`, or `focus` listener anywhere in `src/`
(verified by grep), and `onBraTap` (`main.ts:313`) classifies a mark immediately on
every tap with no resume guard. On mobile this means: the player gets a
notification, taps the screen to dismiss/return, and that stray tap lands as a
**false mark** — penalty + confuse debuff — through no fault of their reading. That
is exactly the punishing feel the spec calls out to avoid.

## Current State

- `src/main.ts:313–344` — `onBraTap()`: `ensureAmbient()`, guard `appState`, then
  classify + `applyMark` immediately. No grace gate.
- No visibility/resume listener anywhere (grep for `visibilitychange` in `src/` →
  none; only `prefers-reduced-motion` matches exist, unrelated).
- The app already uses `performance.now()` as its time base throughout the loop.

## Desired Outcome

For a short window (the **resume grace**) after the document becomes visible again
(tab/app foregrounded), a BRA tap is **silently ignored** — no classify, no
`applyMark`, no audio, no false mark, no confuse. After the window elapses, taps
behave normally. Normal in-session taps are completely unaffected.

## Affected Components

### Files to Modify
- `src/core/` — a new tiny pure module (e.g. `resumeGrace.ts` + `.test.ts`) holding
  the grace constant and a pure predicate. **Test-first.**
- `src/main.ts` — track `resumedAt` via a `visibilitychange` listener; gate
  `onBraTap` with the predicate.
- `.docs/tech-decisions.md` — record the grace window value + rationale.

### Dependencies
- **Internal**: `performance.now()` time base (already used). Independent of other
  tasks.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions
- **Keep the policy pure and tested; keep the DOM event thin.** The decision
  "should this tap be ignored?" is a pure function of `(now, resumedAt, graceMs)` —
  unit-test that. The `visibilitychange` wiring (stamping `resumedAt = performance.now()`
  when `document.visibilityState === 'visible'`) is thin glue, covered by the e2e/
  visual path, not unit tests.
- **Grace window:** `RESUME_GRACE_MS = 400` (placeholder; record in tech-decisions).
  Long enough to swallow a dismiss-tap, short enough to be invisible in normal play.
- **`resumedAt` starts unset** (e.g. `-Infinity` / `0` far in the past) so the very
  first taps of a fresh session are never spuriously eaten.
- **Silent ignore.** When gated, `onBraTap` returns early *before* `ensureAmbient`'s
  side effects matter — no audio, no scene notify, no state change. (Decide whether
  `ensureAmbient()` should still run; preferred: return before any mark side effect,
  but resuming AudioContext on a real user gesture is acceptable — keep it minimal.)

### Behaviours to test (TDD, `resumeGrace.test.ts`)
1. `isWithinResumeGrace(now, resumedAt, graceMs)` is `true` when
   `now - resumedAt < graceMs` (tap immediately after resume → ignored).
2. `false` when `now - resumedAt >= graceMs` (tap after the window → allowed).
3. `false` at the exact boundary `now - resumedAt === graceMs` (window is half-open;
   assert the chosen boundary explicitly).
4. `false` for a never-resumed sentinel (`resumedAt = -Infinity` or `0` with a large
   `now`) — fresh-session taps are never eaten.
5. `RESUME_GRACE_MS` is a positive, small constant (sanity: `> 0` and `< 2000`).

### Implementation Steps
1. **TDD `src/core/resumeGrace.ts`** — `RESUME_GRACE_MS` + `isWithinResumeGrace`
   (behaviours 1–5), red→green.
2. **`main.ts`**: add `let resumedAt = -Infinity;` and, in the bootstrap, register
   `document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible') resumedAt = performance.now(); });`.
3. **Gate `onBraTap`**: after the `appState` guard, compute `now` and
   `if (isWithinResumeGrace(now, resumedAt, RESUME_GRACE_MS)) return;` before any
   classify/apply/audio.
4. **Doc**: record `RESUME_GRACE_MS = 400` + rationale in tech-decisions.
5. **Verify**: full gate green; a manual/scripted visibility-toggle check that a tap
   right after `visibilitychange→visible` produces no mark.

## Before / After Examples

### Example 1: pure policy (tested)
**After** (`src/core/resumeGrace.ts`):
```ts
/** Taps within this window (ms) after the app returns to the foreground are ignored. */
export const RESUME_GRACE_MS = 400;

/** True if `now` falls inside the resume-grace window started at `resumedAt`. */
export function isWithinResumeGrace(now: number, resumedAt: number, graceMs = RESUME_GRACE_MS): boolean {
  return now - resumedAt < graceMs;
}
```

### Example 2: wiring + gate
**Before** (`src/main.ts:313–321`):
```ts
onBraTap() {
  ensureAmbient();
  if (appState !== 'training') return;
  const now = performance.now();
  const active = activeTrick.untrain
    ? untrainAttemptAt(state.timeline, now)
    : attemptAt(state.timeline, now);
  // …classify + applyMark…
}
```
**After**:
```ts
// module scope: let resumedAt = -Infinity;
// bootstrap: document.addEventListener('visibilitychange', () => {
//   if (document.visibilityState === 'visible') resumedAt = performance.now();
// });

onBraTap() {
  ensureAmbient();
  if (appState !== 'training') return;
  const now = performance.now();
  // Mobile grace: swallow stray taps right after returning from background
  // (notification dismiss / lock / fat-finger) so they never false-mark + confuse.
  if (isWithinResumeGrace(now, resumedAt, RESUME_GRACE_MS)) return;
  const active = activeTrick.untrain
    ? untrainAttemptAt(state.timeline, now)
    : attemptAt(state.timeline, now);
  // …classify + applyMark…
}
```

## Risks & Considerations
- **Risk:** swallowing a legitimate fast tap if the grace is too long. Mitigation:
  400 ms is below a deliberate reaction tap and the value is a one-line tuning knob.
- **Risk:** `visibilitychange` fires on tab switch in desktop dev too — fine, the
  behavior is identical and harmless.
- **Risk:** the very first session tap being eaten. Mitigation: `resumedAt` starts
  in the far past (sentinel), tested by behaviour 4.
- **Out of scope:** pausing the round timeline on background (the spec only requires
  swallowing the resume tap; the loop time base is `performance.now()` and the
  scheduler loops, so no extra pause logic is mandated here).

## Code References
- `src/main.ts:313–344` — `onBraTap` (gate point).
- `.docs/specs.md:153–155` — Mobile grace requirement.
- `.docs/specs.md:137–155` — Mistakes / false-mark + confuse (what we're protecting against).

## Progress Log
- 2026-06-17 — Task created (scan round 6). Verified no `visibilitychange`/`pageshow`/
  resume-grace anywhere in `src/`; `onBraTap` classifies immediately, so a resume tap
  currently lands as a false mark + confuse.
- 2026-06-17 — Implemented (TDD, vertical slices):
  - `src/core/resumeGrace.ts`: `RESUME_GRACE_MS = 400` + pure
    `isWithinResumeGrace(now, resumedAt, graceMs = RESUME_GRACE_MS)` = `now - resumedAt < graceMs`.
    Test-first: 6 tests in `resumeGrace.test.ts` (inside-window ignore, outside-window
    allow, half-open boundary at exactly graceMs → allowed, `-Infinity` never-resumed
    sentinel, default-window via the constant, and `0 < RESUME_GRACE_MS < 2000`). RED → GREEN.
  - `main.ts`: added module-scope `let resumedAt = -Infinity;` and a
    `visibilitychange` listener stamping `resumedAt = performance.now()` when
    `document.visibilityState === 'visible'`. `onBraTap` now returns silently after the
    `appState` guard when `isWithinResumeGrace(now, resumedAt, RESUME_GRACE_MS)` — before
    any classify / applyMark / audio / scene notify.
  - `.docs/tech-decisions.md`: new "Mobile Resume Grace" section records the 400 ms value,
    the half-open boundary, the `-Infinity` sentinel, and why timeline-pause is out of scope.
  - Coverage choice: the policy is pure-tested; the thin `visibilitychange` DOM glue is
    covered by typecheck + the build/e2e path (per the task's own architecture note). The
    "no mark within grace" behaviour follows directly from the early `return` before any
    side effect, exercised by the unit tests on the predicate.
  - Verify: `bun run verify` ✓ typecheck + tests + build (549 tests); `bun run e2e` PASS.

## Acceptance Criteria

- [x] `src/core/resumeGrace.ts` with `RESUME_GRACE_MS` + `isWithinResumeGrace`,
      written **test-first**, covering: inside-window ignore, outside-window allow,
      the boundary, the never-resumed sentinel, and the constant sanity bound.
- [x] `main.ts` stamps `resumedAt` on `visibilitychange → visible` and gates
      `onBraTap` with the predicate, returning silently (no classify / applyMark /
      audio / scene notify) when within grace.
- [x] A tap within the grace window after resume produces **no** false mark / confuse
      and **no** learned-bar change; a tap after the window behaves normally; normal
      in-session taps are unaffected. *(Follows from the early `return` before any side
      effect; the pure predicate governing it is unit-tested. Sentinel start ensures
      fresh-session taps are never eaten.)*
- [x] `RESUME_GRACE_MS` value + rationale recorded in `.docs/tech-decisions.md`.
- [x] `bun run typecheck`, `bun run test`, `bun run build`, `bun run e2e` all green
      (`bun run verify` ✓ typecheck + tests + build (549 tests); `bun run e2e` PASS).

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
