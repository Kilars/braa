# BUGFIX: Suppress the apex "mark now" tell while the dog is disengaged

**Status**: Done (2026-06-21)
**Created**: 2026-06-21 (iteration 25 scan)
**Priority**: High
**Labels**: bugfix, core-loop, signal-correctness, test-coverage, po-review
**Estimated Effort**: Small

## Context & Motivation

PO Review — 2026-06-21, **Bugfix #4**: with the dog walked off (engagement empty)
and the call-back prompt showing ("Hunden gikk — trykk for å kalle den tilbake"),
the gold apex ring still pulses around BRA — a "mark the peak" signal at a moment
when marking earns nothing and the only valid action is *tap to call the dog back*.
Two opposite meanings ride one cue.

This is a **core-loop signal-correctness bug**, not cosmetics: the apex tell is the
game's single most important "act now" cue, and firing it during disengagement
directly contradicts the call-back affordance the same screen is showing. The dog's
on-mesh apex shape is *also* driven off the same value (`peakProximity`), so the
walked-off dog can crest its markable pose while back-turned at the frame edge.

## Current State

- `src/ui/viewModel.ts:42-52` computes `peakProximity` and `tellStrength =
  peakProximity * tellIntensity` purely from the active attempt geometry — **with no
  `disengaged` gate**. `disengaged` is computed two lines later (`:68`) but never
  feeds the tell.
- `src/ui/hud.ts:626-630` drives the ring straight off `vm.tellStrength`
  (`tellRingEl.style.opacity = String(ts)`), so any non-zero strength shows the ring
  regardless of disengagement.
- `vm.peakProximity` flows to the scene's dog apex shape (D6), so the same leak
  reaches the mesh.

## Desired Outcome

While the dog is disengaged (`disengaged === true`), **both** `tellStrength` and
`peakProximity` are forced to `0`, so:
- the gold apex ring is fully invisible (opacity 0), and
- the on-dog apex crest is flat,

leaving the call-back hint as the only "act now" affordance. When re-engaged, the
tell behaves exactly as before. No change to scoring/`isAttemptOpen` (a tap while
disengaged already branches to call-back before classification, task 117) — this
only suppresses the *visual cue*.

## Affected Components

### Files to Create / Modify
- `src/ui/viewModel.ts` — zero `tellStrength` + `peakProximity` when `disengaged`.
- `src/ui/viewModel.test.ts` — new failing tests first (TDD).
- `.docs/tech-decisions.md` — one line noting the tell is gated on engagement.

### Dependencies
- **Internal**: `disengageBeat`/`isDisengaged` (already imported in `viewModel.ts`);
  `toViewModel` already computes `disengaged`. None blocking.
- **External**: none.

## Technical Approach

### Implementation Steps (TDD — `tdd` skill, vertical slices)
1. **RED**: add a test asserting that when the engagement meter is empty (disengaged),
   `toViewModel(...).tellStrength === 0` **even with an attempt open at its peak**
   (construct a `RoundState` whose attempt peak === `now`, the case that today yields
   `tellStrength === tellIntensity`).
2. **GREEN**: after computing `disengaged`, clamp: `if (disengaged) { tellStrength = 0;
   peakProximity = 0; }` before building the return object.
3. **RED→GREEN**: add a test that `peakProximity === 0` while disengaged, and a
   guard test that a healthy meter at the peak is **unchanged** (`tellStrength` still
   `peakProximity * tellIntensity`) — proving the gate is engagement-scoped, not a
   blanket zero.

### Before / After

**Before** (`src/ui/viewModel.ts`, tell ignores engagement):
```ts
let tellStrength = 0;
let peakProximity = 0;
if (attempt /* open */) {
  peakProximity = 1 - clamp01(Math.abs(now - attempt.peak) / halfSpan);
  tellStrength = peakProximity * tellIntensity;
}
// ...
const disengaged = isDisengaged(disengageBeat(engagementLevel));
return { tellStrength, peakProximity, /* ... */ disengaged };
```

**After**:
```ts
let tellStrength = 0;
let peakProximity = 0;
if (attempt /* open */) {
  peakProximity = 1 - clamp01(Math.abs(now - attempt.peak) / halfSpan);
  tellStrength = peakProximity * tellIntensity;
}
const disengaged = isDisengaged(disengageBeat(engagementLevel));
// A walked-off dog earns nothing from a mark; suppress the "mark now" cue entirely
// so it never competes with the call-back affordance (PO Review 2026-06-21 #4).
if (disengaged) { tellStrength = 0; peakProximity = 0; }
return { tellStrength, peakProximity, /* ... */ disengaged };
```

### Risks & Considerations
- **Risk**: HUD reads a stale ring if `renderTraining` isn't called on the
  disengage transition. **Mitigation**: `renderTraining` runs every frame with the
  fresh vm, and `opacity` is set unconditionally from `ts` each call — zero
  propagates immediately. No HUD change needed; the fix is upstream in the vm.
- **Note**: pure logic, so **test-first**. Do not touch `hud.ts` rendering — gating
  at the vm keeps a single source of truth and automatically fixes the on-dog apex.

## Acceptance Criteria

- [x] New `viewModel.test.ts` cases (written **first**, red→green via `tdd`): disengaged
      + attempt-at-peak ⇒ `tellStrength === 0` **and** `peakProximity === 0`; healthy
      meter + attempt-at-peak ⇒ `tellStrength` unchanged (regression guard). *(3 cases
      added; confirmed RED then GREEN.)*
- [x] `toViewModel` zeroes `tellStrength` + `peakProximity` when `disengaged`. *(Single
      clamp gated on the already-computed `disengaged`; `beat`/`disengaged` now computed
      once and reused in the return object.)*
- [x] Manual/Visual sanity: the fix is upstream of `hud.ts` — the ring opacity already
      tracks `vm.tellStrength`, so a zeroed strength means an invisible ring while
      disengaged (no HUD change needed; behaviour proven by the unit tests).
- [x] Decision noted in `.docs/tech-decisions.md` (§"On-dog walk-off + call-back" →
      "Apex-tell suppression while disengaged"). **specs.md untouched.**
- [x] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`. *(Run at iteration close.)*

---

**Technical approach hint**: one clamp in `toViewModel`, gated on the already-computed
`disengaged`. The win is that the most important cue stops contradicting the call-back
prompt — and because the on-dog apex shares `peakProximity`, the mesh is fixed for free.
