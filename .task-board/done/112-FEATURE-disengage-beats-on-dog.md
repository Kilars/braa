# FEATURE: Express intermediate disengage beats on the dog (itch / flop / bark)

**Status**: DONE (2026-06-21, iteration 23) · **Priority**: High
**Resolves**: the remaining slice of on-hold `098-FEATURE-engagement-disengagement.md`
(walk-off + call-back already shipped in 107; reward-latency wiring in 100 — this is
the last open piece: the *graded escalation on the dog itself*). **098 is now closed.**

## Delivered
TDD: `DogVisual` extended with `'itch'|'flop'|'bark'`, `DogVisualOpts.beat?: DisengageBeat`,
and `dogVisualState` routes the beat onto **idle lulls only** (never masks `offering`; yields
to `mastered`/`disengaged`/`confused`/`distractor`) — 10 new tests (red→green). `main.ts`
computes `beat = disengageBeat(meter)` once and threads it into `updateDog` + the idle-pant
gate. Procedural poses in `dogPose.ts` (itch = head-cock + scratch wobble; flop = low crouch +
head-down; bark = head-up + sharp bounce), a graded cool-withdrawal tint ramp in `scene.ts`
(itch warm-grey → flop cool-grey → bark steely-blue → the cool walk-off blue) + subtle
flop/bark shrink. `dogAnimationMap.ts` maps the new states to literal imported-rig clips
(itch→Scratching, flop→Lie, bark→Bark; 4 tests). Static pose channels survive reduced motion
(D13). **Visual Review PASS** — real phone-portrait screenshots via new `scripts/shoot-beats.mjs`
(each capture waits for `offering`→beat to land at the gap start, so it can't race the cycle);
the escalation reads as a clear, funny, graded story on the dog. Full gate green: typecheck 0 ·
**833 tests** · build no-warn · e2e (smoke + full-loop) PASS. Decision in tech-decisions
§"Intermediate disengage beats on the dog". specs.md untouched.

## What
The engagement meter drains on sloppy/false marks. The pure model already emits the
full graded escalation — `disengageBeat(level)` → `engaged → itch → flop → bark →
walk-off` (`src/core/engagement.ts:69`) — and the **HUD mood pill** reflects it. But
on the *dog*, only the empty-meter `walk-off` (task 107) is expressed; the intermediate
beats **itch / flop / bark** produce no change to the dog's pose or tint. A player
watching the dog sees nothing escalate until it suddenly trots off.

Spec §"Wrong-behavior beats & disengagement": *"good timing keeps the dog eager;
sloppy/false marks or slow rewards drain it and the dog gets visibly more 'done with
you'… Escalation is graded (itch → flop → bark → walk-off), so it stays funny, never
punishing."* The dog is the game's primary state channel (spec §The Dog) — this signal
must be readable **off the dog**, not only the HUD pill.

## Scope
- **Pure first (TDD):** route the active beat into the dog visual state. The beats are
  an **ambient personality layer over lulls** — they replace the plain `idle` state
  when engagement is low, and never override an active correct `offering` (the player
  must always be able to read the markable behavior), nor `confused`/`happy`/`distractor`/
  `walk-off` (which keep their precedence). Mastered → happy and walk-off → disengaged
  still win.
- **Express (visual):** distinct pose + tint for `itch` (head-scratch tilt/lean),
  `flop` (low bored crouch, tail down), `bark` (head-up bounced "sass"). Procedural —
  **no licensed-Labrador clips required** (same approach as 107's walk-off).
- **Thread:** pass the current `DisengageBeat` from `main.ts` into `updateDog`/`dogPose`
  the same way `disengaged` is already threaded (`src/main.ts:800`, `:813`).
- **Reduced motion:** dampen, don't remove (D13) — each beat must still read via pose +
  tint with motion damped.

## Out of scope
- Per-bone retarget / imported-clip beats (epic phase 2 — gated on the licensed model).
- Reworking the existing `distractor` pose (D9) — leave it as-is; the new beats are a
  separate meter-driven layer, not the distractor.

## Technical Approach

**1. Extend the visual type + routing (pure, TDD — `src/render/dogState.ts`):**
```ts
// BEFORE
export type DogVisual = 'idle' | 'offering' | 'confused' | 'happy' | 'distractor' | 'misbehaving' | 'disengaged';
export interface DogVisualOpts {
  untrain?: boolean;
  disengaged?: boolean;
  // …
}

// AFTER
export type DogVisual =
  | 'idle' | 'offering' | 'confused' | 'happy'
  | 'distractor' | 'misbehaving' | 'disengaged'
  | 'itch' | 'flop' | 'bark';
export interface DogVisualOpts {
  untrain?: boolean;
  disengaged?: boolean;
  /** Current engagement beat (task 112). itch/flop/bark replace plain `idle` during
   *  lulls so the meter's escalation reads on the dog, not only the HUD pill. */
  beat?: import('../core/engagement').DisengageBeat;
  // …
}
```
In `dogVisualState`, after the existing precedence (happy → disengaged → confused →
offering → distractor), map the beat onto what would otherwise be `idle`:
```ts
// BEFORE (tail of normal-trick branch)
if (attemptAt(state.timeline, now) !== null) return 'offering';
if (distractorActiveAt(state.timeline, now)) return 'distractor';
return 'idle';

// AFTER
if (attemptAt(state.timeline, now) !== null) return 'offering';
if (distractorActiveAt(state.timeline, now)) return 'distractor';
// Lull: surface the escalating off-task beat instead of plain idle (task 112).
if (opts?.beat === 'bark') return 'bark';
if (opts?.beat === 'flop') return 'flop';
if (opts?.beat === 'itch') return 'itch';
return 'idle';
```
Tests (in `src/render/dogState.test.ts`): a low-meter `beat:'itch'` during a lull →
`'itch'`; an active correct attempt with `beat:'bark'` → still `'offering'` (beat never
masks the markable behavior); `beat:'engaged'` → `'idle'`; `disengaged` (walk-off) still
wins over any beat; `mastered`/`confused` still win.

**2. Thread the beat from the loop (`src/main.ts`):**
```ts
// BEFORE
const disengaged = isDisengaged(disengageBeat(engagementMeter));
// …
if (sceneApi) sceneApi.updateDog(state, tnow, { trickId, untrain, disengaged, peakProximity, tellStrength });

// AFTER
const beat = disengageBeat(engagementMeter);
const disengaged = isDisengaged(beat);
// …
if (sceneApi) sceneApi.updateDog(state, tnow, { trickId, untrain, disengaged, beat, peakProximity, tellStrength });
```
(Also pass `beat` into the `dogVisualState(...)` call in the idle-pant gate at
`src/main.ts:804` so a sulking dog doesn't pant as if idle.)

**3. Poses (`src/render/dogPose.ts`) + tint/scale (`src/render/scene.ts`):** add an
`itch`/`flop`/`bark` arm to `dogPose()` and to `applyVisualTint`/`scaleFor`
(`src/render/scene.ts:389`, `:423`). Suggested reads, mirroring the existing
`DISENGAGED_*` constants pattern:
- `itch` — slight head-tilt + a periodic hind-leg/head "scratch" lean; near-neutral tint.
- `flop` — low crouch (negative `crouchY`), tail-down, slow breathing; cool/muted tint.
- `bark` — head-up, small repeated bounce (sass); a warmer "agitated" tint.

Reuse the `reducedMotion` damping already plumbed through `dogPose`.

## Done when
- Pure routing TDD-covered (red → green per vertical slice; never all-tests-then-all-code).
- itch/flop/bark each render a visibly distinct pose **and** tint on the procedural dog,
  driven live by the engagement meter, and revert cleanly to idle when the meter refills.
- Beats never mask an active correct `offering`; walk-off/confused/happy precedence intact.
- Reduced-motion: each beat still distinguishable via pose + tint with motion damped (D13).
- **Visual Review (blocking):** spawn a review agent — drive the app on a phone-portrait
  viewport, drain the meter via `window.__setEngagement(0.6 / 0.4 / 0.15 / 0)`, screenshot
  each beat, confirm itch→flop→bark→walk-off reads as a graded, funny escalation on the dog.
- `bun run typecheck` · `bun run test` · `bun run build` (no warnings) · `bun run e2e` green.
- On completion, move on-hold `098` to done (this was its last remaining slice) and note it.

## Acceptance criteria
- [ ] `DogVisual` extended with `'itch' | 'flop' | 'bark'`; `DogVisualOpts.beat` added.
- [ ] Failing test first: `dogVisualState` routes a low-meter beat onto `idle`-lulls only.
- [ ] Test: an active correct attempt + any beat still returns `'offering'`.
- [ ] Test: `disengaged` (walk-off), `confused`, and `mastered` all out-precede a beat.
- [ ] `main.ts` threads `beat` into `updateDog` and the idle-pant `dogVisualState` call.
- [ ] `dogPose.ts` renders a distinct pose for each of itch/flop/bark.
- [ ] `scene.ts` gives each beat a distinct tint (+ scale where it helps the read).
- [ ] Reduced-motion path keeps every beat distinguishable (pose + tint), motion damped.
- [ ] Visual Review agent confirms the graded escalation reads on the dog (screenshots).
- [ ] Full verify gate green (typecheck · test · build · e2e).
- [ ] On-hold `098` moved to done with a note that 112 closed its final slice.
