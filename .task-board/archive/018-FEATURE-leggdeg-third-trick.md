# FEATURE: Legg deg (settle) — the third starter trick, a distinct settle animation (P2-2 / P2-3)

**Status**: Backlog
**Created**: 2026-06-27
**Priority**: P1 — Phase-2 core. Completes the spec's **named** starter trick set
(Sitt, Ligg, **Legg deg**); the single remaining trick-roster gap in Phase 2.
**Labels**: phase-2, rendering, animation, visual-review
**Depends on**: 012 (multi-trick model), 013 (the `'liedown'` pose precedent).

## Context & Motivation

Phase 2 is "**More tricks, same quality bar.**" Story **P2-2** fixes the starter set
explicitly: *"Starter set: **Sitt**, **Ligg** (lie down), **Legg deg** (settle), then
expand."* Sitt (Phase 1) and Ligg (013) ship; **Legg deg is the one named starter trick
still missing.** Until it lands, P2-2's acceptance is unmet and the roster the selector
(014) offers is incomplete.

P2-2 also forbids reusing a generic pose — *"Never one generic pose reused"* — and warns
the lie-down family must read as **down, clearly different from sit** (D6/D11). Legg deg has
a sharper trap than Ligg did: it must read as a **settle** that is *also distinct from
Ligg's alert sphinx*. A Legg deg that looks like Ligg fails the spirit of "its own specific
behavior," even though both are "down."

> **Domain-saturation note (for the scan record):** visual/rendering is saturated (5 of the
> last 15 done tasks). This task **overrides** the saturation filter for one reason: P2-2's
> starter set is a *named, finite* list and Legg deg is the only member not yet built — there
> is **no non-visual substitute** for "the third trick," and completing the named roster is
> the highest-value remaining Phase-2 move. The other two tasks cut this round (019 anti-mash,
> 020 gate) are logic/QA, so the batch does **not** pile onto the saturated domain.

## Desired Outcome

Selecting **Legg deg** (registry `setTrick('leggdeg')`, exercised via `__braSetTrick`; the
player-facing chip is already wired by the 014 selector, which lists all `TRICKS`) makes the
dog play a clean **settle**: from standing it lowers all the way down and **relaxes** — body
slumped low and long, **head/chin dropped toward the ground** (and/or a gentle roll of the
hip to one side) — to a **clear "fully settled" apex**, then rises back to idle. It reads
unmistakably as a *relaxed down*, **distinct from both the sit and Ligg's alert sphinx**. The
honest apex tell + scoring (trick-parametric since 012) land on the fully-settled instant. No
foot-slide, no ground clipping, no T-pose, no snap. The mark still feels good (OK/PERFECT
reaction). Reduced motion dampens but never removes the settle read (P1-8/X-5).

## Affected Components

### Files to Modify
- `src/core/trick.ts` — widen `TrickId` to include `'leggdeg'`; add a `'settle'` member to
  `PoseKind`; add the `leggdeg` entry to `TRICKS` (own `timings` + `poseKind: 'settle'`).
- `src/render/dog.ts` — `pose()` gains a `'settle'` branch alongside `'sit'` / `'liedown'`:
  keep both existing paths byte-identical; the settle drives a *more relaxed, head-down* low
  rest from the same 0→1 build axis. Reuse the `'liedown'` leg/body machinery where it helps,
  but the **read must differ** (lower/forward head, slumped posture).
- `src/render/scene.ts` — already passes `activeTrick.poseKind` through and stretches the
  contact shadow for the lie-down footprint; confirm the settle gets the same grounded shadow
  treatment (a settle has a long, low footprint too).

### Files to Check / Extend
- `src/core/trick.test.ts` — extend the per-trick invariant coverage (below).
- `e2e/_capture.spec.ts` — add a Legg-deg capture test mirroring the Ligg one, into
  `.screenshots/leggdeg-*`, including a **side-by-side-able** apex vs Ligg's apex frame so the
  reviewer can judge "distinct from Ligg," not just "distinct from sit."

## Technical Approach

Mostly a **rendering** task → **Visual Review is the gate** (TDD-exempt per the scan rules),
**plus a small TDD slice** for the registry contract (the trick model is pure logic; a new
trick must keep the "looks-built == markable" invariant and not collide ids).

### TDD slice (red → green) — registry contract in `trick.test.ts`
The existing suite already asserts a per-trick `holdMs <= windowWidthMs/2` invariant (added
in 013) and that tricks have distinct poses. Add Legg deg to those:

```ts
// Before — the invariant loop only sees sitt + ligg
for (const t of TRICKS) {
  expect(t.timings.holdMs).toBeLessThanOrEqual(NORMAL.windowWidthMs / 2)
}

// After — leggdeg is in TRICKS, so the same loop now guards it too; plus an
// explicit assertion that the three starter tricks are all present & distinct.
it('ships the named starter set, each with a distinct pose', () => {
  const ids = TRICKS.map((t) => t.id)
  expect(ids).toEqual(expect.arrayContaining(['sitt', 'ligg', 'leggdeg']))
  expect(getTrick('leggdeg').poseKind).toBe('settle')
  // settle is its own pose, not a reused sit/liedown (P2-2 "never one generic pose")
  expect(getTrick('leggdeg').poseKind).not.toBe(getTrick('ligg').poseKind)
})
```

### Rendering — `dog.pose()` branches on the new `'settle'` poseKind

```ts
// Before (dog.ts) — two paths
if (poseKind === 'liedown') {
  // ... sphinx: body level+low, forelegs forward, head ALERT/level ...
} else {
  // ... sit, byte-identical ...
}

// After — three paths; settle is a relaxed, head-down low rest, visibly NOT the sphinx
if (poseKind === 'liedown') {
  // ... Ligg sphinx (unchanged) ...
} else if (poseKind === 'settle') {
  // Legg deg: drop the body fully down (reuse the lie-down lowering), but RELAX —
  // chin/head sinks toward the ground (head pitch DOWN, not the sphinx's level),
  // posture slumps, and the dog reads as "settled to rest", clearly calmer/lower
  // than Ligg's alert sphinx. Keep paws/chin grounded on the shadow at the apex.
  // (Tune SETTLE_* constants for legibility on a phone; the Visual Review is the gate.)
} else {
  // ... sit, byte-identical ...
}
```

```ts
// trick.ts — Legg deg joins the registry
{
  id: 'leggdeg',
  label: 'Legg deg',
  // A settle is a slow, deliberate sink-and-relax — a touch longer build than Ligg
  // reads as "giving up the weight". Held plateau MUST stay <= windowWidthMs/2 so a
  // dog that looks settled is always markable (PO C1 / task 007 invariant).
  timings: { idleMs: 1700, buildMs: 900, holdMs: 200, releaseMs: 850 },
  poseKind: 'settle',
}
```

Keep the **"looks-settled == is markable"** invariant (PO C1, task 007): the held plateau
sits inside the scoring window (`holdMs <= windowWidthMs/2`). Keep paws/chin grounded on the
contact shadow at the apex (D12). The `'sit'` and `'liedown'` branches stay byte-identical —
re-confirm Sitt and Ligg capture frames are unchanged.

## Visual Review (blocking — the P2-3 gate)

Spawn independent review agent(s) that look at **real captured frames** on a 390×844 portrait
viewport (use `polish` + the capture probes; never fabricate a frame). They must confirm,
with screenshot evidence:
- The apex reads clearly as a **relaxed settle** — low, slumped, head/chin down — and is
  **distinct from the sit** *and* **distinct from Ligg's alert sphinx** (compare the
  `leggdeg-*-apex` frame against `ligg-03-apex` and `03-apex`).
- Clean motion: no foot-slide, no ground clipping, no T-pose, no loop-boundary snap.
- The apex tell lights only on the fully-settled instant and is dark in IDLE (honest).
- The mark still feels good on Legg deg (OK vs PERFECT distinguishable, paws/chin planted).
- The reduced-motion frame still reads as a *settle* by pose alone.
Findings are blocking — fix before marking done.

## Risks & Considerations
- **"Looks like Ligg" trap.** The single biggest risk. Differentiate by the **head/chin
  dropping to the ground** and a more slumped/relaxed posture (optionally a slight hip roll),
  vs Ligg's level, alert, head-up sphinx. Review explicitly for "could a player tell these two
  apexes apart?"
- **Don't regress Sitt or Ligg.** Both existing branches must stay byte-identical; re-confirm
  their capture frames and the existing unit tests still pass.
- **Capture honesty.** The freeze harness must freeze pose *and* tell together for Legg deg
  too (it already does via `poseFreezeTime`); verify a captured settle apex shows a lit ring
  and a captured mid-build shows a dark/ramping ring.
- **Ground contact.** Chin/paws/belly touch the shadow plane at the apex, not hover or sink.

## Acceptance Criteria
- [ ] `TrickId` widened to include `'leggdeg'`; `PoseKind` gains `'settle'`; `leggdeg` added
      to `TRICKS` with its own `timings` + `poseKind: 'settle'`; `holdMs <= windowWidthMs/2`.
- [ ] `trick.test.ts` (TDD, red→green): starter set `['sitt','ligg','leggdeg']` all present;
      `leggdeg.poseKind === 'settle'` and distinct from Ligg's; per-trick window invariant
      covers the new trick. (Unit suite green.)
- [ ] `dog.pose()` gains a `'settle'` branch; `'sit'` and `'liedown'` paths byte-identical.
- [ ] The settle reads unmistakably as a **relaxed down**, clearly different from **both** the
      sit and Ligg — confirmed by captured phone-portrait frames.
- [ ] Clean animation: no foot-slide, no ground clipping, no T-pose, no loop snap; chin/paws
      grounded on the shadow at the apex (D12).
- [ ] Apex tell honest for Legg deg (lit on the settle apex, dark in IDLE); mark feels good
      (OK/PERFECT reaction distinguishable).
- [ ] Reduced motion dampens but preserves the settle read.
- [ ] **Visual Review passed** by independent reviewer(s) on 390×844 with real screenshots;
      blocking findings fixed (P2-3).
- [ ] Verify gate green: `typecheck` · `test` · `build` · `e2e`.
