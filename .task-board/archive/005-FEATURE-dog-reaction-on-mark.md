# FEATURE: Dog reaction on a successful mark (P1-6 reaction half)

**Status**: Done
**Created**: 2026-06-27
**Priority**: P0 (Phase 1 core-loop payoff — completes "the mark feels good")
**Labels**: visual, rendering, babylon, gameplay, phase-1
**Estimated Effort**: Medium

## Context & Motivation

Spec P1-6 requires that on a successful BRA the **dog gives a clearly positive reaction**
(perk-up / bounce / tail wag) — the dog itself acknowledges the mark, not just the UI
(D8). Today the dog only plays idle ↔ sit (`src/render/dog.ts` exposes `pose`/`reveal`);
there is no reaction. This is the visual half of P1-6 (audio is task 004); together they
make the payoff land on the beat (X-3, NS-1).

## Desired Outcome

- On a successful mark (OK/PERFECT) the dog plays a brief, clearly **positive** reaction
  — a perk-up / bounce with a livelier tail wag — then settles back to the seated/idle
  pose with no snap.
- **PERFECT reads brighter than OK** (bigger bounce / faster wag), matching the audio
  brightness from task 004.
- **No reaction on Miss / dead tap** (nothing to celebrate).
- Reduced motion: the reaction is **dampened, not removed** — still clearly a happy
  reaction distinguishable by pose (P1-8, X-5).
- No new visual bugs: no T-pose, no foot-slide, no clipping, stays centered (P1-9, D12).

## Affected Components

### Files to Create
- `src/core/reaction.ts` — pure reaction-envelope (TDD).
- `src/core/reaction.test.ts` — envelope tests.

### Files to Modify
- `src/render/dog.ts` — apply a reaction offset (bounce/perk/wag) on top of the pose.
- `src/render/scene.ts` — expose `react(tier, now)`; drive the envelope each frame.
- `src/main.ts` — call `scene.react(tier, now)` on a scored OK/PERFECT tap.

## Technical Approach

**Test-first for the envelope (TDD — `.claude/skills/tdd/SKILL.md`).** Keep the *timing
shape* of the reaction a pure, tested function; keep the *mesh application* visual.

```ts
// src/core/reaction.ts
export interface ReactionState { bounce: number; wag: number } // 0..1 amplitudes
// strength scales PERFECT > OK; before start or after it decays to 0 → resting.
export function reactionAt(startTime: number | null, now: number, strength: number): ReactionState
```

Behaviors to test:
- No active reaction (`startTime === null`) → `{ bounce: 0, wag: 0 }` (rest).
- At `now === startTime` the envelope is rising (bounce > 0).
- The envelope **decays back to ~0** after its duration (e.g. ~600 ms) — returns to rest.
- A higher `strength` (PERFECT) yields a strictly larger peak bounce than a lower one (OK).

Then wire it (visual, Visual-Review-gated, not unit-tested):

```ts
// dog.ts — pose() gains an optional reaction it adds on top of the base pose
pose(sitAmount, now, reducedMotion, reaction /* ReactionState */) {
  // ...existing pose...
  const amp = reducedMotion ? 0.3 : 1
  root.position.y = reaction.bounce * 0.18 * amp          // a grounded hop, never a float-away
  tail.rotation.z += reaction.wag * 0.5 * amp             // livelier wag on top of idle sway
}
```

```ts
// scene.ts — remember the trigger; map tier→strength; feed reactionAt() each frame
let reactStart: number | null = null
let reactStrength = 0
function react(tier: MarkTier, now: number) {
  if (tier !== 'OK' && tier !== 'PERFECT') return        // nothing to celebrate
  reactStart = now
  reactStrength = tier === 'PERFECT' ? 1 : 0.55
}
// in the render loop:
const reaction = reactionAt(reactStart, now, reactStrength)
dog.pose(st.sitAmount, now, reducedMotion, reaction)
```

### Before
```ts
// main.ts
const tier = scene.scoreTapNow(performance.now())
if (tier === 'NONE') return
tierReadout.textContent = tier
```

### After
```ts
const now = performance.now()
const tier = scene.scoreTapNow(now)
scene.react(tier, now)        // dog perks up on OK/PERFECT; no-op otherwise
if (tier === 'NONE') return
tierReadout.textContent = tier
```

## Technical Approach — Visual Review (blocking, P1-10, X-6)
- Run the **`polish`** skill on the reaction.
- Spawn independent **phone-portrait (390×844)** review agents that look at real captured
  frames of the reaction at peak (OK vs PERFECT) and confirm: reads as a happy dog, no
  T-pose/slide/clip, stays centered, PERFECT clearly bigger than OK. Findings are
  **blocking**. Extend `e2e/_capture.spec.ts` to freeze a reaction-peak frame (drive via
  a deterministic `__braReact` probe) — do not fabricate screenshots.

## Risks & Considerations
- **Risk**: a bounce that lifts the dog off its shadow (floating, breaks D12/P1-1).
  **Mitigation**: keep bounce small and grounded; the blob shadow stays put; review it.
- **Risk**: reaction fights the sit pose mid-build. **Mitigation**: it adds on top and
  decays to 0; verify no snap when it ends.

## Acceptance Criteria
- [x] `reactionAt` written test-first: rest when inactive, rises at start, decays to rest,
      PERFECT peak > OK peak (failing tests before impl)
- [x] Dog plays a clear positive reaction on OK/PERFECT; none on Miss/dead tap
- [x] PERFECT reaction visibly bigger than OK; settles back with no snap
- [x] Reduced motion dampens (not removes) the reaction; dog stays centered, no
      T-pose/slide/clip
- [x] Passes independent phone-portrait Visual Review (real captured frames); `polish`
      pass folded into the task-006 full-loop close-out
- [x] Verify gate stays green (typecheck/test/build/e2e)

## Resolution (2026-06-27)

Done via TDD + a blocking phone-portrait Visual Review.

**Logic (test-first):** `src/core/reaction.test.ts` (6 tests) → `src/core/reaction.ts`.
`reactionAt(startTime, now, strength)` is a pure attack-decay envelope (650 ms, peak at
14%) returning normalized `{ bounce, wag }`: rest when inactive/out-of-window, active just
after the start, decays to rest, and PERFECT (strength 1) peaks above OK (0.55).

**Visual wiring (Visual-Review-gated):** `dog.pose` gained an optional `reaction` it adds
on top of the base pose; `scene.react(tier, now)` records the trigger + tier→strength
(PERFECT 1 / OK 0.55; MISS/NONE no-op) and feeds `reactionAt` each frame. `main.ts` scores
the tier once and fans it to audio + reaction together (one source of truth, sets up 006).

**Visual Review (blocking):** 3 independent phone-portrait reviewers over real captured
frames (`.screenshots/04-react-ok.png`, `05-react-perfect.png`, vs `03-apex` baseline;
added a `__braCaptureReactPeak` probe + capture frames that freeze the perk-up's peak).
First round split 1 PASS / 1 BLOCK — the BLOCK was PERFECT **floating off its contact
shadow** (D12). Root cause: translating the whole rig upward. Fixed by making it a
*seated perk-up* — the lift is now a whisper (`bounce * 0.04`), the energy reads from
posture (chin-up `* 0.34`, livelier/faster tail) and the contact shadow grows slightly
with the reaction (`scene.ts`) so the paws never separate. Re-review: PASS, blocker
resolved, no regressions; PERFECT clearly bigger than OK.

Gate green: typecheck 0 · test **39 passed** · build no warnings · e2e 3 passed.
Note: `e2e/_capture.spec.ts` remains a TEMPORARY non-gate review harness.
