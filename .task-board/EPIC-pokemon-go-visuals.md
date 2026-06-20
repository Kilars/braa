# EPIC: Pokémon-GO Visuals (D14 — "looks the part")

**Created**: 2026-06-17
**Status**: Active — Phase 0 ready, Phases 1–6 outlined
**Owner decision (2026-06-17)**: Asset sourcing route = **asset-store base model
+ shared-rig retargeting** (see [tech-decisions.md §3](../.docs/tech-decisions.md)).

## Why this epic exists

v1 gameplay is functionally complete and playable end-to-end (564 tests green,
backlog drained). The one unstarted pillar is the **look**. specs.md is explicit:
the target is **Pokémon-GO-style stylized-realism** — clean models, bright soft
lighting, breeds that read clearly as their real breed, per-breed signature
animations (`specs.md` §Visual Presentation, D14, §Definition-of-Finished).

Today the dog is **colored Babylon primitives** (capsule + spheres + cylinders,
flat `StandardMaterial`, two lights, no shadows, transform-tween "animation", zero
assets on disk). That clears the *floor* (D1 reads as a dog, D2 breeds distinct at
silhouette level) but not the *ceiling* (D14 looks the part). Closing that gap is
the largest remaining body of work in the project and was correctly deferred until
gameplay landed.

## The one architectural seam that makes this safe

The whole app talks to the renderer through the **`DogMesh` contract** in
`src/render/dogMesh.ts` (`applyPose` / `setTint` / `setEmissive` / `setAppearance`
/ shadow + parts). `scene.ts` and `main.ts` only ever call that interface — they
never touch primitives directly. **The migration swaps the implementation behind
this interface**, breed-by-breed and phase-by-phase, behind a feature flag, with
the procedural dog as a guaranteed fallback. The app stays shippable at every step.

## Sequencing principle

**Vertical slice first.** Prove the entire pipeline (load → pose → light → ship)
on **one breed (Labrador)** before scaling to all five. This matches
tech-decisions §3's "start with a small number of high-quality breeds" mitigation
and de-risks the asset pipeline before per-breed cost is incurred.

## Phases & task slots

| # | Phase | Task | State |
|---|-------|------|-------|
| 0 | Sourcing & decision | `077-RESEARCH-dog-model-sourcing` | **DONE** — purchased + dropped (`Labrador_FBX.rar`); needs FBX→glb conversion |
| 1 | Pipeline slice | `078-FEATURE-gltf-load-path-and-fallback` | Core landed; loader/scene wiring needs the converted `.glb` |
| 1 | Pipeline slice | `079-FEATURE-imported-dogmesh-labrador` | Specced; depends on 078 + the converted `.glb` |
| 2 | Animation | `080` — skeletal animation mapping (pose channels → bones/anim groups) | Outlined below |
| 3 | The look | `081` — PBR coat + soft bright lighting + real contact shadow + tone mapping | Outlined below |
| 4 | Breed scale-out | `082` — retarget shared rig to all 5 breeds (coat textures + proportion morphs) | Outlined below |
| 5 | Polish | `083` — per-breed signature animations (Rull/Sov/Snurr/Ul) | Outlined below |
| 5 | Polish | `084` — upgradable park backdrop (visibly improves with kennel) | Outlined below |
| 6 | Ship gate | `085` — mobile perf budget (LOD/draw-calls/thermal), flip flag to default | Outlined below |

Tasks 080–085 are promoted to full task files when their phase begins (kept as
outlines here so they don't drift before the slice they depend on lands).

### Phase 2 — `080` Skeletal animation mapping
Drive idle / offering / happy / confused + per-trick poses through the model's
animation groups (or procedural bone overlays blended with baked clips) instead of
transform tweens. **Testable (TDD):** the pose-channel → bone/blend-weight mapping
and reduced-motion damping are pure logic. **Visual Review:** motion feel, the apex
"tell," the mark pop. Keep the existing `DogPose` channel contract so nothing
upstream changes.

### Phase 3 — `081` PBR look
Swap `StandardMaterial` → `PBRMaterial` (metallic-roughness coat); add a
`ShadowGenerator` (real soft contact shadow, retire the blob disc); add
environment/IBL for the soft bright fill that defines the Pokémon-GO read; add ACES
tone mapping. **Visual-Review-heavy.** Watch the mobile perf budget here.

### Phase 4 — `082` Breed retarget to all 5
Extend `dogAppearance.ts` to drive **coat textures / PBR params + proportion
morphs/scale on the shared mesh** rather than primitive recolor + cylinder scaling.
Retarget the one rig to Lab / Bulldog / Border Collie / Husky / Puddel. **Testable:**
the appearance lookup extension; **Visual Review:** each breed reads as itself (D2).

### Phase 5 — `083` signature anims + `084` backdrop
Per-breed signature-trick animations as real skeletal clips (Rull/Sov/Snurr/Ul,
tied to `signatureTrickId`). Upgrade the gradient backdrop to a stylized park that
**visibly upgrades as the kennel grows** (spec §Visual Presentation).

### Phase 6 — `085` perf & ship gate
LODs, draw-call + texture-memory budget, battery/thermal check on a mid-range
phone. Flip the feature flag so imported is the default; decide whether to keep the
procedural dog as an ultra-low fallback or retire it.

## Done-when (epic acceptance)

- All 5 breeds render as imported, rigged, PBR-shaded, breed-recognizable models
  with real contact shadows under soft bright lighting (D2 + D14).
- Idle / offering / apex-tell / happy / confused / per-trick + per-breed signature
  animations run as skeletal motion; the mark moment still feels satisfying.
- Backdrop upgrades with the kennel.
- Holds frame-rate / thermal budget on a mid-range phone; bundle + asset load stay
  within a documented budget; imported is the default with a sane fallback.
- `bun run verify` green throughout; each visual phase passes **Visual Review**.

## Notes for the loop / implementers

- Respect TDD: pure logic (load-state machine, pose→bone mapping, appearance
  lookup, LOD selection) is **test-first**; asset/render glue is **Visual Review**.
- Never fabricate a screenshot (PLANNING-BOARD Subagent note).
- Reuse one long-lived `bun run dev` for screenshots; verify with `bun run verify`.
- Asset licensing is a money/likeness gate — `077` shortlists, the owner approves
  the purchase. Do not commit an asset to the repo until its license is recorded.
