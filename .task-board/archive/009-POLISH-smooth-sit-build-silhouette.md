# POLISH: Smooth the lumpy mid-build silhouette so the sit folds cleanly (PO I2)

**Status**: Done
**Created**: 2026-06-27
**Completed**: 2026-06-27
**Priority**: Medium — follows 007 + 008 (PO Review I2; P1-3 legibility)
**Labels**: render, dog, silhouette, phase-1, visual-review
**Estimated Effort**: Small

## Context & Motivation

PO Review **I2** (`specs2.md` → Product Owner Review — 2026-06-27):

> Through the build (≈ sitAmount 0.5–0.65) the hindquarters bulge into a large rounded
> lump jutting rearward and the pose reads more like "leaning/rearing back" than "folding
> into a sit." It resolves to a clean seated apex, so it's an in-between-frame quality
> issue, not a broken end pose.

**P1-3** wants the player to "watch the dog build into a sit" and read it cleanly; the
lumpy mid-build undercuts that legibility. What good looks like (PO): "smooth the
rump/haunch through the build so the lowering reads as one continuous fold (tuck the hind
mass as the hip drops rather than letting it balloon outward), keeping the clean apex it
already reaches."

**Current state (source):** in `src/render/dog.ts`, `rump` is created at a fixed
`position (0,-0.02,-1.0)` / fixed `scaling`, and the `pose()` build only rotates the
shoulder + folds the hind legs — the rump mass is **not** tucked as a function of
`sitAmount`, so mid-build it swings rearward and balloons. The apex (s=1) already reads
clean; the problem is the in-between frames.

## Desired Outcome

The lowering reads as **one continuous fold** from idle to the seated apex — no rearward
lump, no "rearing back" mid-build — while the already-clean apex pose is **unchanged**.

## Affected Components

### Files to Modify
- `src/render/dog.ts` — drive the rump/haunch mass from `sitAmount` in `pose()` so it
  tucks forward/down as the hip drops (continuous through the build), preserving the apex.

## Technical Approach

Pure rendering/3D → **exempt from TDD**; judged by **Visual Review** (per scan-project
rules). Use the existing deterministic pose-freeze harness (`setPose` / capture spec) to
grab mid-build frames at the exact `sitAmount` values the PO flagged.

Make the rump a function of `s` so it folds *with* the hip instead of ballooning rearward.

### Before
```ts
// rump is static — never tucked during the build
rump.position.set(0, -0.02, -1.0)
rump.scaling.set(1.0, 0.98, 0.98)
// ... pose() only does: shoulder.rotation.x = s*SIT_ANGLE; hind legs fold
```

### After (illustrative — tune to the silhouette)
```ts
// in pose(), drive the rump with s so the hind mass tucks forward+down as the hip drops,
// and stops bulging rearward through the lumpy 0.5–0.65 band. Land on the SAME apex values.
rump.position.z = -1.0 + s * 0.18          // tuck forward as it folds (no rearward swing)
rump.position.y = -0.02 - s * 0.06         // settle down with the hip
rump.scaling.z = 0.98 - s * 0.12           // shrink the rearward bulge through the build
// keep scaling.x/y so the seated apex silhouette is identical to today
```

## Risks & Considerations
- **Do not regress the apex (PO's explicit constraint).** Capture the apex (s=1) frame
  before and after — it must read identical. If a Visual-Review reviewer sees the seated
  apex change, the fix is wrong.
- **Smoothness over the whole band.** The fix must read clean across the *continuous*
  build (sample at least s ≈ 0.3 / 0.5 / 0.65 / 0.85), not just at the two flagged values.
- **Scope discipline (phasing rule).** This is in-between-frame legibility, not a new
  rig. No re-modelling beyond tucking the existing rump/haunch mass.

## Acceptance Criteria
- [x] In `pose()`, the rump/haunch tucks as a function of `sitAmount` so the build reads
      as one continuous fold (no rearward lump / "rearing back").
- [x] The seated apex (s=1) silhouette is unchanged vs. before (before/after apex capture
      match) — confirmed in Visual Review.
- [x] **Visual Review (blocking):** independent phone-portrait reviewers confirm, on
      frozen frames at sitAmount ≈ 0.3 / 0.5 / 0.65 / 0.85, that the lowering folds
      cleanly and the apex is intact. Findings are blocking.
- [x] Verify gate green: `typecheck` · `test` · `build` · `e2e`.

## Resolution (2026-06-27)

**Implemented** in `src/render/dog.ts` `pose()`: the rump is driven by a corrective
*hump* `tuck = s * (1 - s)` (zero at both s=0 and s=1, max 0.25 at s=0.5) that pulls the
hind mass forward (`+z`) and down and shrinks its rearward bulge (`scaling.z`) through the
build, then returns to the static creation values at the apex:

```ts
const tuck = s * (1 - s)
rump.position.z = -1.0 + tuck * 0.72
rump.position.y = -0.02 - tuck * 0.3
rump.scaling.z  = 0.98 - tuck * 0.5
```

**Discrepancy with the task's illustrative snippet (recorded per loop rules).** The
"After" sketch in *Technical Approach* drove the rump **linearly** with `s`
(`-1.0 + s*0.18`, etc.), which lands the apex at `z=-0.82 / y=-0.08 / scaling.z=0.86` —
i.e. it would have **moved the apex**, directly contradicting Acceptance Criterion #2 and
the PO's explicit "do not regress the apex" constraint. The sketch's own comment said
"Land on the SAME apex values," so the intent was clear; only the formula was wrong. A
`s*(1-s)` hump satisfies both: it corrects the lumpy 0.5–0.65 band yet is **identically
zero at s=1**, so the rump is geometrically byte-identical at the apex by construction.

**Visual Review (blocking) — both independent phone-portrait reviewers returned PASS:**
- Fold continuity across 0.3/0.5/0.65/0.85 → apex reads as one continuous lowering; the
  s≈0.65 "rearing-back" lump is substantially gone.
- Apex preserved (only ambient tail/breathing phase differs — allowed).
- No new artifacts (no rump↔hind-leg clipping, no lumbar pinch, no over-forward collapse).
- Non-blocking notes captured: improvement at s=0.5 is the subtlest of the band (the
  pre-fix lump was smaller there, so the proportional correction is smaller); a faint
  stray paw/toe blob near the right hind foot in the 0.5 frame is **pre-existing** and
  unrelated to the rump. Neither warrants further work under the phasing/scope rule.

Before/after frames captured via the existing pose-freeze harness; build frames added to
`e2e/_capture.spec.ts` (the temporary review harness, not a gate).
