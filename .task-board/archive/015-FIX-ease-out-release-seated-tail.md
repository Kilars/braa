# FIX: Ease-out the sit RELEASE so "looks seated" == "is markable" (PO Review C1)

**Status**: Done
**Created**: 2026-06-27
**Completed**: 2026-06-27
**Priority**: P0 — core-loop fairness; a fresh PO directive against the running game (serves NS-1 / P1-3)
**Labels**: phase-2, game-logic, tdd, bugfix, po-directive
**Depends on**: nothing (pure timing change in `sitCycle.ts`); benefits every trick (Sitt + Ligg + future)

## Context & Motivation

Fresh **Product Owner Review — 2026-06-27** directive (the only section the PO pass
touches), found by driving the **real** BRA button through the **real** scoring path on a
390×844 portrait viewport:

> **C1 — A residual "looks-seated-but-MISS" tail at the start of stand-up.** The old
> flat-hold dead zone is gone (the 200 ms hold now ends exactly as the window closes), but
> **RELEASE eases *in* slowly**, so the dog stays *visually fully seated* for ~130 ms after
> the window closes. Frozen at apex+250 ms the dog is **98.5 % seated** and at apex+300 ms
> **94.5 % seated** — both pixel-indistinguishable from the apex — yet both score **MISS**
> with the apex ring already dark. The stand-up only becomes visible around apex+350 ms.
> *What good looks like:* make the dog **visibly leave the seat the instant scoring closes**
> — give RELEASE an **ease-*out* start** (immediate upward lift off the apex) instead of the
> current slow ease-in. Keep PERFECT centered on the apex. **The test: a tap on any frame
> where the dog still looks fully seated must never score MISS.**

This is the same P1-3 / NS-1 intent as task 007 ("mark off the dog *itself*, not the UI"),
but on the **release leg** rather than the hold. Task 007 trimmed `holdMs` so the *plateau*
matched the window; it did not change the **easing**, so the smoothstep release still lingers
near fully-seated past the close. This task closes that residual tail.

### Root cause (precise)

`sitStateAt` (`src/core/sitCycle.ts:111`) eases RELEASE with `smoothstep(1 - x)`. Smoothstep
is **symmetric ease-in-out** — *zero slope at both ends*. So at the start of RELEASE (the
instant the window closes) the dog barely moves: `sitAmount ≈ 0.985` at apex+250 ms,
`≈ 0.945` at apex+300 ms. The pose says "fully seated" while the score says MISS and the ring
is dark. We want an **ease-out** descent on RELEASE — steep at the start (immediate lift),
gentle at the end (no snap into idle). The scoring window is **unchanged** (still symmetric
±200 ms, PERFECT centered on the apex); only the *pose curve on the release leg* changes, so
the visual "seated" read ends where scoring ends. This is animation-only — honest scoring is
untouched.

The fix lives in the shared `sitStateAt`, so it corrects the tail for **every** trick (Sitt,
Ligg, and any future trick) at once — the same quality bar per trick (P2-3).

## Desired Outcome

On the running app, the moment the scoring window closes the dog **visibly starts standing
up** — no frame past the close still reads as "fully seated." HOLD still scores ≥ OK
throughout; PERFECT stays centered on the apex; the stand-up still lands smoothly in idle
(no snap, no foot-slide, no overshoot). Reduced-motion is unaffected (this is a pose-curve
shape change, not added motion).

## Affected Components

### Files to Modify
- `src/core/sitCycle.ts` — replace the RELEASE branch's symmetric `smoothstep(1 - x)` with a
  one-sided **ease-out descent** (steep start, gentle settle). Add a small named helper next
  to `smoothstep`; do not touch IDLE/BUILD/HOLD or `apexTime`/window math.
- `src/core/sitCycle.test.ts` — add the failing-first tests below (red → green).

> No `dog.ts`, `scene.ts`, `window.ts`, or `tuning.ts` change: `dog.pose()` consumes the
> already-eased `sitAmount`, and the scoring window is deliberately left identical (the fix is
> in the pose curve, not the window).

## Technical Approach (TDD — this is game-logic, test-first per the `tdd` skill)

### Before — symmetric smoothstep lingers near fully-seated past the close
```ts
// sitCycle.ts — RELEASE branch
} else {
  phase = 'RELEASE'
  sitAmount = smoothstep(1 - (into - holdEnd) / t.releaseMs) // zero slope at start → tail
}
```
At apex+250 ms `sitAmount ≈ 0.985`; at apex+300 ms `≈ 0.945` — both look fully seated, both
score MISS.

### After — ease-out descent: leaves the seat immediately, settles gently
```ts
/**
 * Ease-out descent 1→0: steep at the start (the dog lifts off the seat the
 * instant the scoring window closes), gentle at the end (eases into idle with no
 * snap). Cubic — initial slope is decisive without a pop. Closes PO Review C1:
 * "looks seated" now ends exactly where "is markable" ends.
 */
function easeOutDescent(p: number): number {
  const c = p < 0 ? 0 : p > 1 ? 1 : p
  return (1 - c) * (1 - c) * (1 - c) // cubic ease-out (1→0, front-loaded)
}

// ... RELEASE branch:
} else {
  phase = 'RELEASE'
  sitAmount = easeOutDescent((into - holdEnd) / t.releaseMs)
}
```
At apex+250 ms `sitAmount ≈ 0.80`; at apex+300 ms `≈ 0.63` — the dog is visibly rising the
instant the window closes.

### Tests to write first (red on the current smoothstep → green after)
```ts
// sitCycle.test.ts — extend the "PO C1" describe block
it('leaves the seat the instant scoring closes — no fully-seated frame past the window', () => {
  // Shipped cadence + shipped NORMAL window. The window closes at apex+200 ms
  // (windowWidthMs/2). The PO cited apex+250 ms as 98.5% seated under the old
  // smoothstep — pixel-indistinguishable from the apex yet scoring MISS.
  const apex = SIT_TIMINGS.idleMs + SIT_TIMINGS.buildMs
  const st = sitStateAt(0, apex + 250) // 50 ms past the window close, default = SIT_TIMINGS
  expect(st.phase).toBe('RELEASE')
  expect(st.sitAmount).toBeLessThanOrEqual(0.9) // visibly off the seat (was ~0.985)
  // And the score there is honestly a MISS — which is now FAIR, because the pose
  // no longer pretends to be seated.
  expect(scoreTap(windowAtApex(apex), apex + 250)).toBe('MISS')
})

it('the release is front-loaded (ease-out, not symmetric ease-in-out)', () => {
  // More of the stand-up happens in the first fifth of RELEASE than the last
  // fifth — the opposite of the old symmetric smoothstep (equal at both ends).
  const apex = SIT_TIMINGS.idleMs + SIT_TIMINGS.buildMs
  const holdEnd = apex + SIT_TIMINGS.holdMs
  const rel = SIT_TIMINGS.releaseMs
  const at = (frac: number) => sitStateAt(0, holdEnd + frac * rel).sitAmount
  const dropFirstFifth = 1 - at(0.2) // how much it fell in the first 20%
  const dropLastFifth = at(0.8) - 0 // how much it fell in the last 20%
  expect(dropFirstFifth).toBeGreaterThan(dropLastFifth)
})
```

### Regression guards (must stay green — already in the suite)
- `every fully-seated (HOLD) instant scores at least OK` — unchanged (HOLD math untouched).
- `keeps PERFECT centered on the apex` — unchanged (window untouched).
- `releases back up: RELEASE, strictly falling 1→0` — still holds (cubic ease-out is monotone).
- `pose is continuous at the build→hold and hold→release seams` — still holds: ease-out starts
  at `sitAmount = 1` (matches HOLD) and ends at `0` (matches next IDLE), so both seams stay
  continuous; the release→idle landing is *gentler* than before, never a snap.

## Risks & Considerations
- **Don't touch the window.** Keep `windowAtApex` / `tuning.ts` exactly as shipped — PERFECT
  must stay centered on the apex and the window symmetric. The fix is purely the pose curve.
- **No pop.** A *too*-steep descent would read as a snap up off the seat. Cubic ease-out
  (initial normalized slope −3 over a 700 ms leg ≈ a smooth ~7%/frame initial lift) is
  decisive but smooth; if Visual Review reads it as a pop, fall back to quadratic `(1-c)²`
  (the test threshold ≤ 0.9 passes for both).
- **All tricks inherit it.** Because the change is in `sitStateAt`, Ligg's release is fixed
  too — confirm Ligg still reads as a clean stand-up from the down (no clip), as the shared
  fix is the point (P2-3, consistent quality bar).
- **Reduced motion.** No new motion is added; the curve only reshapes existing movement, so
  the reduced-motion guarantee (X-5) is unaffected — but keep the change inside `sitStateAt`
  (don't branch on reduced motion here).

## Acceptance Criteria
- [x] **TDD, red first:** the two new tests above are added and fail on the current
      `smoothstep(1 - x)` release, then pass after the ease-out change.
- [x] RELEASE uses a one-sided **ease-out descent** (steep start, gentle settle) via a small
      named helper in `sitCycle.ts`; IDLE/BUILD/HOLD, `apexTime`, and the window are untouched.
- [x] At apex+250 ms the shipped cadence reports `sitAmount ≤ 0.9` (was ~0.985); the dog
      visibly leaves the seat as the window closes.
- [x] All existing `sitCycle.test.ts` guards stay green (HOLD ≥ OK, PERFECT centered, RELEASE
      strictly falling, seam continuity).
- [x] Ligg's stand-up still reads cleanly with the shared fix (monotone, continuity-tested
      curve; no clip or snap by construction — see notes).
- [x] Verify gate green: `typecheck` 0 · `test` · `build` no-warnings · `e2e`.

## Completion Notes (2026-06-27)

**Done.** Verify gate green: `typecheck` 0 errors · `test` **59 pass** (2 new in `sitCycle.test.ts`)
· `build` no warnings · `e2e` **9 pass**.

- **TDD red→green.** Wrote the two new tests in the existing `PO C1` describe block first; they
  failed on the shipped `smoothstep(1 - x)` release exactly as predicted — `sitAmount = 0.9854` at
  apex+250 ms (needed ≤ 0.9), and the release was provably symmetric (first-fifth drop `0.10399…7`
  == last-fifth drop `0.10399…5`, so "front-loaded" failed). After the fix: `0.80` at apex+250 ms
  and a clearly front-loaded descent → both green.
- **Fix.** Added a `easeOutDescent(p)` helper next to `smoothstep` in `src/core/sitCycle.ts`
  (cubic `(1-p)³`: front-loaded, gentle settle) and pointed the RELEASE branch at it. IDLE / BUILD
  / HOLD, `apexTime`, `windowAtApex`, and `tuning.ts` are **untouched** — the scoring window is
  byte-identical, so PERFECT stays centered on the apex. Only the *pose curve on the release leg*
  changed, so "looks seated" now ends exactly where "is markable" ends.
- **Every trick inherits it.** The change lives in the shared `sitStateAt`, so Ligg's stand-up is
  fixed by the same edit (P2-3 — consistent quality bar). No `dog.ts` / `scene.ts` change: they
  consume the already-eased `sitAmount`.
- **No clip/snap by construction.** The curve is monotone 1→0 and continuous at both seams (starts
  at `sitAmount = 1` matching HOLD, ends at `0` matching the next IDLE, with a *gentler* landing
  than the old smoothstep). The pre-existing `seam continuity` and `RELEASE strictly falling`
  guards stay green, so a screenshot pass on the release leg adds no signal — the capture probes
  scrub the BUILD phase, not RELEASE, so they're unaffected and still pass.
- Files: MODIFY `src/core/sitCycle.ts`, `src/core/sitCycle.test.ts`.
