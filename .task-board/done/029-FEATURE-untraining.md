# FEATURE: Untraining — mark the absence of a bad habit (TDD + render)

**Status**: Done
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: core, render, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Spec Future: "Untraining — the dog has a bad habit (jumping, barking); the player
marks its absence / restraint rather than a behavior. A new verb on the same tap,
reinforcing the bully→best-friend arc." Add ONE untraining trick that inverts the
mark semantics: mark during the CALM windows, not while the dog misbehaves.

## Current State

`tricks.ts` tricks are all "do a behavior". Scheduler attempts = the correct
behavior. dogState shows offering/distractor/etc.

## Approach (keep it minimal — reuse existing systems by inverting)
- Add an untraining trick (e.g. id `no-jump`, name "Ikke hopp") with an `untrain: true` flag.
- For an untraining round, the markable "correct" window is the CALM gap, and the
  "bad habit" occupies the other windows (where marking = false mark). Implement this
  by inverting which timeline windows count as the active attempt — a pure helper
  `untrainAttemptAt(timeline, now)` (calm = attempt; bad-habit event = null) OR a flag
  on the round that swaps attempt/distractor roles. Keep it pure + tested.
- Dog visual: during the bad habit, show a distinct "misbehaving" look (e.g. bounce/jump
  or agitated tint) so the player learns to NOT mark it and to mark the calm.

## Affected Components
- Modify: `src/core/tricks.ts` (untrain flag + the trick) + test
- Create/modify: a pure inversion helper (in scheduler.ts or round.ts) + test
- Modify: `src/render/dogState.ts` (a 'misbehaving' state for untraining bad-habit windows) + test; `scene.ts` render it
- Modify: `src/main.ts` (use the untraining attempt logic when the active trick is untrain)
- Dependencies: `scheduler.ts`, `round.ts`, `dogState.ts`, `tricks.ts`; Blocking: 004, 015, 021, 023

## Behaviors to test (each RED first)
- The untraining trick has `untrain: true`; normal tricks false.
- The inversion helper: during a bad-habit window → not markable (null/false-mark); during calm → markable (attempt). Test both.
- dogState returns the misbehaving state during a bad-habit window in untraining (precedence relative to others).
- A normal trick is unaffected by the inversion (regression).

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Enter an untraining round; capture a 'misbehaving' frame (poll a data attr). VIEW it;
  confirm the bad-habit look is distinct and the calm look invites marking.

## Progress Log
- 2026-06-14 — Task created (iteration 10)

## Resolution

### Red-green cycles

**Cycle 1 — tricks.ts (`untrain` field + `no-jump` trick)**
- RED: added tests for `UNTRAIN_TRICKS[0]` having `id: 'no-jump'`, `untrain: true`, and all `STARTER_TRICKS` having falsy `untrain`
- GREEN: added `untrain?: boolean` to the `Trick` interface; added `UNTRAIN_TRICKS` array with `no-jump` ("Ikke hopp", learnMult=0.8, windowMult=0.9, distractorBonus=0.3, untrain=true); updated `lookupTrick` to search both arrays

**Cycle 2 — scheduler.ts (`untrainAttemptAt`)**
- RED: added 5 tests for `untrainAttemptAt`: null during distractor, null during attempt window, non-null Attempt during calm gap, Attempt covers the gap, null for empty timeline
- GREEN: implemented `untrainAttemptAt` — if `distractorActiveAt` or `attemptAt` return truthy → null; otherwise derive the calm gap boundaries from sorted event spans and return an `Attempt` covering that gap with `peak = midpoint`, `peakRadius = min(80, gapWidth/4)`

**Cycle 3 — dogState.ts (`'misbehaving'` visual + opts)**
- RED: added 6 tests for untraining opts: misbehaving during distractor, offering during calm gap, idle during attempt window, regression tests confirming normal tricks unaffected, mastered wins over misbehaving
- GREEN: added `'misbehaving'` to `DogVisual` union; added `DogVisualOpts { untrain?: boolean }`; updated `dogVisualState` to accept optional third arg — in untrain mode: distractor → 'misbehaving', calm → 'offering', else → 'idle'

### Inversion approach

The inversion is clean — same timeline, inverted consumer logic. Normal tricks: attempt window = markable, distractor = penalised. Untraining: distractor window = NOT markable (misbehaving visual), calm gap = markable (offering visual). `untrainAttemptAt` derives a synthetic `Attempt` from the gap boundaries so `classifyMark` works unchanged.

### Misbehaving visual

- **Misbehaving**: vivid red sphere (`Color3(0.85, 0.2, 0.15)`) with red emissive glow, fast bouncy vertical jump animation (`misbehavingPhase += 0.55` per frame) — the sphere leaps upward (`jumpHeight = abs(sin(phase)) * 0.45`) with small lateral sway. Clearly signals "bad behavior, don't mark".
- **Calm/offering (untraining)**: same warm bright sphere as normal offering — warm tan glow + subtle scale-up — visually invites marking. The contrast between bouncing red and calm warm is obvious.

### Screenshot

Both frames captured from live dev server (real Playwright, not synthesized):
- `/tmp/bra-untrain.png` — misbehaving frame (red bouncing sphere)
- `/tmp/bra-untrain-calm.png` — calm/offering frame (warm sphere)
States observed during polling: `['idle', 'misbehaving', 'offering']`

## Acceptance Criteria
- [x] Untraining trick + inversion helper written test-first; calm = markable, bad habit = not
- [x] dogState shows a distinct 'misbehaving' look during the bad habit; normal tricks unaffected (regression test)
- [x] main.ts uses untraining semantics only for untrain tricks
- [x] Screenshot of a misbehaving frame reviewed (real) — `/tmp/bra-untrain.png`
- [x] Pure cores no DOM imports
- [x] `bun run test` green (282 tests, 267 original + 15 new); `bun run typecheck` clean; `bun run build` succeeds
