# FEATURE: Ligg (lie-down) — the first expansion trick, a distinct animation with its own apex (P2-2 / P2-3)

**Status**: Done
**Created**: 2026-06-27
**Completed**: 2026-06-27
**Priority**: P1 — Phase-2 core (the first proof that "more tricks" holds the quality bar)
**Labels**: phase-2, rendering, animation, visual-review
**Estimated Effort**: Medium
**Depends on**: 012 (multi-trick model) — needs the `TrickDef` / `poseKind` seam.

## Context & Motivation

Phase 2 is "**More tricks, same quality bar**." Story **P2-2** demands every trick "visibly
perform its **specific** behavior with a clear apex" and explicitly forbids reusing one
generic pose; **P2-3** requires each trick to pass **its own Visual Review** before it
counts as done. Task 012 builds the trick *model* but the dog still only *animates* Sitt.
This task adds the first real expansion trick — **Ligg (lie down)** — as a genuinely
distinct animation, so Phase 2 has two tricks that look different and each reads honestly.

The spec calls out the failure mode to avoid (P2-2, D6/D11): *"The lie-down tricks read as
**down**, clearly different from sit."* A Ligg that looks like a low sit fails the gate.

> **Domain-saturation note (for the scan record):** visual/rendering is saturated (4 of the
> last 15 done tasks). This task overrides the saturation filter because **P2-2 has no
> non-visual substitute** — "more tricks" *is* new animation — and it is the single
> remaining way to progress the current phase's core. The other two tasks in this batch
> (012 model, 014 selector) are logic/UI, so the batch is not piling onto the saturated
> domain.

## Desired Outcome

Selecting **Ligg** (via the model's `setTrick('ligg')`, exercised here through the
`__braSetTrick` probe; the player-facing selector is task 014) makes the dog play a clean
**lie-down**: from standing it lowers its front, slides its forelegs forward, and settles
its belly toward the ground to a **clear "fully down" apex**, then rises back to idle. It
reads unmistakably as **down**, not as a deep sit. The honest apex tell + scoring (already
trick-parametric from 012) land on the fully-down instant. No foot-sliding, no clipping
through the ground, no T-pose, no snapping. The mark still feels good (reaction fires on
OK/PERFECT). Reduced motion dampens but never removes the down read (P1-8/X-5).

## Affected Components

### Files to Modify
- `src/core/trick.ts` — add the `ligg` entry to `TRICKS` (its own `timings` + `poseKind:
  'liedown'`).
- `src/render/dog.ts` — `pose()` switches on the active trick's `poseKind`: keep the sit
  path exactly as-is for `'sit'`; add a `'liedown'` path that drives a distinct lie-down
  pose from the same 0→1 build amount (front lowers, forelegs extend, body settles).
- `src/render/scene.ts` — pass the active trick's `poseKind` into `dog.pose(...)` (the
  scene already holds `activeTrick` after 012).

### Files to Check
- `src/render/scene.ts` capture harness (`setPose`, `captureReactPeak`, `poseFreezeTime`)
  — must produce honest **Ligg** Visual-Review frames at build amounts 0.3/0.5/0.7/apex
  for the active trick, same as it does for Sitt.

## Technical Approach (rendering task → Visual Review is the gate, not TDD)

Per the scan rules, pure rendering/3D tasks are TDD-exempt and instead carry a **Visual
Review** acceptance criterion. Keep the pure timing untested-by-new-unit-tests here (012
already covers `trickStateAt`); the deliverable is a legible, bug-free lie-down on the
running app, reviewed on a phone-portrait (390×844) viewport.

### Before — pose draws only the sit (dog.ts:251)
```ts
pose(sitAmount, now, reducedMotion, reaction = NO_REACTION) {
  const s = clamp01(sitAmount)
  // ... sit kinematics only: haunches drop, chest rises ...
}
```

### After — pose branches on the active trick's poseKind
```ts
// dog.ts — the scene passes poseKind through; one 0→1 build axis, two kinematic paths.
pose(buildAmount, now, reducedMotion, poseKind = 'sit', reaction = NO_REACTION) {
  const a = clamp01(buildAmount)
  if (poseKind === 'liedown') {
    poseLieDown(a)   // front lowers, forelegs slide forward, belly settles to ground
  } else {
    poseSit(a)       // UNCHANGED — today's sit kinematics, byte-identical
  }
  applyIdleAndReaction(now, reducedMotion, reaction) // shared ambient + perk-up layer
}
```
```ts
// trick.ts — Ligg joins the registry with its own cadence + pose
{
  id: 'ligg',
  label: 'Ligg',
  // A slightly longer build than Sitt reads as a deliberate lowering; tune for
  // legibility on a phone (the apex must be an obvious, held "down" instant).
  timings: { idleMs: 1600, buildMs: 800, holdMs: 200, releaseMs: 800 },
  poseKind: 'liedown',
}
```

The lie-down must keep the **same "looks down == is markable"** invariant Sitt has (PO C1,
task 007): the held fully-down plateau must sit inside the scoring window — keep `holdMs <=
windowWidthMs/2`. Keep paws grounded on the contact shadow at the apex (D12).

## Visual Review (blocking — the P2-3 gate)

Spawn independent review agent(s) that look at **real captured frames** on a 390×844
portrait viewport (use the `polish` skill + the capture probes; never fabricate a frame).
They must confirm, with screenshot evidence:
- The apex pose reads clearly as **lying down** — belly toward ground, forelegs extended —
  and is **obviously distinct from the sit** (side-by-side Sitt vs Ligg apex).
- Clean motion: no foot-slide, no ground clipping, no T-pose, no snap between loop ends.
- The apex tell lights on the fully-down instant and is dark in IDLE (honest, trick-parametric).
- The mark still feels good on Ligg (OK vs PERFECT reaction distinguishable, paws planted).
- Reduced-motion frame still reads as "down" by pose alone.
Findings are blocking — fix before marking done.

## Risks & Considerations
- **"Low sit" trap.** The single biggest risk is a Ligg that reads as a deep sit. Push the
  chest/chin toward the ground and slide the forelegs *forward* so the silhouette is long
  and low, not folded and upright. Review explicitly for this.
- **Don't regress Sitt.** The `'sit'` branch must stay byte-identical; re-confirm the Sitt
  Visual-Review frames are unchanged (reuse 009/008 expectations).
- **Capture honesty.** The freeze harness must freeze pose *and* tell together for Ligg too
  (it already does for Sitt via `poseFreezeTime`); verify a captured Ligg apex shows a lit
  ring and a captured Ligg build shows a dark/ramping ring.
- **Ground contact.** Belly/paws must touch the shadow plane at the apex, not hover or sink.

## Acceptance Criteria
- [ ] `ligg` added to `TRICKS` with its own `timings` + `poseKind: 'liedown'`; held
      fully-down plateau stays inside the scoring window (`holdMs <= windowWidthMs/2`).
- [ ] `dog.pose()` branches on `poseKind`: `'sit'` path byte-identical; new `'liedown'`
      path drives a distinct lower-and-settle from the same 0→1 build amount.
- [ ] The lie-down reads unmistakably as **down**, clearly different from the sit, with a
      clear held apex — confirmed by captured phone-portrait frames.
- [ ] Clean animation: no foot-slide, no ground clipping, no T-pose, no loop-boundary snap;
      paws/belly grounded on the shadow at the apex (D12).
- [ ] Apex tell honest for Ligg (lit on the down apex, dark in IDLE); mark feels good
      (OK/PERFECT reaction distinguishable on Ligg).
- [ ] Reduced motion dampens but preserves the down read.
- [x] **Visual Review passed** by independent reviewer(s) on 390×844 with real screenshots;
      blocking findings fixed (P2-3).
- [x] Verify gate green: `typecheck` · `test` · `build` · `e2e`.

## Completion Notes (2026-06-27)

**Implemented.** Ligg ships as a genuinely distinct lie-down (sphinx/sploot), clearly
different from the sit — confirmed by independent Visual Review on a 390×844 viewport.

**Changes**
- `src/core/trick.ts` — `TrickId` widened to `'sitt' | 'ligg'`; `ligg` added to `TRICKS`
  with its own cadence (`idle 1600 / build 800 / hold 200 / release 800`) and
  `poseKind: 'liedown'`. `holdMs (200) <= windowWidthMs/2 (200)` — the "looks-built ==
  markable" invariant holds (PO C1 / task 007).
- `src/render/dog.ts` — `pose()` now takes `poseKind` and branches: the `'sit'` path is
  byte-identical (every transform unchanged; front legs are explicitly reset to their
  planted construction values so a lie→sit switch is clean). New `'liedown'` path drives
  the whole rig down+long from the same 0→1 build axis: body drops & stays level, forelegs
  swing forward onto the ground, hind legs splay back-and-down to rest on the shadow, tail
  trails back with a damped wag, head rests low. Shared ambient/reaction block is
  parametrized on the generic build amount `a` (== sit `s` for sit → byte-identical) plus a
  per-pose head pitch + tail pitch/wag scale.
- `src/render/scene.ts` — passes `activeTrick.poseKind` into `dog.pose()`, and stretches +
  slides the contact shadow forward for the lie-down's long footprint (driven by build
  amount; zero for the sit, so the sit shadow is unchanged).
- `src/core/trick.test.ts` — added: Ligg is a distinct lie-down trick (different poseKind &
  timings from Sitt); and a **per-trick** invariant test `holdMs <= windowWidthMs/2` so no
  future trick can violate "looks-built == markable". (51 unit tests green.)
- `e2e/_capture.spec.ts` — added a Ligg capture test (`__braSetTrick('ligg')` + the same
  honest pose/tell freeze) shooting stand / build 0.3·0.5·0.7 / apex / OK+PERFECT reaction /
  reduced-motion frames into `.screenshots/ligg-*`.

**Visual Review.** Two independent reviewers (then two more for fix verification) on real
captured frames. First pass found 3 blocking issues — (1) the wag swung the tail into a
detached-looking stick over the low body in reaction frames, (2) forepaws floated off the
front of the round shadow, (3) OK/PERFECT hard to distinguish. All fixed (tail trails back +
damped wag; shadow stretched/shifted; tier delta now reads via head-lift). A follow-up nit —
the off-side hind leg read as a floating blob (the sit's >90° fold lifts the paw up) — was
also fixed by swinging the hind legs sub-90° back-and-down onto the shadow. Final verdict
from both re-reviewers: **SHIP**.

**Sitt regression check.** The `'sit'` branch is byte-identical; the existing Sitt
capture (`.screenshots/03-apex.png` etc.) is unchanged and the 49 prior tests still pass.

**Gate:** `typecheck` 0 errors · `test` 51 passed · `build` no warnings · `e2e` 6 passed.
