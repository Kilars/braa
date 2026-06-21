# FEATURE: Contextual onboarding coach for the distractor reveal

**Status**: Backlog
**Created**: 2026-06-21 (iteration 21 scan)
**Priority**: High
**Labels**: feature, onboarding, ux
**Estimated Effort**: Medium

## Context & Motivation

specs.md §Onboarding (First Run): systems are "**revealed in stages**, never all
at once: distractors arrive around the second trick, then the first phrase unlock,
then the economy at the first payout, with the kennel last."

The staging itself is implemented (`onboardingStage`, task 022/096) and the first
core-verb coach is implemented (task 108, `shouldCoachCoreVerb` → `#hud-coach`).
But there is **no contextual coaching at each reveal** — each new system just
silently appears in the HUD. The single highest-value missing moment is the
**distractor reveal**: at `masteredCount >= 1` the dog starts offering *wrong*
behaviors the player must **not** mark (a false mark penalises + confuses). A
brand-new player gets no explanation of why the dog is suddenly "wrong" or why a
tap was punished — a real confusion/churn point the spec explicitly calls out.

This task adds one contextual coach pill for the first distractor-enabled round,
reusing the proven task-108 pattern (pure gate + dismissible HUD pill +
reduced-motion-safe + Visual Review). (Phrase-reveal and kennel-reveal coaching
are noted as follow-ups, not in scope here — keep this focused.)

## Current State

- `src/core/onboarding.ts` — `onboardingStage(masteredCount)` reveals
  `distractors: masteredCount >= 1`; `shouldCoachCoreVerb({masteredCount,
  hasMarkedSuccessfully})` gates the existing first-run pill.
- `src/ui/hud.ts` — a single `#hud-coach` gold pill + a `setCoachVisible(...)`
  control on the public HUD handle (task 108). Text is currently fixed to the
  core-verb hint.
- `src/main.ts` — owns the runtime onboarding/coach wiring: calls
  `applyRevealed(onboardingStage(totalMasteredCount(roster)))` after each mastery
  and drives `setCoachVisible` from `shouldCoachCoreVerb`.

## Desired Outcome

The **first time a player is in a round with distractors active** (the
`masteredCount === 1` band — distractors are revealed but still new), a short,
distinct coach pill appears, e.g. *"Noen ganger gjør hunden noe annet — ikke mark
da. Bare BRA på «{trick}»."* ("Sometimes the dog does something else — don't mark
then. Only BRA on «{trick}».") It auto-dismisses on the first scoring mark of that
round and never nags returning, experienced players.

## Affected Components

### Files to Modify
- `src/core/onboarding.ts` — add pure `shouldCoachDistractors(progress)` gate.
- `src/core/onboarding.test.ts` — TDD the new gate (red → green, vertical slices).
- `src/ui/hud.ts` — let the coach pill show distractor text (extend
  `setCoachVisible` to accept an optional text/variant, or add a sibling control);
  keep reduced-motion + aria parity with the existing pill.
- `src/main.ts` — drive the new pill from `shouldCoachDistractors`, resetting its
  dismissal when a `masteredCount === 1` round starts and setting it on the first
  scoring mark of that round (mirror the 108 wiring; transient runtime flag, **no
  GameSave change** — same as 108).
- `.docs/tech-decisions.md` — short note under the onboarding/coach section
  (§3k neighbourhood) recording the distractor-coach gate. **specs.md untouched.**

### Dependencies
- **Blocking**: none. Builds directly on task 108's pattern.

## Technical Approach

### Architecture Decisions
- **Pure gate, mirrors 108.** Keep the decision in `onboarding.ts` so it is
  TDD-covered and DOM-free; `main.ts` owns only the runtime flag plumbing.
- **Transient dismissal, like 108.** No persisted flag. The pill shows while
  `masteredCount === 1` and a runtime `distractorCoachDismissed` is false; it is
  reset on entering such a round and set true on the first scoring mark there.
  Because the band only lasts until the 2nd mastery, it self-limits and never
  nags. (Re-showing on a return visit at the same stage is acceptable/helpful.)
- **One pill element.** Reuse `#hud-coach` with swapped text rather than adding a
  second floating element, to keep HUD stacking/chrome unchanged.

### Behaviors to test (TDD — `onboarding.test.ts`)
1. `masteredCount === 0` → `false` (core-verb stage owns the screen).
2. `masteredCount === 1` & not dismissed → `true`.
3. `masteredCount === 1` & dismissed → `false`.
4. `masteredCount >= 2` → `false` (distractors are no longer new).

### Implementation Steps
1. **Red**: write the first failing test for `shouldCoachDistractors`.
2. **Green**: minimal implementation; repeat per behavior (vertical slices).
3. Extend the HUD coach control to render the distractor text
   (reduced-motion + aria parity).
4. Wire `main.ts`: reset-on-round-start / dismiss-on-first-mark; ensure the
   core-verb pill (108) and this one never show simultaneously.
5. **Visual Review** (blocking): real phone-portrait screenshot at the
   `masteredCount === 1` round — pill legible, well-placed, not clashing with the
   loadout/combo chrome, dismisses on a scoring mark.
6. tech-decisions note. **specs.md untouched.**

### Risks & Considerations
- **Risk**: the two coach pills overlap/contradict. **Mitigation**: gates are
  mutually exclusive by `masteredCount` (0 vs 1); assert in wiring.
- **Risk**: pill nags after the player understands. **Mitigation**: dismiss on
  first scoring mark + the band self-limits at `masteredCount >= 2`.

## Before / After Examples

**Before** (`src/core/onboarding.ts`): only `shouldCoachCoreVerb` exists.

**After** (`src/core/onboarding.ts`):
```ts
/** Contextual coach for the first distractor-enabled round (masteredCount === 1
 *  band): teaches "don't mark the wrong behavior". Auto-dismisses on the first
 *  scoring mark of that round. Pure — no DOM. */
export function shouldCoachDistractors(progress: {
  masteredCount: number;
  dismissed: boolean;
}): boolean {
  return progress.masteredCount === 1 && !progress.dismissed;
}
```

**Before** (`src/main.ts`): coach driven only by `shouldCoachCoreVerb`.
**After** (`src/main.ts`, sketch):
```ts
let distractorCoachDismissed = false;
// on round start:
if (totalMasteredCount(roster) === 1) distractorCoachDismissed = false;
// in the scoring-mark handler (PERFECT/OK):
distractorCoachDismissed = true;
// in the HUD refresh:
const coachVerb = shouldCoachCoreVerb({ masteredCount, hasMarkedSuccessfully });
const coachDist = !coachVerb &&
  shouldCoachDistractors({ masteredCount, dismissed: distractorCoachDismissed });
setCoachVisible(coachVerb || coachDist, coachDist ? distractorHint(activeTrick) : undefined);
```

## Code References
- `src/core/onboarding.ts` (`shouldCoachCoreVerb`, `onboardingStage`).
- `src/ui/hud.ts` (`#hud-coach`, `setCoachVisible`).
- `src/main.ts` (coach wiring; `applyRevealed`).
- tech-decisions §3k (task 108 coach decision).

## Progress Log
- 2026-06-21 — Task created (iteration 21 scan). Extends task 108's coach pattern
  to the distractor reveal — the highest-value uncoached onboarding moment.
- 2026-06-21 — **Implemented & verified (DONE).**
  - TDD pure gate `shouldCoachDistractors({ masteredCount, dismissed })` in
    `src/core/onboarding.ts`; 4 boundary behaviors + a cross-gate mutual-exclusion
    guard added to `onboarding.test.ts` (red→green, vertical slices).
  - HUD: `setCoachVisible(visible, text?)` now swaps `#hud-coach` text + adds
    `.coach-wide` for the wrapped distractor copy; reverts to the core-verb text when
    `text` is omitted. New `.coach-wide` CSS (width matched to `#hud-callback-hint`);
    aria-live + reduced-motion parity kept. jsdom coverage added to `hud.test.ts`.
  - `main.ts`: per-round runtime flag `distractorCoachDismissed` (no GameSave change),
    reset in `onSelectTrick` + `__setTrick`, set on the round's first scoring mark;
    `refreshCoach` drives both pills with an explicit `!coachVerb` exclusivity guard.
    Added `__setMasteredCount(n)` dev/screenshot hook.
  - **Copy refined in polish pass**: "ikke trykk da" (game's marker voice), not the
    Anglicised "mark" from the task's example wording.
  - **Visual Review PASS** (independent agent, 390×844 portrait,
    `scripts/shoot-distractor-coach.mjs`): pill legible & well-placed, distinct from the
    core-verb pill, dismisses on a scoring mark, absent at `masteredCount >= 2`.
  - tech-decisions §3l added. specs.md untouched.
  - Gate green: typecheck 0 · 815 tests · build no warnings · e2e SMOKE + FULL-LOOP.

## Acceptance Criteria
- [x] `shouldCoachDistractors` added to `onboarding.ts`, **TDD** (red→green, one
      behavior per slice); the 4 behaviors above are covered in `onboarding.test.ts`.
- [x] The distractor coach pill renders distinct text on first exposure
      (`masteredCount === 1`), auto-dismisses on the first scoring mark, and never
      shows for `masteredCount === 0` or `>= 2`.
- [x] The two coach pills are never visible simultaneously.
- [x] Reduced-motion + aria parity with the existing `#hud-coach` pill.
- [x] **Visual Review (blocking)**: real phone-portrait screenshot confirms the
      pill is legible, well-placed, and dismisses correctly — findings treated as
      blocking polish.
- [x] tech-decisions note added; **specs.md untouched.**
- [x] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

**Status**: Done — moved to `.task-board/done/` 2026-06-21.
