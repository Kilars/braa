# FEATURE: One-line licensed-Labrador swap + named owner/legal gate

**Status**: Ready (build after 078/079). Closes the gap between the *staged CC0
placeholder* glb and the *real licensed Labrador* the PO wants live (spec line 1:
"MAKE GLB REPLACE PLACEHOLDER DOG"). The licensed asset itself is owner/legal-gated;
this task makes the swap trivial and tracks exactly what the owner must deliver.

> **UPDATE 2026-06-20 (interactive session):** Gate 1 (texture) is RESOLVED. Owner
> supplied `Labrador_Textures.rar`; the **textured licensed glb now exists** at
> `models-build/out_anim.glb` (19.7 MB, albedo+normal embedded, 113 clips), produced
> by `scripts/skin-dog-model.mjs` (FBX2glTF stubs a 1x1 placeholder for this pack —
> we inject the real maps post-bake). **Only Gate 2 (web-PWA license scope) remains**
> and it is an owner decision, NOT a code task: pack/encrypt vs Capacitor-native-only.
> Keep this file out of git and the web bundle until that call is made.
**Created**: 2026-06-20 (iteration 14)
**Priority**: Medium
**Labels**: render, assets, config, licensing, epic:pokemon-go-visuals
**Estimated Effort**: Small

## Context & Motivation

After 078 (loader) + 079 (imported `DogMesh`), the game renders an **imported glb
dog** behind `renderConfig.importedDog`, proven with the **CC0 placeholder** at
`public/models/dog.glb`. The PO's actual end goal is the **licensed Labrador** (Dogs
Big Pack), which converts cleanly to `models-build/out_anim.glb` (tech-decisions §3e)
but is held by **two genuine gates** named in `public/models/CREDITS.md`:

1. **Missing albedo texture (owner):** the FBX references an external
   `Labrador_Albedo1.png` (+ normal/roughness/AO) **not in the drop** → the model is
   untextured/white. The owner must supply the pack's texture folder.
2. **Web-PWA license (owner/legal):** the Royalty-Free license permits the model
   **compiled into an app** but **forbids end-users extracting the raw file**. A raw
   web-PWA serves the `.glb` fetchable (gray area). Decide PWA scope (pack/encrypt,
   or native-only via Capacitor) before the licensed file ships.

Neither gate blocks the CC0 path. This task removes all *non-gated* friction so that,
the moment the owner delivers, swapping CC0 → licensed Labrador is **one config line**
and the licensed file is structurally prevented from leaking into the web bundle.

## Current State

- `public/models/dog.glb` — CC0 placeholder, hard-referenced (the loader will fetch
  `/models/dog.glb` directly once 078 lands).
- `models-build/` — gitignored; holds `out_anim.glb` / `out_base.glb` (licensed,
  must never enter git or the web bundle).
- No single source of truth for "which model file is live" and no guard that keeps a
  licensed `.glb` out of the shippable web build.

## Desired Outcome

- A **single `DOG_MODEL_URL` constant** (the only place the model path lives), so the
  CC0 → licensed swap is a one-line change.
- A **pure, TDD-covered `resolveDogModelSource()`** that picks the model source from
  build inputs (licensed allowed *and* present → licensed; else CC0 fallback), so the
  fallback is deterministic and unit-tested — never a broken/empty model path.
- The genuine owner/legal gate **named precisely** in tech-decisions with the exact
  owner deliverable and the PWA-license decision, so it is tracked, not lost.

## Affected Components

### Files to Create
- `src/render/dogModelSource.ts` (+ `.test.ts`) — `DOG_MODEL_URL` const and the pure
  `resolveDogModelSource({ allowLicensed, licensedAssetPresent })` selector.

### Files to Modify
- `src/render/dogModelLoader.ts` (or wherever 078 puts the fetch) — load
  `resolveDogModelSource(...)` / `DOG_MODEL_URL` instead of a hard-coded string.
- `.docs/tech-decisions.md` — record the swap recipe + the precise owner/legal gate.
- `public/models/CREDITS.md` — cross-link the swap procedure.

## Technical Approach

### Architecture Decisions
- **One source of truth.** All model-path knowledge lives in `dogModelSource.ts`;
  the loader imports it. No string literals elsewhere.
- **Pure selector, TDD.** The "which file?" decision is pure logic → unit-test it
  (this is functional code → test-first per CLAUDE.md). The actual fetch stays in
  078's loader glue (Visual Review).
- **Web-bundle safety is structural.** The licensed `.glb` stays gitignored in
  `models-build/`; only the CC0 file lives under `public/`. Document that the licensed
  build path (Capacitor/native, or a pack/encrypt step) is where the licensed file is
  introduced — never copied into `public/` on a web build.

### Behaviours to test (TDD)
1. `allowLicensed=false` → returns the CC0 `DOG_MODEL_URL` (web default).
2. `allowLicensed=true, licensedAssetPresent=false` → CC0 fallback (never an empty/
   missing path).
3. `allowLicensed=true, licensedAssetPresent=true` → the licensed model path.

### Before / After

Before (078 loader, hard-coded path):
```ts
// somewhere in the loader glue
const result = await loadGlb('/models/dog.glb');
```

After (single source of truth + tested selector):
```ts
// src/render/dogModelSource.ts
export const DOG_MODEL_URL = '/models/dog.glb'; // CC0 placeholder, web-safe to ship

export interface ModelSourceInput {
  /** Build allows the licensed asset (e.g. native/Capacitor build, license cleared). */
  allowLicensed: boolean;
  /** The licensed glb is actually present in this build. */
  licensedAssetPresent: boolean;
}

/** Pick the live dog model, always falling back to the web-safe CC0 placeholder. */
export function resolveDogModelSource(
  { allowLicensed, licensedAssetPresent }: ModelSourceInput,
): string {
  return allowLicensed && licensedAssetPresent
    ? '/models/labrador.glb'   // licensed — only introduced in a license-cleared build
    : DOG_MODEL_URL;           // CC0 fallback (web default)
}
```
```ts
// loader glue
import { resolveDogModelSource } from './dogModelSource';
const url = resolveDogModelSource({ allowLicensed: false, licensedAssetPresent: false });
const result = await loadGlb(url);
```

### Implementation Steps
1. TDD `resolveDogModelSource` through behaviours 1–3 (red → green).
2. Add `DOG_MODEL_URL`; point 078's loader at the selector/const.
3. Document the swap recipe + the precise owner/legal gate in tech-decisions; cross-
   link from CREDITS.md.
4. Confirm `bun run build` ships only the CC0 `dog.glb` (no licensed file in `dist/`).

## Risks & Considerations
- **Don't introduce the licensed file now.** This task only prepares the seam; staging
  `labrador.glb` happens once the owner delivers the texture + the PWA decision is made.
- Keep the CC0 default genuinely web-safe (CC0 = no attribution/redistribution issue).

## Acceptance Criteria
- [x] `resolveDogModelSource` is pure + TDD-covered (3 behaviours; CC0 fallback never
      yields an empty/missing path).
- [x] `DOG_MODEL_URL` is the single source of truth; 078's loader imports it (no
      hard-coded model-path string elsewhere — `grep` clean).
- [x] tech-decisions records the one-line swap recipe **and** names the exact owner
      deliverable (`Labrador_Albedo1.png` + texture folder) and the PWA-license decision.
- [x] `bun run build` output (`dist/models/`) contains only the CC0 `dog.glb`; no
      licensed `.glb` enters the web bundle or git.
- [x] `bun run verify` green; no visual change (CC0 stays live until the owner delivers).

---

## Resolution

**Files Created:**
- `src/render/dogModelSource.ts` — single source of truth for model paths; exports `DOG_MODEL_URL` (CC0) and the pure, TDD-tested `resolveDogModelSource({allowLicensed, licensedAssetPresent})` selector.

**Files Modified:**
- `src/render/scene.ts` — imported `resolveDogModelSource`; replaced hard-coded `'/models/dog.glb'` at line 147 with selector call + explanatory comment about the one-line swap recipe.
- `.docs/tech-decisions.md` — added new section 3h documenting the single source of truth, the one-line swap recipe, and the precise named owner/legal gates (missing texture, PWA-license decision).
- `public/models/CREDITS.md` — cross-linked to the swap procedure in tech-decisions §3h.

**Build verification:**
- All 4 tests in `src/render/dogModelSource.test.ts` pass (RED → GREEN).
- `grep` across `src/` for `'/models/dog.glb'` and `'models/labrador.glb'` finds only `dogModelSource.ts` (single source of truth achieved).
- `bun run build` output `dist/models/` contains **only** `dog.glb` (CC0 placeholder); no licensed `.glb` leaks into the web bundle.
- `bun run verify` summary: **green** (typecheck + 715 tests + build all pass).
- **No visual change** — CC0 placeholder stays live on web; the licensed model remains gated by owner delivery (texture + PWA-license decision).

**The one-line swap recipe is now complete:** stage the licensed `labrador.glb` into the license-cleared build path (Capacitor or pack/encrypt on web), then flip `{allowLicensed: false, licensedAssetPresent: false}` to `{allowLicensed: true, licensedAssetPresent: true}` in `scene.ts` line 150. The gate is structural: CC0 fallback is always available if the licensed asset is absent or disallowed.

**Next Steps**: once the owner supplies the texture folder and the PWA-license scope is
decided, stage the licensed `labrador.glb` into the license-cleared build path and flip
the selector inputs — a one-line change thanks to this task.
