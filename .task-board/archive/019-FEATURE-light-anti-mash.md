# FEATURE: Light anti-mash — a dead tap is gently discouraged, never punished (P2-6)

**Status**: Backlog
**Created**: 2026-06-27
**Priority**: P2 — the last unbuilt Phase-2 gameplay story. Lower than 018 (the named
trick roster comes first; the spec itself says keep this "secondary to nailing clean tricks").
**Labels**: phase-2, game-logic, tdd, feedback
**Depends on**: 002 (scoring `NONE` tier), 004 (`cueForTier` audio), 016 (learned bar — must
**not** be reduced by this).

## Context & Motivation

Story **P2-6** — *"Mashing should lose (light, secondary)."* *As a player, I want tapping
with nothing to mark to be gently discouraged, so that patience beats spamming even before
full difficulty exists."* Acceptance: *"Light false-mark/confuse + distractors ride along…
but stay **secondary**… keep minimal until the roster feels good."*

Today a dead tap scores `NONE` and **does literally nothing** (correct for Phase 1 — P1-5/P1-0
explicitly deferred any penalty — but P2-6 is the Phase-2 story that adds the *light*
discouragement). This is the only remaining Phase-2 gameplay gap that isn't a new trick. The
fuller confuse/distractor/penalty model is **Phase 4** (P4-2) — this task must stay minimal
and must not pull it forward.

## Decision (recorded here — a game-logic decision the spec defers to the build)

**Minimal, non-punitive discouragement.** A tap that scores **`NONE`** (no scoring window
open — a true "mash") produces:
1. A **light negative feedback cue** — a subtle BRA-button shake + dim and a soft, low "tick"
   that is clearly **not** the reward "Bra!" — so a mash *feels* unrewarding. (X-3 promises a
   payoff on *success*; a dead tap is allowed a small honest "no". The reward audio stays
   gated to OK/PERFECT.)
2. An **escalating mash streak**: consecutive dead taps within a short coalescing window
   escalate the nudge intensity (a clearer "wait" signal); the streak **decays to nothing**
   after a brief quiet period, so one stray tap is barely felt but spamming visibly says stop.
3. **No progress penalty and no fail state** (P2-4 / X-3): the learned bar is **never reduced**
   and real marks always score. Patience wins purely because only well-timed taps earn the
   payoff while mashing earns escalating "no".

**Scope guard:** discouragement targets **`NONE` only** (a dead tap with no window). A
**`MISS`** (window open, mistimed) is *real engagement* and is left exactly as-is — no nudge,
no change. **No** distractors, **no** confuse/false-mark-on-a-real-window, **no** learned-bar
drain — all of that is Phase 4 (P4-2). This is the lightest honest reading of P2-6.

## Affected Components

### Files to Add
- `src/core/mash.ts` — pure, DOM-free mash-streak model (the decision above as logic).
- `src/core/mash.test.ts` — TDD specs (below).

### Files to Modify
- `src/main.ts` — on each tap, if the scored tier is `NONE`, fold the tap into the mash state
  and surface the resulting nudge level to the shell + play the soft "no" tick; any non-`NONE`
  tier clears the streak. The learned-bar update path is untouched (no NONE → no progress
  change — already true; keep it that way).
- `src/app/shell.ts` — a `nudge(level)` hook on the BRA button (a brief shake + dim keyed to
  level); reduced-motion dampens it to a static dim (X-5), never removed.
- `src/audio/markCue.ts` — add a distinct, quiet **dead-tap "no" tick** cue (separate from and
  softer than the reward), gated to fire **only** on a NONE mash. (Keep `cueForTier` for
  OK/PERFECT/MISS unchanged; the mash tick is its own small player call.)

## Technical Approach (game-logic → TDD; the pure model is `mash.ts`)

### TDD slice (red → green), `mash.test.ts`

```ts
// 1. A single dead tap starts a streak of 1.
expect(registerDeadTap(EMPTY_MASH, 1000).streak).toBe(1)

// 2. Dead taps close together escalate the streak; the nudge grows but is capped.
let s = EMPTY_MASH
for (const t of [1000, 1120, 1240]) s = registerDeadTap(s, t)
expect(s.streak).toBe(3)
expect(nudgeLevel(s, 1240)).toBeGreaterThan(nudgeLevel(registerDeadTap(EMPTY_MASH, 0), 0))
expect(nudgeLevel(s, 1240)).toBeLessThanOrEqual(1)

// 3. A gap longer than the coalesce window resets the streak (one stray tap ≈ no nudge).
const after = registerDeadTap(registerDeadTap(EMPTY_MASH, 0).valueOf && registerDeadTap(EMPTY_MASH, 0), 5000)
expect(registerDeadTap(registerDeadTap(EMPTY_MASH, 0), 5000).streak).toBe(1)

// 4. The nudge decays to 0 after a quiet period (mashing pressure fades).
const mashed = registerDeadTap(EMPTY_MASH, 0)
expect(nudgeLevel(mashed, 0)).toBeGreaterThan(0)
expect(nudgeLevel(mashed, 5000)).toBe(0)

// 5. A real scored tap clears the streak (engagement resets discouragement).
expect(clearMash(s).streak).toBe(0)
```

(Refine the exact assertions during red→green; the behaviors above are the contract:
streak-up on close dead taps, capped & decaying nudge, reset on a gap, reset on a real score.)

### Wiring — `main.ts` (before → after)

```ts
// Before — a tap scores; NONE does nothing.
const tier = scoreTap(window, tapTime)
if (tier === 'OK' || tier === 'PERFECT') { playReward(tier); reactAndLearn(tier) }
// (NONE / MISS: nothing)

// After — NONE folds into the mash model and nudges; real tiers clear it.
const tier = scoreTap(window, tapTime)
if (tier === 'NONE') {
  mash = registerDeadTap(mash, tapTime)
  shell.nudge(nudgeLevel(mash, tapTime)) // shake+dim, reduced-motion → static dim
  playDeadTapTick()                      // soft, NOT the reward; silent reward path unchanged
} else {
  mash = clearMash(mash)
  if (tier === 'OK' || tier === 'PERFECT') { playReward(tier); reactAndLearn(tier) }
  // MISS unchanged — real engagement, no nudge
}
```

## Verification / Light e2e
Extend an existing timing spec (or add a small one) to assert, in the running app:
- A tap in IDLE (no window) adds **no** learned-bar progress and plays **no** reward (the
  reward audio path stays silent on a mash) — i.e. mashing can't sneak progress.
- A real OK/PERFECT tap still scores and fills the bar exactly as before (no regression).
Keep the visual shake/dim itself out of the gate (timing-sensitive); judge it by eye if a
quick capture is cheap, but it is **not** a Visual-Review-gated task (it's feedback polish on
a logic feature).

## Risks & Considerations
- **Never a fail state.** Do not reduce the learned bar or block real marks (P2-4/X-3). The
  cue is *feedback only*; only the payoff is withheld (it already is on NONE).
- **Don't touch MISS.** A MISS is a real window mistimed — leave it exactly as today.
- **Stay minimal.** No distractors, no confuse-on-a-real-window, no cooldown that could eat a
  legitimately well-timed tap — all Phase 4. If it grows past "a soft no + escalating nudge",
  it's out of scope.
- **Reduced motion (X-5).** The shake must dampen to a static dim, never vanish entirely (the
  "no" still reads), and the tick audio is unaffected.
- **Audio gating.** The dead-tap tick must be unmistakably quieter/lower than the reward and
  must never fire on OK/PERFECT/MISS; re-confirm the reward stays silent on a mash.

## Acceptance Criteria
- [ ] `src/core/mash.ts` pure model: `EMPTY_MASH`, `registerDeadTap`, `nudgeLevel`,
      `clearMash` — TDD red→green per the contract above (streak up on close dead taps; capped,
      decaying nudge; reset on a gap; reset on a real score). Unit suite green.
- [ ] `main.ts` folds a `NONE` tap into the mash model, nudges the shell, and plays the soft
      tick; any non-`NONE` tier clears the streak; **`MISS` behavior unchanged**.
- [ ] Learned bar is **never reduced** and real marks always score (no fail state) — covered
      by the light e2e (mash adds no progress / no reward; real mark unchanged).
- [ ] BRA-button nudge (shake+dim) keyed to level; reduced-motion → static dim (X-5).
- [ ] Dead-tap "no" tick is distinct from and quieter than the reward and fires only on a
      mash; reward audio stays gated to OK/PERFECT.
- [ ] Verify gate green: `typecheck` · `test` · `build` · `e2e`.
