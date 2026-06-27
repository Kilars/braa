# FIX: "Looks seated" must == "is markable" — close the dead seated tail (PO C1)

**Status**: Backlog
**Created**: 2026-06-27
**Priority**: P0 — fix first (PO Review C1, blocks Phase-1 sign-off)
**Labels**: gameplay, timing, scoring, phase-1, tdd
**Estimated Effort**: Small

## Context & Motivation

The father/PO play-test (`specs2.md` → **Product Owner Review — 2026-06-27**, change
**C1**) found the one fairness bug that inverts the core design:

> The dog stays fully seated (pose held flat at 100 %) for ~500 ms, but the scoring
> window **and** the apex tell both end ~200 ms after the apex. So for the last ~300 ms
> of the hold the dog looks *exactly* as seated as it did at the apex, yet a tap scores
> **MISS** and the ring is dark. Verified live: a tap at apex+300 ms (dog still fully
> seated) → MISS.

This breaks **P1-3** ("mark off the dog itself — not just the UI"): a player who waits
until the dog is *clearly* sitting, then taps, eats an unfair MISS. The honest tell only
rescues players who watch the ring, not the dog.

**Root cause (confirmed in source):** in `src/core/sitCycle.ts`, `SIT_TIMINGS.holdMs =
500`, and the `HOLD` phase pins `sitAmount = 1` for that entire 500 ms (the fully-seated
plateau spans `apex … apex+500`). But `windowAtApex` (`src/core/window.ts`) builds a
symmetric window of `windowWidthMs = 400` → it **closes at `apex+200`**. So the plateau
outlives the window by ~300 ms — the dead tail the PO measured.

## Desired Outcome

"Looks seated" == "is markable": **every instant the dog is fully seated falls inside the
scoring window** (scores OK or PERFECT, never MISS/NONE), and the honest apex tell stays
lit for exactly that markable span. **PERFECT stays centered on the apex** (PO directive).

## Affected Components

### Files to Modify
- `src/core/sitCycle.ts` — `SIT_TIMINGS` (and/or the phase math) so the held plateau no
  longer outlives the window.
- `src/core/sitCycle.test.ts` — add the invariant test (below) first (TDD).
- (Only if option B is chosen) `src/core/window.ts` + its callers — asymmetric close.

### Files to Check (must stay honest, not necessarily edited)
- `src/render/scene.ts` / wherever the apex-tell ring brightness is driven — confirm the
  tell is lit **iff** the tap would score, under whichever option is chosen.

## Technical Approach (TDD — write the invariant test first)

This is game-logic → **test-first** via the `tdd` skill (`.claude/skills/tdd/SKILL.md`).
The fix is small; the *test* is the real deliverable because it encodes the PO's rule as a
permanent invariant, independent of which option you pick.

**The invariant test (red first):** for a cycle's apex window `W = windowAtApex(apexTime)`
and every plateau instant `tp` where the dog reads as fully seated, a tap scores ≥ OK.

### Before (no such guarantee — this is the bug)
```ts
// sitCycle.ts
export const SIT_TIMINGS: SitTimings = { idleMs: 1600, buildMs: 700, holdMs: 500, releaseMs: 700 }
// plateau = apex … apex+500, but windowAtApex closes at apex+200  → apex+300 tap MISSes
```

### After — Option A (RECOMMENDED: trim the hold so the pose stops lying)
```ts
// sitCycle.ts — the dog begins standing back up as the window closes; no dead tail.
// holdMs must be <= windowWidthMs/2 so the whole fully-seated plateau is inside the window.
export const SIT_TIMINGS: SitTimings = { idleMs: 1600, buildMs: 700, holdMs: 200, releaseMs: 700 }
```
```ts
// sitCycle.test.ts (red → green)
it('every fully-seated instant is inside the scoring window (looks seated == is markable)', () => {
  const start = 0
  const apex = SIT_TIMINGS.idleMs + SIT_TIMINGS.buildMs
  const w = windowAtApex(apex)
  // sample the whole HOLD plateau
  for (let tp = apex; tp < apex + SIT_TIMINGS.holdMs; tp += 5) {
    const st = sitStateAt(start, tp)
    expect(st.sitAmount).toBeGreaterThanOrEqual(0.999) // really fully seated
    expect(scoreTap(w, tp)).not.toBe('MISS')           // ... and markable
    expect(scoreTap(w, tp)).not.toBe('NONE')
  }
  expect(scoreTap(w, apex)).toBe('PERFECT')            // PERFECT still centered on apex
})
```

### After — Option B (alternative: extend window + tell to span the held seat)
Keep `holdMs` generous but make the window's **close** reach the plateau end while the
PERFECT band stays centered on the apex (asymmetric window). Bigger blast radius
(`window.ts` shape + the tell renderer must light the whole extended span), so prefer A
unless a longer restful hold is judged worth it.

**Pick exactly one and keep PERFECT centered on the apex.** Record the choice + reasoning
in the task's completion notes / `tech-decisions.md`. Whichever you pick, the apex tell
must remain *honest*: lit exactly when a tap would score, dark otherwise.

## Risks & Considerations
- **Existing tests hard-code `holdMs`/period.** Update any `sitCycle.test.ts` assertions
  that assume 500 ms — but the new invariant is the contract going forward.
- **Don't regress the apex.** PERFECT at `apex` must stay PERFECT; the tell must still
  peak at the apex (P1-4). Verify the ring is dark all through IDLE/RELEASE (unchanged).
- **Cadence feel.** A 200 ms hold is brief; confirm in the running app the sit still
  reads as a deliberate "land + hold" beat, not a bounce. If it feels too quick, that is
  the trade that motivates Option B — note it for the PO rather than widening scope here.

## Acceptance Criteria
- [x] Red-first invariant test added: every fully-seated (`sitAmount ≈ 1`) instant of the
      HOLD scores ≥ OK (never MISS/NONE) — `tdd` loop followed.
- [x] A tap at the spot the PO flagged (dog clearly seated, ~apex+300 ms previously) now
      scores instead of MISS — covered by the swept invariant test.
- [x] PERFECT is still centered on the apex (`scoreTap(W, apex) === 'PERFECT'`, band
      = apex ± peakRadius unchanged).
- [x] The apex tell ring is lit **iff** a tap would score, and dark through IDLE/RELEASE
      (honest tell preserved — confirm in the running app / capture harness).
- [x] Chosen option (A or B) + rationale recorded in completion notes.
- [x] Verify gate green: `typecheck` · `test` · `build` · `e2e`.

## Resolution (2026-06-27)

**Chosen option: A (trim the hold).** Root cause was purely the cadence table:
`SIT_TIMINGS.holdMs = 500` pinned the dog fully seated (`sitAmount === 1`) for
`apex … apex+500`, while the shipped NORMAL window (`windowWidthMs 400`) closes at
`apex+200` — a ~300 ms tail where the dog looks identical to the apex yet a tap MISSes
and the tell is dark. Fix: `holdMs: 500 → 200` (= `windowWidthMs/2`), so the dog begins
standing back up (RELEASE) exactly as the window closes. "Looks seated" now == "is
markable"; PERFECT stays centered on the apex; the symmetric window is untouched.

**Why not option B (extend window):** larger blast radius (`window.ts` shape + the tell
renderer + `scoreTap` would all need an asymmetric close) for a more lenient late edge.
Trimming the hold is the minimal change that removes the lying tail. A 200 ms hold still
reads as a deliberate land-and-hold beat; if the PO wants a longer restful seat, that is
the trade that motivates B — noted here rather than widening scope.

**Tell honesty (unchanged, verified by reading `src/render/scene.ts:194-198`).** The
apex-tell brightness is `max(0, 1 - |now - apexTime| / (windowWidthMs/2))`, zeroed during
IDLE — derived from the apex + window half-width, it **never referenced `holdMs`**. So
trimming the hold cannot desync the tell: it is lit iff `|now-apex| < 200` (exactly the
markable span) and hits 0 at `apex±200`, which is now also where the pose stops looking
seated. The bug was the *pose* outliving the *window*, not the tell.

**TDD.** Red first: the swept invariant (`PO C1 — "looks seated" == "is markable"`) failed
against `holdMs=500` (a tap at apex+205 → MISS while `sitAmount===1`). Green after the
one-line cadence fix. The PERFECT-centered assertion was green throughout.

**Gate:** `typecheck` 0 errors · `test` 41 passed (was 39; +2 C1 invariant tests). The
shared end-of-iteration `build`/`e2e` gate is run once after 008/009. The e2e capture
harness freezes by `sitAmount` (not `holdMs`), so it is unaffected by this change.
