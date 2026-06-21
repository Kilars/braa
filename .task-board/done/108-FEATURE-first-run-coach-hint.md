# FEATURE: First-run coach hint — teach the core verb in context

**Status**: Backlog
**Created**: 2026-06-20 (iteration 18 scan)
**Priority**: Medium
**Labels**: ui, onboarding, gap:onboarding
**Estimated Effort**: Small-Medium

## Context & Motivation

specs.md §Onboarding: *"The first session teaches the one core verb — wait for the
apex, tap BRA — on the starter Labrador with a forgiving window and an obvious
target behavior."* Today the only teaching is a **passive** help overlay behind a
`?` button (task 048, `helpPanel.ts`: "Tap BRA on the pulse") — a player must
*choose* to open it. There is **no in-context coach** during the actual first
round; `grep -ni "coach|tutorial"` over `src/` is empty. A brand-new player can
start the first round with no prompt telling them what to do.

The onboarding **drip** (task 022, `onboardingStage`) already hides the selector /
phrases / kennel on a fresh session — the staging skeleton exists; this adds the
one missing piece: an **active, in-context instruction** for the core verb on the
first round. UI/onboarding is a **cool domain** (last 15 done skew render /
refactor / logic).

## Current State

- `src/core/onboarding.ts` — `onboardingStage(masteredCount): Revealed` gates UI
  reveal by mastery count. No "should we coach the core verb?" concept.
- `src/ui/hud.ts` — renders the training HUD; has the swipe-hint affordance
  pattern (`#hud-bra-swipe-hint`) to mirror. No coach element.
- `src/main.ts` — knows `masteredCount` and whether the player has ever marked.
- `helpPanel.ts` — passive how-to overlay (stays; complementary).

## Desired Outcome

- On a **fresh first run** (nothing mastered, no successful mark yet), a clear,
  friendly in-context coach line is shown during the round — e.g.
  **"Vent på pulsen — trykk BRA!"** ("wait for the pulse — tap BRA!") — pointing
  the player at the apex tell + the BRA marker.
- The coach **dismisses itself** after the player's **first successful mark** (and
  never shows again once anything is mastered) — it must not nag.
- Opaque, legible on phone-portrait, reduced-motion friendly, aria-live polite so
  it's announced once.
- Zero impact on the loop for returning players (gated off by progress).

## Affected Components

### Files to Create / Modify
- `src/core/onboarding.ts` (+ `onboarding.test.ts`) — add a **pure**
  `shouldCoachCoreVerb({ masteredCount, hasMarkedSuccessfully })` predicate (TDD).
- `src/ui/hud.ts` — a `#hud-coach` element + `setCoachVisible(boolean)` on the
  handle (mirror the swipe-hint pattern); shown via `renderTraining`.
- `src/main.ts` — track `hasMarkedSuccessfully` (runtime, not persisted beyond the
  existing mastery signal) and drive `setCoachVisible(shouldCoachCoreVerb(...))`.
- `.docs/tech-decisions.md` — note the coach-gating rule.

### Dependencies
- **Internal**: `onboardingStage` (022). None blocking.
- **External**: none.

## Technical Approach

### Implementation Steps (TDD — `tdd` skill, vertical slices)
1. Pure `shouldCoachCoreVerb`: one test → impl → repeat:
   - true when `masteredCount === 0 && !hasMarkedSuccessfully`,
   - false once a successful mark has happened,
   - false when anything is mastered (returning player).
2. HUD `#hud-coach` element + `setCoachVisible`.
3. `main.ts` drives visibility; flips `hasMarkedSuccessfully` on the first
   PERFECT/OK mark.

### Before / After

**Before** (`src/main.ts`, no in-context teaching — only the passive `?` panel):
```ts
// (no coach; first-time players get no prompt during the round)
```

**After**:
```ts
// src/core/onboarding.ts (pure, tested)
export function shouldCoachCoreVerb(p: {
  masteredCount: number; hasMarkedSuccessfully: boolean;
}): boolean {
  return p.masteredCount === 0 && !p.hasMarkedSuccessfully;
}
```
```ts
// src/main.ts
hud.setCoachVisible(shouldCoachCoreVerb({ masteredCount, hasMarkedSuccessfully }));
// on a scoring mark: hasMarkedSuccessfully = true;  -> coach hides for good
```

### Risks & Considerations
- **Risk**: coach overlaps the BRA marker / apex tell. **Mitigation**: place it in
  the upper-center safe area like the trick label; Visual-Review the layout.
- **Risk**: it re-appears for returning players. **Mitigation**: pure predicate
  gated on `masteredCount` + the mark flag; covered by tests.

## Progress Log

- 2026-06-20 — Task created (iteration 18 scan).
- 2026-06-21 — **Implemented + shipped (iteration 18).**
  - Pure `shouldCoachCoreVerb({ masteredCount, hasMarkedSuccessfully })` added
    **test-first** via `tdd` (red → green, 3 cycles: fresh-run true, post-first-mark
    false, returning-player false). `onboarding.test.ts` 23 → 29 tests.
  - HUD: new `#hud-coach` element + `setCoachVisible(boolean)` on the handle (reuses the
    shared `.hud-gated` hide class). Gold attention pill below the trick label; CSS pulse
    removed under `prefers-reduced-motion` (D13); `aria-live="polite"`. 4 jsdom tests on
    the public handle (gated-by-default, reveal, re-hide, instruction text).
  - `main.ts`: runtime `hasMarkedSuccessfully` flag + `refreshCoach()`; shown on round
    start (real + `__setTrick` dev hook), dismissed for good on the first PERFECT/OK mark.
  - **Visual Review (real screenshots, 390×844)**: `/tmp/coach-firstrun.png` (coach
    visible, opacity 1) and `/tmp/coach-after-mark.png` (auto-dismissed, opacity 1→0 after
    a landed apex mark; combo chip takes the slot). Independent review agent →
    **VERDICT: PASS**, no blocking issues (only non-blocking suggestions about the
    *pre-existing* combo-chip geometry).
  - Decision recorded in `.docs/tech-decisions.md` §3k. **specs.md untouched.**
  - Gate: typecheck 0 · test **767** (760 → 767) · build no-warn · e2e (smoke + full-loop) PASS.

## Acceptance Criteria

- [x] Pure `shouldCoachCoreVerb` added **test-first** via `tdd` (fresh-run true,
      post-first-mark false, returning-player false) — tested through the public fn.
- [x] A first-run coach line appears in-context during the first round and
      **auto-dismisses** after the first successful mark; never shown to returning
      players.
- [x] Opaque, legible on a 390×844 portrait viewport, reduced-motion friendly,
      `aria-live="polite"`.
- [x] **Visual Review (blocking)**: real phone-portrait screenshot of the first-run
      coach, reviewed by an independent agent (PASS). No fabricated screenshots.
- [x] Decision recorded in `.docs/tech-decisions.md` (§3k). **specs.md untouched.**
- [x] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

**Next Steps**: Engineering complete; closed to `done`.
