# FEATURE: Surface idle "welcome back" income on return

**Status**: Backlog
**Created**: 2026-06-21 (iteration 24 scan)
**Priority**: Medium-High
**Labels**: ui, economy, kennel, gap:kennel-idle, onboarding-return
**Estimated Effort**: Small

## Context & Motivation

specs.md §Kennel: *"a small, capped passive idle trickle … collected on return"* —
the kennel is the game's **gentle reason to come back**. The economic half is fully
built: on load, `main.ts` computes `idleIncome(save.idleTimestamp, Date.now())` and
`award`s the coins (`src/main.ts:150-156`). **But the player is never told.** `grep -ni
"idle\|earned\|welcome" src/ui/hud.ts` is empty — the coins appear silently in the
balance, so the "you earned something while away" payoff that motivates return visits
**never lands on screen**. This is the single most player-visible v1 gap that is *not*
owner/legal/asset-gated (the licensed-Labrador ship path and Maren voice are; this is
neither). UI/economy-surfacing is a **cold domain** — the last 15 done tasks skew
render-visual (saturated), tuning-refactor (saturated), and test (saturated).

## Current State

- `src/main.ts:150-156` — `const earned = idleIncome(save.idleTimestamp, Date.now());`
  then `if (earned > 0) profile = award(profile, { coins: earned, xp: 0 }, 1);`. The
  grant is invisible: no HUD call, no toast.
- `src/core/kennel.ts` — `idleIncome(...)` is pure + already unit-tested (capped trickle).
- `src/ui/hud.ts` — renders the select/training shells; has the floating-inset pill
  chrome pattern (stats cluster, combo chip, coach pill) to mirror. No idle element.
- Idle income is only granted when `earned > 0` **and** onboarding has revealed the
  economy stage (coins are hidden pre-first-payout, specs §Onboarding) — the toast must
  respect the same reveal gate so a brand-new player never sees a coin toast.

## Desired Outcome

- On returning to the app after time away (idle income > 0 **and** economy revealed), a
  brief, friendly **"Velkommen tilbake! +N 🪙"** toast appears on the **select screen**
  at bootstrap, then fades on its own (it must not require a tap, must not block play,
  and must not appear mid-round).
- Shows **once per launch** (the grant already happens once at load); never shows when
  `earned === 0` or when the economy stage is still hidden (fresh first run).
- Opaque, legible on phone-portrait, `aria-live="polite"` (announced once),
  reduced-motion friendly (dampened fade, not removed — D13).
- Zero change to the economy math — this is presentation glue over an already-correct
  grant.

## Affected Components

### Files to Create / Modify
- `src/core/onboarding.ts` (+ `onboarding.test.ts`) — add a **pure**
  `shouldShowIdleWelcome({ earnedCoins, economyRevealed })` predicate (TDD): true iff
  `earnedCoins > 0 && economyRevealed`. Keeps the gate testable & out of the untested IIFE.
- `src/ui/hud.ts` (+ jsdom coverage in `hud.test.ts`) — a `#hud-idle-welcome` toast
  element + `showIdleWelcome(coins: number)` on the handle (mirror the coach-pill pattern
  from task 108; reuse the floating-inset chrome).
- `src/ui/hud.css` — toast styling + `@media (prefers-reduced-motion: reduce)` branch.
- `src/main.ts` — after the existing grant, call
  `if (shouldShowIdleWelcome({ earnedCoins: earned, economyRevealed: revealed.economy })) hud.showIdleWelcome(earned);`
  (drive off the same `revealed` object already computed for staging).
- `.docs/tech-decisions.md` — note the idle-welcome gating + placement decision.

### Dependencies
- **Internal**: `idleIncome` (kennel), `onboardingStage`/`revealed.economy` (022/096).
  None blocking.
- **External**: none.

## Technical Approach

### Implementation Steps (TDD — `tdd` skill, vertical slices)
1. Pure `shouldShowIdleWelcome` — one test → impl → repeat:
   - true when `earnedCoins > 0 && economyRevealed`,
   - false when `earnedCoins === 0` (nothing accrued),
   - false when `!economyRevealed` (fresh run, coins still hidden).
2. HUD `#hud-idle-welcome` toast + `showIdleWelcome(coins)` (jsdom: hidden by default,
   reveals with the coin count in text, `aria-live="polite"`).
3. `main.ts` glue: call it once at bootstrap behind the predicate.

### Before / After

**Before** (`src/main.ts` — grant is silent):
```ts
const earned = idleIncome(save.idleTimestamp, Date.now());
if (earned > 0) {
  profile = award(profile, { coins: earned, xp: 0 }, 1);
}
// (player never sees that they earned anything)
```

**After**:
```ts
const earned = idleIncome(save.idleTimestamp, Date.now());
if (earned > 0) {
  profile = award(profile, { coins: earned, xp: 0 }, 1);
}
// ...later, once hud + revealed are available at bootstrap:
if (shouldShowIdleWelcome({ earnedCoins: earned, economyRevealed: revealed.economy })) {
  hud.showIdleWelcome(earned); // "Velkommen tilbake! +N 🪙", auto-fades
}
```
```ts
// src/core/onboarding.ts (pure, tested)
export function shouldShowIdleWelcome(p: {
  earnedCoins: number; economyRevealed: boolean;
}): boolean {
  return p.earnedCoins > 0 && p.economyRevealed;
}
```

### Risks & Considerations
- **Risk**: toast fires for a brand-new player before the economy is revealed.
  **Mitigation**: the `economyRevealed` gate in the pure predicate (tested).
- **Risk**: `earned` is captured at load but the toast needs `hud`/`revealed` which are
  created later in bootstrap — make sure `earned` is hoisted/closed over correctly (it is
  already a `let`/`const` in the load block; thread it to the post-hud bootstrap step).
- **Risk**: overlaps the difficulty selector / stats cluster on the select screen.
  **Mitigation**: place it in the upper-center safe area; Visual-Review the layout.
- **Risk**: appears mid-round. **Mitigation**: only called at bootstrap on the select
  screen, never from `tick()`.

## Progress Log

- 2026-06-21 — Task created (iteration 24 scan).
- 2026-06-21 — **Implemented + shipped (iteration 24).**
  - Pure `shouldShowIdleWelcome({ earnedCoins, economyRevealed })` added **test-first** via
    `tdd` (RED → GREEN, 4 cases). `onboarding.test.ts` 34 → 38.
  - HUD `#hud-idle-welcome` toast + `showIdleWelcome(coins)` (mirrors the coach pill): green
    "Velkommen tilbake! +N 🪙" pill, `aria-live="polite"`, slides+fades in, auto-re-gates after
    `IDLE_WELCOME_MS = 4200`. 3 jsdom tests on the public handle. `hud.test.ts` 30 → 33.
  - `main.ts`: hoisted `idleEarned`; after `showSelect()` calls the toast behind the pure gate
    via `onboardingStage(...).economy`. New `__showIdleWelcome` dev/screenshot hook.
  - **Visual Review (real screenshots, 390×844)**: `scripts/shoot-idle-welcome.mjs` → normal +
    reduced-motion. Independent review agent → **VERDICT: PASS** (non-blocking chroma nit only;
    moot vs the 110-coin cap, widest copy "+110 🪙").
  - Decision in `.docs/tech-decisions.md` §"Idle 'Welcome Back' Toast". **specs.md untouched.**
  - Gate: typecheck 0 · test **840** (833 → 840) · build no-warn · e2e (smoke + full-loop) PASS.

## Acceptance Criteria

- [x] Pure `shouldShowIdleWelcome({ earnedCoins, economyRevealed })` added **test-first**
      via `tdd` (earned+revealed → true; zero-earned → false; not-revealed → false).
- [x] A "welcome back +N 🪙" toast appears on return when idle income accrued and the
      economy stage is revealed; auto-fades; never blocks play; never appears mid-round
      or for a fresh first run.
- [x] HUD toast covered by jsdom tests through the public handle (hidden by default,
      shows the coin count, `aria-live="polite"`).
- [x] Opaque, legible on a 390×844 portrait viewport, reduced-motion friendly (dampened
      fade, not removed).
- [x] **Visual Review (blocking)**: real phone-portrait screenshot of the toast on the
      select screen, reviewed by an independent agent (PASS). No fabricated screenshots.
- [x] Decision recorded in `.docs/tech-decisions.md`. **specs.md untouched.**
- [x] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

**Next Steps**: Engineering complete; closed to `done`.

**Technical approach hint**: this is presentation glue over an already-correct,
already-tested economy grant — keep the only new *logic* in the pure predicate, keep the
rest in HUD/CSS, and prove it with a real screenshot.
