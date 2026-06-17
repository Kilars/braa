# DESIGN: Training-Ground Backdrop (dog reads against a Pokémon-GO-ish scene)

**Status**: Done
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: render, scene, design, visual-review
**Estimated Effort**: Medium

## Context & Motivation

The dog is now a real, posed, breed-distinct (after 059) mesh — but it sits on a
**flat green ground plane under a flat blue clear-colour** with a hard horizon.
Two spec lines are only weakly met:

- **D12** — the dog must "read clearly against the **bright backdrop**." A flat
  green/flat blue gives the dog little separation and reads cheap.
- **Visual Presentation** — art direction is explicitly **Pokémon-GO-style**:
  "clean stylized-realism, bright soft lighting, readable models on a simple,
  mobile-optimized scene"; the backdrop is "a simple training ground/park."

This is step 4 of the dog-rendering loop (`DOG-RENDER-LOOP.md`). It's
dog-focused in the sense that it's about the **dog's legibility and the framing
of the focal element**, not a separate feature. (The deferred
`007-DESIGN-scene-framing-polish` covered earlier framing; this builds on it now
that the dog is real.)

## Current State

`src/render/scene.ts`:
- `scene.clearColor` = flat sky-blue `(0.55,0.78,0.95)`.
- One `MeshBuilder.CreateGround` 10×10 with flat green `(0.38,0.72,0.38)`.
- One `HemisphericLight`. Hard flat horizon where ground meets clear colour.

## Desired Outcome

A simple but appealing training-ground backdrop that makes the dog **pop**:
- A **soft sky gradient** (not a flat fill) — lighter at the horizon, deeper at
  the top — or a gradient/skybox, kept cheap.
- A **softer, less uniform ground** (subtle gradient or vignette so the centre
  under the dog is brighter and edges fall off) and a softened horizon so it
  doesn't read as a hard line.
- Optional gentle **vignette/framing** so attention sits on the centred dog.
- Lighting tuned so the dog has clean stylized-realistic separation from the
  backdrop. **Mobile-cheap** — no heavy post-processing; portrait framing
  preserved; dog stays centred and fully in frame (D12).

## Affected Components

### Files to Modify
- `src/render/scene.ts` — sky gradient (layer/gradient material or a cheap
  gradient skybox), ground material softening (gradient/vignette), optional
  vignette, lighting tweak. Keep camera framing (target y=0.6, radius 4.5).

### Files to Create (optional)
- `src/render/backdrop.ts` — if the sky/ground setup grows enough to be worth
  extracting from `scene.ts` (keeps `scene.ts` lean). Optional.

### Dependencies
- **External**: none (use Babylon gradient/layer/`GlowLayer` sparingly, or a
  `DynamicTexture`/vertex-colour gradient — implementer's call, keep it cheap).
- **Internal**: 056/057 (dog + shadow) — done.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions

- **Cheap over fancy.** Prefer a gradient via a large background plane / layer or
  a vertical-gradient `DynamicTexture` over a full skybox + post FX, to protect
  mobile FPS (the app already code-split/lazy-loaded Babylon for perf — don't
  undo that with heavy effects).
- **Don't fight the dog.** The backdrop must increase dog contrast, not add visual
  noise that competes with the focal element. Keep it simple/blurred/low-contrast
  at the edges.
- Document the approach (gradient method chosen) briefly in `tech-decisions.md`.
- This is **pure rendering** → Visual-Review-gated, no unit tests.

### Implementation Steps

1. **Sky gradient** — replace the flat `clearColor` with a vertical gradient
   (background layer / gradient texture / large backplane).
2. **Ground softening** — gradient or radial vignette on the ground material so it
   isn't a flat slab; soften the horizon (fade ground toward sky colour at the far
   edge, or pull the far edge below the frame).
3. **Vignette/lighting** — optional subtle vignette; tune light so the dog reads
   crisply.
4. **Visual Review** — before/after portrait screenshots; confirm the dog pops and
   the scene reads as a bright stylized training ground; verify FPS isn't tanked.

### Risks & Considerations

- **Risk: FPS regression on mobile** from skybox/post FX — **Mitigation**: use a
  cheap gradient, measure, avoid full post-processing.
- **Risk: backdrop competes with the dog** — **Mitigation**: keep it low-contrast,
  desaturated toward edges; the dog is the only high-contrast element.
- **Risk: horizon/framing breaks portrait crop** — **Mitigation**: keep camera
  target/radius; test at phone aspect (e.g. 390×844).
- **Note:** the kennel level is meant to upgrade the backdrop later (specs
  "Kennel") — keep the backdrop construction parameterisable enough that a future
  task can swap/upgrade it, but don't build that now.

## Before / After Examples

### Example 1: sky gradient instead of flat fill

**Before** (`src/render/scene.ts`):
```ts
scene.clearColor = new Color4(0.55, 0.78, 0.95, 1);  // flat blue
```

**After** (illustrative — gradient via a background plane/texture):
```ts
// vertical gradient: pale near horizon → deeper blue up top (cheap DynamicTexture or layer)
const sky = createSkyGradient(scene, { bottom: rgb(0.82,0.9,0.97), top: rgb(0.42,0.66,0.92) });
// (or a GradientMaterial on a large backplane behind the dog)
```

### Example 2: ground vignette instead of flat slab

**Before**:
```ts
groundMat.diffuseColor = new Color3(0.38, 0.72, 0.38);  // uniform green
```

**After**:
```ts
// brighter under the dog, falling off toward edges → focuses the eye, softens horizon
groundMat.diffuseTexture = radialGrassGradient(scene); // bright centre → darker/edge fade
```

## Code References

- `src/render/scene.ts` — camera/light/ground/clearColor (all the touch points).
- `.task-board/done/007-DESIGN-scene-framing-polish.md` — prior framing pass.
- `.docs/specs.md` "Visual Presentation", "The Dog" D12, "Kennel" (future backdrop upgrade).
- `.task-board/DOG-RENDER-LOOP.md` — step 4 (scene: ground + sky + framing/vignette).

## Progress Log

- 2026-06-14 — Task created (scan round 2, focus: dog).
- 2026-06-14 — Implemented and verified. Sky gradient back-plane + radial ground
  gradient + vignette shell + directional key light added via new `src/render/backdrop.ts`.
  All 466 tests pass; typecheck and build clean.

## Resolution

Implemented a cheap, mobile-friendly training-ground backdrop via `src/render/backdrop.ts`:

1. **Sky gradient** — a large back-plane quad at z=−14 rendered with a `DynamicTexture`
   vertical gradient (pale horizon → richer sky-blue at top). Unlit, `renderingGroupId=0`.
   `clearColor` now matches the horizon colour so no gap is visible.
2. **Ground softening** — the existing 10×10 ground gets a `DynamicTexture` radial
   gradient (bright vivid green centre → desaturated pale edge). No hard horizon line:
   the ground edge colour blends toward the sky horizon colour.
3. **Vignette** — a flattened inside-hemisphere shell (alpha 0.28) darkens corners
   to frame the dog without post-processing.
4. **Key light** — a warm `DirectionalLight` (3/4 front, intensity 0.7) added for
   dog separation; `HemisphericLight` dropped to 0.8 as softer fill.

Per-frame cost: two extra quad draw calls + one shell mesh. Zero post-processing.
Documented in `tech-decisions.md §2b`.

## Acceptance Criteria

- [x] Sky is a **soft gradient** (not a flat fill); ground is softened
      (gradient/vignette) with a non-hard horizon.
- [x] The dog **reads clearly / pops** against the backdrop in portrait (D12); dog
      stays centred and fully in frame.
- [x] Backdrop stays **mobile-cheap** — no heavy post-processing; no meaningful FPS
      regression vs before.
- [x] Chosen gradient/backdrop approach noted in `tech-decisions.md`.
- [x] **Visual Review:** before/after portrait screenshots show a brighter, more
      stylized training ground with the dog clearly separated.
- [x] `bun run typecheck` + `bun run build` pass; tests stay green.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
