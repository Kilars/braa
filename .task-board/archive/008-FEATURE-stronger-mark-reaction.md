# FEATURE: Make the successful-mark reaction an unmistakable celebration (PO I1)

**Status**: Done (2026-06-27)
**Created**: 2026-06-27
**Priority**: High — follows 007 (PO Review I1; the North-Star payoff, NS-1 / P1-6)
**Labels**: gameplay, render, reaction, phase-1, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

PO Review **I1** (`specs2.md` → Product Owner Review — 2026-06-27):

> On OK/PERFECT the dog perks up (a small chin/head lift + tail), and PERFECT does read
> bigger than OK — but at the reaction's peak it is only subtly different from the plain
> seated hold. With audio unverifiable, the *visual* payoff alone barely registers as a
> celebration.

The mark landing is the **North Star (NS-1)** and **P1-6** asks for a "clearly positive
reaction." It must be unmistakable **on its own**, not lean on the (owner-gated) voice to
carry the moment. What good looks like (PO): "a crisper head/ear lift, a quick
squash-and-settle, a visible fast tail flurry — with PERFECT distinctly punchier than OK.
Keep paws on the shadow (no float regression)."

**Current state (source):** `src/core/reaction.ts` gives `bounce`/`wag` envelopes;
`src/render/dog.ts:278-285` maps them to a tiny grounded bob (`root.position.y =
reaction.bounce * 0.04`), a chin-up (`head.rotation.x -= 0.34 * bounce`), and a faster
tail (`wagRate += 11`). The amplitudes are too small to read as joy at the peak.

## Desired Outcome

At the reaction peak the dog **unmistakably celebrates** — readable with audio off —
PERFECT distinctly punchier than OK, MISS still flat (no perk-up), and the **paws never
separate from the contact shadow** (D12 — this was a prior Visual-Review blocker).

## Affected Components

### Files to Modify
- `src/core/reaction.ts` (+ `src/core/reaction.test.ts`) — strengthen / shape the pure
  envelope; the testable amplitude relationships live here (TDD).
- `src/render/dog.ts` — map the stronger envelope to a **grounded** celebration:
  crisper head + ear lift, a quick squash-and-settle, a faster tail flurry. Paws stay
  planted (squash via upper-body/scaling, NOT by lifting `root.position.y`).

## Technical Approach

Split: the **envelope shape + PERFECT>OK margin** is pure and test-first (`tdd` skill);
the **pose mapping** is a thin visual layer judged by Visual Review (the captureReactPeak
probe already freezes the peak frame deterministically).

### Pure envelope (TDD — write tests first)
Add a grounded "squash-and-settle" channel (e.g. `pop`) and/or scale the existing peak so
the celebration reads, while keeping everything in [0,1] and settling to rest by
`REACTION_MS`.

#### Before
```ts
return { bounce: clamp01(s * env), wag: clamp01(env) }
```
#### After (illustrative — final shape is the implementer's, locked by tests)
```ts
// pop = a quick grounded squash that settles; scales with strength so PERFECT > OK.
return { bounce: clamp01(s * env), wag: clamp01(env), pop: clamp01(s * env) }
```
Behaviors to test (red → green):
- **PERFECT distinctly punchier than OK:** peak(strength=1) ≥ ~1.6 × peak(strength≈0.55)
  on the celebration channel — a *clear* margin, not a sliver.
- **MISS / no reaction is flat:** `reactionAt(null, …)` and `strength=0` → all channels 0
  (dog stays in the plain seated hold).
- **Settles:** every channel returns to 0 by `t = REACTION_MS` (no stuck perk).
- **Bounded + monotone attack:** channels in [0,1]; rise to the peak by `REACTION_PEAK_MS`
  then ease down (extends existing `reaction.test.ts` coverage).

### Pose mapping (dog.ts — Visual Review, grounded)
#### Before
```ts
root.position.y = reaction.bounce * 0.04 * amp        // barely reads
head.rotation.x -= reaction.bounce * 0.34 * amp       // chin up only
```
#### After (illustrative)
```ts
// Grounded squash-and-settle: scale the body about its planted base + a crisper
// head/ear lift. NO root lift — paws never leave the shadow (D12).
const pop = reaction.pop * amp
torso.scaling.y = breathe * (1 - pop * 0.10)          // quick squash...
chest.scaling.y = 1.05 * breathe * (1 + pop * 0.06)   // ...chest pushes up, feet planted
head.rotation.x -= reaction.bounce * 0.55 * amp       // crisper chin/head lift
earL.rotation.x -= pop * 0.5; earR.rotation.x -= pop * 0.5  // ears perk
// tail flurry already faster via wagRate; widen wagAmp a touch for a visible flurry
```
(Use the real ear/torso/chest mesh handles present in `createDog`; keep `root.position.y`
at 0 or near-0 so the contact shadow stays glued to the paws.)

## Risks & Considerations
- **Float regression (D12, blocking).** The previous reviewer blocked when the rig lifted
  off the shadow. Achieve energy through **squash/scale + posture**, not by raising the
  root. Verify paws-on-shadow in the OK and PERFECT capture frames.
- **Reduced motion (P1-8).** Dampen — do not remove — every new channel (the `amp=0.25`
  path must still show a distinguishable, smaller celebration).
- **Don't desync the cues (P1-7).** Reaction is still driven by the one scored tier from
  `main.ts`; this task changes amplitude/shape only, not the wiring.

## Acceptance Criteria
- [x] Red-first envelope tests: PERFECT peak ≥ clear margin over OK; MISS/none flat;
      every channel settles to 0 by `REACTION_MS`; all bounded [0,1] (`tdd` followed).
      → Added the grounded `pop` channel (snappy attack + early settle) to
      `src/core/reaction.ts`; `reaction.test.ts` 9 tests green within the 44-test suite.
- [x] `dog.ts` maps the envelope to a grounded celebration (head + ear lift, quick
      squash-and-settle, faster tail flurry); `root.position.y` stays ~0 (paws planted).
      → `dog.ts:270-296`: torso/chest scaling squash-and-settle, chin lift 0.6, ear perk,
      wag flurry (rate +11, amp +0.95); `root.position.y = 0` explicitly.
- [x] Reduced-motion path still shows a dampened-but-visible celebration (P1-8).
      → every new channel scaled by `amp` (0.25 under reduced motion), not gated off.
- [x] **Visual Review (blocking):** independent phone-portrait reviewers, audio off,
      confirm via the captureReactPeak OK vs PERFECT frames that the mark reads as an
      unmistakable celebration, PERFECT clearly punchier than OK, MISS flat, and paws
      never leave the shadow. Findings are blocking.
      → **2/2 independent reviewers PASS.** Both confirmed the chin/ear/chest lift reads
      unmistakably vs the neutral apex (03), PERFECT clearly out-punches OK (measured head
      rise +9px OK vs +26px PERFECT; shadow 188→208→224px monotonic tiering — a grow, not
      a detach), and front paws stay inside the contact shadow in 04/05 (D12 resolved).
- [x] Verify gate green: `typecheck` (0 errors) · `test` (44 passed) · `build` (no
      warnings) · `e2e` (4/4 passed).

## Outcome
Closes PO Review **I1** (NS-1 / P1-6). The success payoff now reads as a celebration on
its own with audio off. Captures `04-react-ok.png` / `05-react-perfect.png` regenerated and
reviewed; `03-apex.png` confirms the neutral baseline the celebration now clearly beats.
