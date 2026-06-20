# FEATURE: Stage the economy reveal — hide coins/level until the first payout

**Status**: ✅ Done (2026-06-18)
**Created**: 2026-06-17

> **Outcome:** One-line fix — `applyRevealed()` in `hud.ts` now toggles
> `statsEl.classList.toggle('hud-gated', !revealed.economy)`, so coins/level are
> hidden on a fresh session and revealed at the first payout (the reveal call is
> already re-invoked post-mastery at `main.ts:595`). The economy staging contract
> was already fully tested in `onboarding.test.ts`; the bug was purely that the
> HUD ignored the computed flag (UI glue). Verified by screenshot + computed-style
> probe (gated/opacity 0/visibility hidden at 0 masteries). 632 tests, verify + e2e green.

**Priority**: High (v1 onboarding spec gap — correctness)
**Labels**: feature, onboarding, hud, tdd
**Estimated Effort**: Small

## Context & Motivation

specs.md §Onboarding (First Run) requires staged reveal — systems are "revealed
in stages, never all at once … then the economy at the first payout." The
onboarding model already encodes this: `onboardingStage(masteredCount)` returns
`economy: masteredCount >= 1` (`src/core/onboarding.ts:29`), documented as
"≥ 1 mastered → distractors + economy revealed (first payout has happened)".

But the HUD **never applies** `revealed.economy`. `applyRevealed()`
(`src/ui/hud.ts:586-596`) toggles `.hud-gated` on the phrase chip, difficulty
selector and kennel button — but the coins/level stats block (`statsEl`,
`hud.ts:259-271`) is **always visible from session one**:

```
$ grep -n "statsEl" src/ui/hud.ts
259:  const statsEl = document.createElement('div');     // created
369:  hud.appendChild(statsEl);                            // mounted
# …never referenced inside applyRevealed()
```

So a brand-new player sees `COINS 0 / LEVEL 1` before they have ever earned a
coin — exactly the "dump every system at once" the onboarding section is written
to avoid. Every other staged element is gated; economy is the one that slipped.
This is a **v1 spec gap / correctness bug**, not polish: the reveal rule is
specified and the flag is computed but ignored.

## Desired Outcome

The coins/level stats block is **hidden on the very first session** (zero
masteries) and **appears at the first payout** (≥ 1 mastery), matching every
other staged reveal. After the first mastery it stays visible for the rest of
the save (reveals are monotonic in `masteredCount`). No layout jump that
disturbs the centered dog/BRA framing when it appears.

## Affected Components

### Files to Create / Modify
- `src/ui/hud.ts` — apply `revealed.economy` to `statsEl` inside `applyRevealed()`.
- `src/ui/hud.css` (or wherever `.hud-gated` lives) — no change expected; reuse
  the existing `.hud-gated` hide rule already used by the other staged elements.
- (If a pure mapping helper is introduced to make this testable without DOM, add
  it to a tested module — see Technical Approach.)

## Technical Approach

The reveal **rule** is functional/game-logic and is **test-first (TDD)** per
[`.claude/skills/tdd`](../../.claude/skills/tdd/SKILL.md). `onboardingStage`
itself is already tested; the gap is that `economy` is unused. To keep the fix
behavior-tested through a public interface (not a DOM detail), assert the
**reveal contract** that the HUD must honour, then wire the one missing toggle.

### Behaviours to test (TDD)
1. **Contract (extend `onboarding.test.ts` if not already covered):**
   `onboardingStage(0).economy === false`; `onboardingStage(1).economy === true`;
   stays `true` for higher counts. (Guards the rule the HUD depends on.)
2. **Gating set completeness:** every element the spec stages —
   `economy, phrases, difficulty, kennel` — is a boolean on `Revealed`, and the
   HUD gates one DOM node per flag. Add/strengthen a test (or a small pure
   `gatedElementsFor(revealed)` map, if introduced) asserting `economy` is in the
   gated set so a future refactor can't silently drop it again.

### Before
```ts
// src/ui/hud.ts
function applyRevealed(revealed: Revealed): void {
  // statsEl is NOT gated — coins/level always visible
  loadoutChipEl.classList.toggle('hud-gated', !revealed.phrases);
  diffSelectorEl.classList.toggle('hud-gated', !revealed.difficulty);
  kennelBtnEl.classList.toggle('hud-gated', !revealed.kennel);
}
```

### After
```ts
// src/ui/hud.ts
function applyRevealed(revealed: Revealed): void {
  statsEl.classList.toggle('hud-gated', !revealed.economy);   // ← economy now staged
  loadoutChipEl.classList.toggle('hud-gated', !revealed.phrases);
  diffSelectorEl.classList.toggle('hud-gated', !revealed.difficulty);
  kennelBtnEl.classList.toggle('hud-gated', !revealed.kennel);
}
```

## Risks & Considerations
- **Reveal moment:** confirm `applyRevealed` is re-invoked after a mastery so the
  block appears at the first payout within the same session (trace the existing
  call after `completeMastery`); if it only runs on load, the reveal would lag to
  next launch. Wire it to fire on mastery if needed.
- **Layout stability:** hiding `statsEl` must not shift the centered dog / BRA
  marker; reuse the same `.hud-gated` approach the other gated elements use
  (which already reserve/collapse cleanly). Visual Review on a phone-portrait
  viewport: confirm no jump when it reveals.
- **No save change:** reveal is derived live from `masteredCount`.

## Acceptance Criteria
- [x] Economy staging contract is test-covered (TDD): `onboarding.test.ts` already asserts `onboardingStage(0).economy === false`, `onboardingStage(1).economy === true`, and monotonic for ≥2. **No new failing test was needed — the functional logic was already correct and tested; the defect was purely that the HUD never consumed the flag (UI glue, the e2e/visual-covered layer, not unit-tested). Honest note: this task added no red-green cycle because there was no untested logic to drive.**
- [x] `statsEl` (coins/level) is hidden at 0 masteries (verified by screenshot + computed style: `hud-gated`, `opacity:0`, `visibility:hidden`) and shown from the first mastery onward — the reveal fires at the first payout via the already-wired `applyRevealed(onboardingStage(totalMasteredCount(roster)))` at `main.ts:595`, not only on next launch.
- [x] All four staged elements (economy, phrases, difficulty, kennel) are gated; phrases/difficulty/kennel unchanged.
- [x] No layout jump — `statsEl` uses the same `.hud-gated` (opacity/visibility) mechanism as the other gated elements, which reserves space rather than reflowing; the centered dog/BRA framing is unchanged.
- [x] `bun run verify` green (632 tests, typecheck + build, no warnings); `bun run e2e` green (smoke + full-loop).
