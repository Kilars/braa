# Tech Decisions (Open)

Technical questions parked during functional design. The **what/how-it-plays**
lives in [specs.md](https://github.com/Kilars/braa/blob/deprecated-game/.docs/specs.md); this file tracks **how we build it**. Nothing here
is final.

## 1. Architecture / Stack — DECIDED

**A PWA (web) front end with a WebGL 3D layer, wrapped for the app stores via
Capacitor. Fully client-side, no backend.**

| Layer | Choice |
|-------|--------|
| Language / build | **TypeScript**, bundled with **Vite**; **Bun** as package manager / runtime |
| 3D dog rendering + animation | **Babylon.js** (WebGL) — TS-native, code-first, built-in skeletal-animation system; renders a single skinned character on a simple backdrop |
| 2D UI (BRA marker, bars, menus, economy) | **DOM / HTML-CSS overlay** on top of the Babylon canvas |
| Store distribution | **Capacitor** wraps the same web app into native iOS/Android binaries (App Store + Play Store); the project is also an installable PWA on the open web |
| Persistence | **IndexedDB**, client-side only (see §4) |
| Backend | **None** for v1 |

**Why:** satisfies "downloadable on both stores" (Capacitor), "PWA" (it is one),
"no heavy cross-platform native" (no React Native / Flutter), "client-heavy / no
server" (IndexedDB, no backend), and "engine-grade animation without a full game
engine" (Babylon is a web-native engine, not a Unity/Godot runtime). A single
animated dog on a simple scene is well within mobile WebGL budget.

**Caveats:** profile on a real mid-range Android early; the genuine risk is the
3D dog art/animation pipeline (§2), not the architecture.

**Fallback:** if web 3D animation proves too painful in practice, **Godot 4** is
the escape hatch (small mobile exports, real 3D, free) — switch only if web
genuinely blocks, since it forfeits the PWA / instant-deploy / no-native-weight
benefits.

**Prototype first:** v1 is a "vertical slice on feel" — validate the BRA timing
with placeholder art before investing in the 3D pipeline.

## 2. Rendering — Dog Shadow Approach (DECIDED)

**Blob shadow (disc decal), not a shadow map.**

A flat semi-transparent dark disc (`MeshBuilder.CreateDisc`) at world y≈0.01 provides
the contact shadow required by D12, with zero shadow-map cost on mobile. The disc
tracks the dog's lateral x each frame (called from the render loop in `scene.ts` via
`dog.updateShadowX`), so it stays centered during confused jitter and distractor lean.
A real `ShadowGenerator` with `DirectionalLight` would look marginally sharper but adds
a non-trivial per-frame GPU cost; the blob is indistinguishable at phone size.

## 2b. Rendering — Training-Ground Backdrop (DECIDED)

**Cheap gradient backdrop via DynamicTextures + back-plane, no skybox or post-processing.**

Implemented in `src/render/backdrop.ts` (called from `scene.ts`):
- **Sky gradient**: a large back-plane quad at z=−14 with a `DynamicTexture`
  vertical gradient (pale horizon `rgb(0.76,0.89,0.98)` → richer sky-blue top
  `rgb(0.32,0.55,0.88)`). `renderingGroupId = 0` puts it behind everything; unlit
  (`disableLighting = true`) so the texture colour is direct. One extra quad draw
  call per frame; textures created once at setup.
- **Ground radial gradient**: the 10×10 ground gets a `DynamicTexture` radial
  gradient (bright vivid grass at centre → desaturated edge), focusing the eye on the
  dog and softening the ground-to-sky join. The far edge colour matches the sky
  horizon so there is no hard horizon line.
- **Corner vignette**: a flattened inside-hemisphere shell (backFaceCulling off,
  alpha=0.28) around the scene darkens corners and frames the dog without any
  post-processing pipeline.
- **Key light**: added a warm `DirectionalLight` (3/4 front, intensity 0.7) to give
  the dog crisp separation from the backdrop; the `HemisphericLight` intensity
  dropped to 0.8 as softer ambient fill. No shadow generator added.
- Per-frame cost: two extra quad draw calls (sky plane + ground) + the shell. All
  textures drawn once at init. No post-processing. Safe on mobile.

## 2c. Rendering — Kennel-Tier Backdrop Upgrades (DECIDED, 2026-06-17, task 095)

**Four visual tiers (0–3) keyed to the count of owned kennel upgrades; props are
low-poly Babylon primitives placed at the scene edges.**

Implementation in `src/render/backdropTier.ts` (pure, fully tested) +
`src/render/backdrop.ts` (`applyBackdropTier`) + `src/render/scene.ts`
(`setKennelUpgrades` handle method) + `src/main.ts` (initial pass + purchase hook).

### Tier → visual mapping

| Tier | Owned upgrades | What it adds vs. previous tier |
|------|---------------|--------------------------------|
| 0 | 0 | Bare ground + sky (existing backdrop) |
| 1 | 1 (`treats-pouch`) | 2 small bush spheres at far back corners; slightly brighter/greener fill |
| 2 | 2 (`clicker-pro`) | 2 more mid-edge bushes + agility props: cone pair + low jump-bar on the left edge |
| 3 | 3 (`training-dummy`) | 3 far-back bushes + fence-line (3 segments across the background); warmest fill |

### Design decisions

- **Pure tier resolution**: `kennelTier(ids)` in `backdropTier.ts` (no Babylon
  import) counts distinct valid upgrade ids, clamps to [0,3], ignores unknown ids.
  Fully unit-tested (19 tests). `backdropTierConfig(tier)` returns a config with
  monotonically non-decreasing `lushness` scalar plus per-tier prop counts and
  light-intensity deltas.
- **Props are static primitives**: bush spheres (5 segments), cones (tessellation 8),
  cylinders, boxes. No textures, no animation, no motion cues — `prefers-reduced-motion`
  is unaffected. All props use `disableLighting = true` so they read as flat-colour
  silhouettes consistent with the backdrop aesthetic.
- **Edge placement**: all props are at |x| ≥ 2.2 or |z| ≤ −1.5 (back half of the
  10×10 ground), keeping the centred dog framing zone (D12) clear. The jump-bar
  group is the closest — its nearest edge is at x = −2.2, well clear of the dog at x ≈ 0.
- **Live update, no rebuild**: `ensureTierProps(scene)` creates all prop meshes once
  (disabled) into a module-level `Map`. `applyBackdropTier(scene, tier)` only
  calls `setEnabled(true/false)` and bumps the hemi-light intensity by `cfg.fillBoost`
  — no mesh allocation per call, no per-frame cost.
- **Bootstrap tier**: `createScene(canvas, appearance, initialUpgradeIds)` resolves the
  initial tier and passes it to `setupBackdrop`, so a returning player sees the
  correct park immediately without any post-init call.
- **Save schema**: unchanged — tier is always derived from the existing
  `kennelUpgradeIds` string array; no new fields.

## 3. 3D-on-Mobile Cost (flagged)

Semi-realistic, breed-recognizable 3D models + per-breed signature animations is
the single biggest content/perf risk. Mitigations to evaluate:

- Start with a **small number of high-quality breeds**, not many cheap ones.
- Shared skeleton / retargeted animations across breeds where possible.
- Budget for LODs, draw-call limits, and battery/thermal on mid-range phones.
- Consider asset-store/base models early to avoid bespoke modeling per breed.

### Decision (2026-06-17): asset-store base model + shared-rig retargeting

The sourcing route is **resolved**. We will license a **rigged dog base model**
(glTF/`.glb`) with a shared canine skeleton and produce the breed roster via
**proportion morphs + per-breed coat textures on that one rig** — not bespoke
per-breed models, not AI-generated meshes, not a further-pushed procedural dog.
Rationale: predictable cost, proven pipeline, fastest route to the Pokémon-GO
look, and it is this section's own listed mitigation. Risk owners accepted the
money/license gate (the actual purchase is approved by the product owner).

Execution lives in the **[Pokémon-GO Visuals epic](https://github.com/Kilars/braa/blob/deprecated-game/.task-board/EPIC-pokemon-go-visuals.md)**
(tasks 077–085). Key architectural choice: the migration swaps the implementation
**behind the existing `DogMesh` contract** (`src/render/dogMesh.ts`), one breed and
one phase at a time, behind a feature flag, with the procedural dog as fallback —
so the app stays shippable throughout. Vertical slice (Labrador) first, then scale.

The chosen model's link / license / format / tri count will be recorded here by
task `077` once selected and approved.

### 3a. Candidate shortlist (task 077, 2026-06-17) — RESOLVED (purchased + dropped; see §3b/§3c)

Research done against the §3/077 selection criteria (glTF/.glb, shared rigged
canine skeleton supporting our pose channels, clean UVs for per-breed coat swaps,
~10–30k-tri mobile budget, and a license that permits **commercial use +
modification + redistribution inside a compiled app**). License terms below were
verified via vendor docs where noted; **exact price / tri-count / per-model rig
fitness must be re-confirmed on the listing at point of purchase** (not asserted
here, to avoid stale specifics).

**Assets-location convention (decided here):** imported models live in
`public/models/` and load at runtime from `/models/<file>.glb` (Vite serves
`public/` at web root; Babylon's `SceneLoader` reads that URL). **Do not commit a
paid asset until its license is recorded in this section.** A CC0 asset may be
committed freely.

| # | Source | Role | License (verified) | Look | Notes |
|---|--------|------|--------------------|------|-------|
| 1 | **TurboSquid** rigged dog, *Royalty-Free* license | **Final look (Track B)** | RF **allows use inside a compiled mobile game**; **forbids redistributing the raw model file** ([TurboSquid RF FAQ](https://www.turbosquid.com/help/en/articles/9937423-royalty-free-license-faq)) | Semi-realistic — matches the Pokémon-GO ceiling | Often FBX/OBJ → convert to `.glb` via Blender; verify rig covers sit/lie/spin/roll + head channels before buying |
| 2 | **CGTrader** rigged dog, *Royalty-Free* (exclude "Editorial only") | Paid fallback to #1 | Royalty-Free, redistribution-in-app — **verify exact per-listing terms** ([CGTrader dog-rig](https://www.cgtrader.com/3d-models/dog-rig)) | Semi-realistic options exist | Some listings ship glTF natively (no convert step) |
| 3 | **Quaternius** CC0 dog (LowPoly Animated Animals / Universal Animation Library) | **De-risk placeholder (Track A)** | **CC0** — commercial, modify, redistribute, **no attribution** ([Quaternius](https://quaternius.com/)) | Stylized low-poly (below the ceiling) | Rigged + animated, glTF available — proves the pipeline at **zero cost/legal risk** |

**Recommendation — two-track (HISTORICAL — both tracks now executed; see §3b/§3c):**

- **Track A (de-risk now, free):** stage a **Quaternius CC0** dog as
  `public/models/dog.glb` to prove the `078` loader + `079` imported-`DogMesh`
  slice end-to-end **with real Visual Review at zero cost and zero legal risk**.
  CC0 means no money/likeness/attribution gate — it validates the whole pipeline
  behind the (default-off) flag before any purchase.
- **Track B (final look — the chosen, now-purchased track):** a
  **semi-realistic Royalty-Free** rigged dog for the shipped aesthetic, dropped in
  behind the **same `DogMesh` seam**. Executed via the Dogs Big Pack Labrador (§3b/§3c).

Rationale (as recorded at decision time): this unblocked engineering immediately
without spending money, while the money/likeness decision stayed with the owner.
Outcome: the owner went straight to Track B and purchased the Labrador (§3b).

**Escalation to owner — RESOLVED (2026-06-19):** the owner approved committing the
CC0 placeholder (done), chose and purchased the realistic Labrador (§3b), and dropped
the asset (`Labrador_FBX.rar`, §3c). The distribution / raw-`.glb` licensing question
is settled by the PWA-first + pack-on-web stance (§3d).

**Status:** research, shortlist, purchase, and file-drop all complete. The **one
remaining step before the licensed model renders is converting the FBX → `.glb`** (see
§3c; `public/models/dog.glb` is still the CC0 placeholder). `078`'s pure load-decision
core (`selectDogRenderMode` + `resolveLoadState` + default-off `renderConfig` flag) was
landed test-first, so the loader/scene glue is a drop-in once the converted glb exists.

### 3b. Owner decision (2026-06-19): buy "Dogs Big Pack" Labrador ($30), realistic track

After an in-engine **bake-off** (free candidates rendered in the real scene/lighting:
Quaternius/Poly-Pizza low-poly + Objaverse high-poly), the owner judged low-poly
"too basic" and chose the **realistic** track. Concrete pick:

- **Pack:** **Dogs Big Pack** (CGTrader / Sketchfab Store / Fab) — Royalty-Free (no-AI).
  19 realistic PBR breeds × 3 colours, **100+ animations** (incl. literal `sit` /
  `lie` / `sleep` / `bark` / `idle` that map onto Sitt/Ligg + dog states), **mobile
  model 2,500–3,500 tris + 4 LODs**, 2048 PBR maps. Breeds cover **4/5** of ours
  (Labrador, Border Collie, French Bulldog, Husky); **no Poodle** → Puddel needs a
  substitute/restyle later.
- **Scope approved now:** **one breed — Labrador, $30** (vertical slice first). Buy the
  rest only after the slice passes Visual Review in motion.
- **Format:** ships FBX/OBJ/BLEND (no native glb) → **convert FBX → glb in Blender**,
  stage at `public/models/dog.glb`.
- **Human gate — purchase + drop DONE (2026-06-19):** the owner bought the pack and
  dropped the FBX (`Labrador_FBX.rar` at repo root, see §3c). **Remaining step: convert
  FBX → glb** and stage at `public/models/dog.glb`; then wire/review (078/079).
- **⚠️ License reality (cross-vendor, newly confirmed):** every paid RF/Asset-Store
  license forbids end-users **extracting the raw file**. Native (Capacitor) bundle =
  clean; raw **web-PWA** serving the `.glb` = the gray area. PWA scope for the licensed
  model is an open owner call; the **CC0 placeholder** below is unaffected.
- **Placeholder staged (done):** a **CC0** dog is at `public/models/dog.glb`
  (see [`public/models/CREDITS.md`](https://github.com/Kilars/braa/blob/deprecated-game/public/models/CREDITS.md)) to prove the pipeline.
- **Loader/scene wiring (078 glue + 079 imported `DogMesh`): NOT YET BUILT** — deferred
  at the owner's request (2026-06-19). The pure cores already exist; the glTF-loader
  dependency, async `loadDogModel`, `createImportedDogMesh`, and `scene.ts` wiring + the
  Visual Review are still to do. Flag stays default-OFF, so the app is unchanged today.

### 3c. Asset received (2026-06-19): `Labrador_FBX.rar` (Dogs Big Pack — Labrador)

The owner purchased + dropped the Labrador. Archive at repo root: **`Labrador_FBX.rar`**
(22 MiB, RAR5, 111 MiB uncompressed). Confirmed Dogs Big Pack structure. Manifest:

| File | Size | Role for us |
|------|------|-------------|
| `Labrador.fbx` | 707 KB | base desktop mesh (static) |
| `Labrador_anim_IP.fbx` | 52 MB | **animated — In-Place.** ✅ the source we want — the dog trains stationary, so In-Place (not Root-Motion) clips are correct |
| `Labrador_anim_RM.fbx` | 52 MB | animated — Root-Motion (locomotion travels; not needed here) |
| `Labrador_LOD.fbx` | 1.7 MB | LOD chain (4 levels) |
| `Labrador_LowPoly.fbx` | 249 KB | **mobile-budget mesh** (~2.5–3.5k tris) — ✅ primary candidate for the PWA/Capacitor build |
| `Labrador_NoAlpha.fbx` | 681 KB | coat variant without alpha-mask texture |
| `Import_settings/` | — | vendor screenshots: Blender / Maya / C4D FBX import settings (use for the convert step) |

**Conversion RESOLVED (2026-06-20) — see §3e.** The FBX → glb conversion was previously
parked as "blocked" (no tooling / archive thought corrupted). Both assumptions were wrong:
the archive is intact and a headless, no-sudo toolchain converts it cleanly. §3e has the
working recipe, the full clip inventory, and the one genuine remaining gap (a missing
texture map).

**Licensing reminder (still applies — see §3b):** Royalty-Free / no-AI. Fine bundled in
the compiled Capacitor app; the raw-`.glb`-in-a-web-PWA extraction question is unresolved
and must be decided before the licensed model ships on web. `Labrador_FBX.rar` and any
converted `.glb` of it are the **paid asset** — do NOT treat them like the CC0 placeholder
(e.g. mind what gets served fetchable in the web build).

### 3d. Distribution stance (2026-06-19): PWA-first; pack/encrypt the licensed model on web

Owner preference: **ship browser-based (PWA) first** — instant updates, one codebase, no
App-Store/Play-Store signing + review overhead. This matches the existing architecture
(CLAUDE.md: client-only PWA; Capacitor is an *optional* later wrapper for store presence).

Consequence for the paid Labrador's "no raw-file extraction" clause (§3b), which bites
**only on web**: the agreed mitigation is to **pack/encrypt the licensed `.glb`** so it is
not served as a plain open-format file — decrypt in memory at load time. This satisfies the
"not redistributed in an open format" letter of the RF license while keeping the realistic
dog on the preferred web build. (The clause's real intent is to stop asset *resale*, not
browser caching; packing addresses the letter, and practical risk for an indie PWA is low.)

**Owner re-confirmed 2026-06-20 (interactive):** pack/encrypt on web, after the textured
licensed glb was produced (`models-build/out_anim.glb`, albedo+normal embedded — see §3e).
Implementation tracked in **task 103** (build-time AES-GCM pack + decrypt-in-memory load).
Recorded caveat: client-side key = **deterrence, not DRM** (key ships in the bundle); it
defeats casual raw-fetch and matches the compiled-bundle bar, but is not unbreakable.

### 3e. FBX → glb conversion RESOLVED (2026-06-20) — headless toolchain + clip inventory

The conversion that gated the whole visuals epic (077–079, 098 remainder) is **done and
reproducible without sudo, Blender, or a GUI.** The two prior "blockers" were both false:

- *"Archive corrupted / can't extract"* — **wrong.** `Labrador_FBX.rar` is RAR5 using
  RAR-7.x compression (method `v6`). System `7z` (even 7-Zip **24.08**, current) reports
  `Unsupported Method` — 7-Zip's RAR codec doesn't implement RAR 7's algorithm — so it
  wrote **0-byte** files and looked like corruption. It isn't: **`node-unrar-js`** (npm,
  WASM port of the official unRAR) extracts every entry at full size.
- *"No FBX→glb tooling in the env"* — **wrong.** The **`fbx2gltf`** npm package ships a
  prebuilt Linux binary (`node_modules/fbx2gltf/bin/Linux/FBX2glTF`, v0.9.7) that converts
  cleanly.

**Working recipe (dev-only deps; both keep the licensed asset out of git):**
1. `npm i node-unrar-js fbx2gltf` (dev-only; not added to `package.json` — run ad hoc).
2. Extract FBX from `Labrador_FBX.rar` via `node-unrar-js` (`createExtractorFromData`).
3. `FBX2glTF --binary --anim-framerate bake30 -i Labrador_anim_IP.fbx -o dog`.

**What the converted glb contains** (`Labrador_anim_IP.fbx` → 7.5 MB glb):
- Rigged single mesh — **8 682 verts**, 60-node skeleton, 1 skin. (Base `Labrador.fbx` →
  0.6 MB glb, same mesh, no clips.)
- **113 animation clips**, covering *every* clip the gated tasks needed:
  `Sitting_*` (Sitt), `Lie_*`/`Lie_belly_*` (Ligg / disengage flop), `Bark`,
  `Scratching` (disengage itch), `Digging_*`, `Idle_1..7`, `Walk_*`/`Trot_*`/`Run_*`,
  `Turn_*`/`Turn_*180` (walk-away/call-back), `Jump_*`, `Crouch_*`, plus many unused
  (Swim/Attack/Death/Eat/Drink/Pissing/Defecate — ignore). The 098/079 animation gate is
  fully satisfied. Artifacts persisted to gitignored `models-build/` (out_anim.glb /
  out_base.glb).

**Genuine remaining gap — missing texture (owner action):** the FBX references an
**external** albedo map `Labrador_Albedo1.png` (absolute path `D:\My_Work\For_asset\Dogs 2\
Labrador\texture\Labrador_Albedo1.png`); **that file is not in the archive** (the only
images present are `Import_settings/` screenshots). So the glb converts with a material but
**no colour texture → renders white.** To get the realistic Labrador skin the owner must
supply the pack's texture folder (`Labrador_Albedo1.png` + any normal/roughness/AO maps).
**This does not re-block integration:** 078/079 can wire the rigged + animated mesh now
behind the default-off `renderConfig.importedDog` flag using a fawn fallback `baseColorFactor`,
Visual-Review the silhouette + animation, and drop the photoreal texture in later.

**Still owner/legal-gated before the licensed model ships (not before integration):** the
web-PWA raw-`.glb` extraction clause (§3b/§3d) — pack/encrypt or native-gate at ship time.

**TODO when wiring the real model:** add the pack/decrypt step to the load path (`078`
`loadDogModel`) for the licensed `.glb` only; the CC0 placeholder needs no packing. A later
Capacitor native build can bundle the model compiled and skip packing entirely.

### 3f. Imported `DogMesh` wired behind the flag (2026-06-20, tasks 078/079) — pipeline proven, flag OFF

`createImportedDogMesh` (`src/render/importedDogMesh.ts`) implements the full `DogMesh`
contract over a loaded glb, and `scene.ts` swaps to it when `selectDogRenderMode()==='imported'`.
The flag (`renderConfig.importedDog`) stays **default OFF**: the CC0 placeholder renders a
recognizable dog but reads worse than the tuned procedural one (oversized/generic) — the win
is the **proven pipeline**, ready for the licensed Labrador (swap = task 102). Visual-Review
the imported path in DEV with `?importedDog=1`.

Implementation notes for whoever wires the **licensed** model:

- **Lazy chunking (web-bundle hygiene).** The glTF loader (`@babylonjs/loaders/glTF`,
  `Loading/sceneLoader`) and the **PBR material stack** are reached *only* via dynamic
  `import()` (`loadDogModel` + a dynamic `import('./importedDogMesh')` inside the flag-gated
  block in `scene.ts`). `vite.config.ts` `manualChunks` routes `@babylonjs/loaders` +
  `Materials/PBR` to a separate **`babylon-loaders`** chunk (~315 kB) so none of it ships to
  flag-off users at parse time. `import.meta.env` is typed via `src/vite-env.d.ts`. Babylon's
  glb **scene-loader subsystem** does leak into the always-on `babylon` chunk (pushing it to
  ~2.1 MB) because manualChunks can't cleanly split its transitive `@babylonjs/core/*` deps;
  workbox `maximumFileSizeToCacheInBytes` is raised to 3 MiB and `chunkSizeWarningLimit` to
  2500 so the engine still precaches for offline. The licensed file must **never** be copied
  into `public/`/`dist/` on a web build (§3d).
- **Skinned-model framing (the sliver trap).** The CC0 glb is a *rigged* model
  (`RootNode → AnimalArmature ×100 → bones`, **1 skinned mesh, 1 material, ~3.6 k tris**).
  `createImportedDogMesh` must (a) re-parent the model's **topmost ancestor** under its pivot
  (re-parenting leaf meshes strips the armature/coordinate transforms → the mesh collapses to
  a vertical sliver), and (b) compute the framing bbox with `mesh.refreshBoundingInfo({
  applySkeleton: true })` so the 100× armature is reflected (bind-pose verts ignore it). The
  real Labrador rig may differ — re-run the `?importedDog=1` Visual Review and tune
  `TARGET_HEIGHT`/centering when it lands. **Gotcha (fixed in §3j/task 080):** `applySkeleton`
  bakes whatever clip the loader auto-started into the bounds, so the load path now forces
  `animationStartMode = NONE` to frame at the rest pose.
- **Pose channels.** Whole-body channels (roll/yaw/breathe) map onto the root; per-part
  channels (head/tail/spine) map onto bones found by case-insensitive name and **no-op
  gracefully** if absent (full skeletal clips are a later phase).

### 3h. Dog-model source-of-truth + the one-line licensed swap (2026-06-20, task 102)

**`src/render/dogModelSource.ts` is the SINGLE place the model path lives.** All model-path knowledge lives here: the CC0 placeholder `DOG_MODEL_URL` (`/models/dog.glb`, web-safe, no attribution/redistribution issue) and the pure, TDD-covered `resolveDogModelSource({allowLicensed, licensedAssetPresent})` selector. Scene.ts calls the selector; no other hard-coded model path exists in `src/`.

**The one-line swap recipe (when the owner delivers the texture + the PWA-license scope is decided):**
1. Stage the licensed `labrador.glb` into the license-cleared build path (Capacitor native bundle or a pack/encrypt step on web — **never** into `public/` on a web build per §3d).
2. Flip the selector inputs in `src/render/scene.ts` from `{allowLicensed: false, licensedAssetPresent: false}` to `{allowLicensed: true, licensedAssetPresent: true}`. That is the entire code change.

**Owner/legal gate status for the real asset (neither blocks task 102, which keeps CC0 live):**
- **(1) Texture — SUPPLIED (2026-06-20), no longer a gate.** Originally absent from the
  drop (the PO-named `Labrador_Albedo1.png` + maps, §3e), but the owner has since supplied
  `Labrador_Textures.rar`; the albedo + maps are embedded into the gitignored
  `models-build/out_anim.glb` (~19.7 MB) via `scripts/skin-dog-model.mjs` (see
  `public/models/CREDITS.md`). The task-102 selector is ready to consume the textured
  licensed glb once it is staged into a license-cleared build.
- **(2) Web-PWA license decision (owner/legal) — the one operative remaining gate.** The
  Royalty-Free license forbids end-users extracting the raw file; the **CC0 placeholder** has
  no such constraint. Decide the PWA scope (pack/encrypt-on-web vs native-only Capacitor, per
  §3d) before the licensed `.glb` ships on web. The selector's `allowLicensed` flag gates the
  choice architecturally — no code change needed once the policy is decided, only the
  per-build-context selector input.

**Web-bundle safety is structural:** the licensed `.glb` stays gitignored in `models-build/`; only the CC0 file at `public/models/dog.glb` is committed, so `bun run build` ships only `dog.glb`. The selector always falls back to CC0 if the licensed asset is absent or disallowed, never yielding an empty/broken path.

### 3i. Pack/encrypt + decrypt-in-memory load IMPLEMENTED (2026-06-20, task 103)

The §3d "pack on web" stance is now built and **verified end-to-end** — the real
textured Labrador renders from an AES-GCM-encrypted artifact, never from a plain glb.

- **Crypto core** — `src/render/assetCrypto.ts` (pure, TDD): `encryptAsset`/`decryptAsset`
  over Web Crypto AES-256-GCM. Wire format `IV(12) ‖ ciphertext+tag`. Tested for lossless
  round-trip, fresh-IV-per-call, and rejection on wrong key / tampered blob / truncation.
  The identical scheme runs in the browser and in Node, so build and runtime agree.
- **Bundle key** — `src/render/dogPackKey.ts` holds the base64 AES key. **Intentionally
  public**: the browser must decrypt, so the key ships in the bundle → **deterrence, not
  DRM** (documented in-file). The build script reads this same constant (single source of
  truth) so the artifact decrypts with the runtime key.
- **Source descriptor** — `resolveDogModelDescriptor()` (added alongside the unchanged
  `resolveDogModelSource`, whose tests stay green) returns `{ kind: 'plain', url:
  '/models/dog.glb' }` for CC0 or `{ kind: 'packed', url: '/models/dog.pack' }` for the
  licensed web path. The loader branches on `kind`.
- **In-memory load** — `loadPackedDogModel`/`packedToGlbFile` (`dogModelLoader.ts`):
  decrypt → wrap bytes in an in-memory `File('dog.glb')` → Babylon's glTF loader reads from
  memory. **No plaintext glb ever touches `public/`, `dist/`, git, or a fetchable URL.**
- **Build step** — `scripts/pack-dog-model.mjs` (`bun run pack-dog-model`): AES-GCM-encrypts
  `models-build/out_anim.glb` → `public/models/dog.pack`, self-verifies the round-trip, and
  is **gitignored** (encrypted but key-recoverable → treated like the raw licensed asset).
  The default (CC0) build does not carry it; regenerate on demand when shipping licensed.
- **Reaching it for review** — DEV-only `?licensedDog=1` (+`?importedDog=1`) routes the load
  through the packed descriptor (`devOverrideLicensedDog`, no effect in prod). Committed
  default is unchanged: `allowLicensed:false` → CC0 plain glb.

**Visual Review (2026-06-20):** packed path fetched (200, 18.7 MB), decrypted in memory, and
rendered the Labrador with **correct matte fur (not white/metallic)** — the encryption
deliverable is proven. The facing + skeletal-clip follow-ups are now done in **task 080
(§3j)**: the licensed Labrador faces the camera and plays a distinct embedded clip per state,
and on its own reads **clearly ≥ the procedural baseline**. The committed
`renderConfig.importedDog` flag nonetheless **stays OFF** — but for a NEW reason (§3j): the
default web build cannot carry the licensed pack, so flipping the flag would ship the much
weaker *CC0* dog, not the Labrador. See §3j for the full flag rationale.

### 3j. Imported dog — camera-facing + skeletal clips + the auto-start framing fix; flag still OFF (2026-06-20, task 080)

Closes the two engineering follow-ups §3i named, plus a load-path bug they surfaced. The
licensed Labrador now faces the camera and animates per state; on its own it reads **clearly
≥ procedural**. The committed flag still stays OFF — for a packaging reason, not a quality one.

- **Camera-facing yaw on a dedicated pivot, NOT the root.** `applyPose` owns `root.rotation.y`
  (the `bodyYaw` spin trick), so a `facingPivot` between `root` and the framing pivot carries
  the constant `CAMERA_FACING_YAW = 3π/4` (front-three-quarter hero angle). The fit *scale*
  also lives on `facingPivot` (not `root`) because `scene.ts` overwrites `root.scaling` every
  frame for the per-state pop; a Y-rotation about the centred axis is height/centre-preserving,
  so facing + fit-scale compose cleanly on one node. The spin trick still works (composes on top).
- **State → clip resolver** (`dogAnimationMap.ts`, pure + TDD, 16 tests): `resolveStateClip`
  maps each `DogVisual` to a preferred embedded clip (matched past the `Arm_Labrador|` prefix,
  case-insensitively, with family fallback) or `null` → keep the procedural pose. `clipMotionScale`
  damps the playback *rate* under `prefers-reduced-motion` (D13: calm, not frozen); `clipLoops`
  loops every sustained state. Render glue in `importedDogMesh.setVisualState` starts the resolved
  `AnimationGroup` on state change and restores a bind-pose snapshot first so a subtle clip can't
  inherit the previous clip's body pose.
- **idle → `Idle_2`, NOT `Idle_1` (Visual-Review finding).** On this rig `Idle_1` is a *seated*
  idle — visually identical to the seated `offering` (`Sitting_loop_1`). `Idle_2` is the *standing*
  calm idle, so idle (standing) vs offering (sitting) are tellable apart at a glance. Falls back
  to `Idle_1` then any `Idle`-family clip for rigs without `Idle_2`.
- **Bug fix — disable the glTF loader's animation auto-start (`dogModelLoader.ts`).** Babylon's
  glTF loader auto-plays the FIRST embedded clip on load. `createImportedDogMesh` frames the dog
  from `refreshBoundingInfo({ applySkeleton: true })`, which **bakes that auto-started pose into the
  bounds**. For the CC0 rig the first clip is `Death` (dog sprawled flat) → bbox went `x: 0..2.398`
  → garbage fit scale → an *exploded* render. Fix: a scoped `SceneLoader.OnPluginActivatedObservable`
  hook sets the glTF loader's `animationStartMode = NONE` for the load, so bounds + the bind-pose
  snapshot are taken at the authored REST pose for any rig (CC0 bbox became a sane symmetric
  `x: -0.475..0.475`); the per-state clip is then started explicitly. The Labrador happened to dodge
  this (its first clip, `Attack_Bite`, is compact) but is correct now too.
- **Flag decision — `renderConfig.importedDog` stays default OFF (per the 079 rule).** The rule is
  "flip ON only if the dog that actually ships ≥ procedural." The licensed Labrador is ≥ procedural,
  but it ships ONLY via the DEV `?licensedDog=1` override or a native/Capacitor license-cleared build
  — never the default web build (the pack is gitignored, §3d/§3i). So flipping the committed flag would
  put the **CC0** dog on the live web build, and CC0 Visual-Reviews **below** the polished procedural
  dog (a jumble of blocky, semi-detached shapes vs a coherent stylised dog). Verified head-to-head on
  a 390×844 portrait viewport: **Labrador ≫ procedural ≫ CC0-imported.**
- **Remaining delta to default-ON** (no longer pure engineering): either (a) the licensed Labrador
  ships in the default build — an **owner/license/packaging** decision (ship the 18.7 MB pack on web,
  or ship native-only), and then validate that load/decrypt budget on a real device (perf phase 085);
  or (b) source a web-safe CC0-class model that itself reads ≥ procedural. All the engineering above is
  landed and stays in place behind the flag; the DEV override path renders the Labrador at full quality.

**Hardening before the flag-flip (2026-06-21, task 111).** Three latent defects in
`importedDogMesh.ts` were fixed while the flag is still OFF, so the eventual swap is clean:
(1) **Head-bone Y drift** — `applyPose` did `headBone.position.y += pose.headLiftY` every frame,
*accumulating* the lift onto the previous frame's value so the head walked upward unboundedly.
Now bind-relative: `captureBindPose`-adjacent code snapshots the head bone's bind-pose Y once
(`headBindY`) and `applyPose` *assigns* `headBone.position.y = headBoneY(headBindY, pose.headLiftY)`
via a pure, TDD-covered helper (`headBoneY(bindY, lift) = bindY + lift`) — mirroring the procedural
dog's `headPivot.position.y = 0.28 + headLiftY` rest-relative model. (2) **`setEmissiveMat`** collapsed
to a single `emissiveColor.copyFrom` — both PBR and Standard expose `.emissiveColor`; only the
*diffuse* split (`albedoColor` vs `diffuseColor`) needs the type branch. (3) **Dead Phase-2 captures**
`_originalDiffuse`/`_originalEmissive` (and the `getDiffuse` reader that only fed them) removed — they
had no consumer and were eslint-suppressed; **task 082 must re-capture** the glb's own diffuse/emissive
if it wants raw-colour restoration (see the note at the foot of `importedDogMesh.ts`).

## 3e. UI test harness — jsdom for `src/ui/**` only (DECIDED, 2026-06-19, task 101)

The pure game-logic suite runs under Vitest's fast `node` environment. The DOM-bearing
UI layer (the five panel factories + future `hud` tests) needs a real `document`, so
`vite.config.ts` adds `test.environmentMatchGlobs: [["src/ui/**", "jsdom"]]` — node stays
the default; only `src/ui/**` opts into jsdom (`jsdom` is a dev dependency). Per-file
`// @vitest-environment jsdom` docblocks make the env explicit at the top of each UI test.
Task 101 added behavior tests for `adoptPanel` / `kennelPanel` / `settingsPanel` /
`helpPanel` / `achievementsPanel` (24 tests) through their public `PanelHandle` (gate
legibility classes, buy/adopt/reset flows, open/close, list re-render) — characterization
of current behavior, asserting observable DOM not internals so they survive refactors.

### 3g. e2e full-loop is render-rate-independent (2026-06-20, task 079 follow-up)

Headless Chromium software-renders the Babylon scene (`--disable-gpu` → SwiftShader), which
throttles `requestAnimationFrame` to **~3 fps** under load. The full-loop e2e originally timed
its taps to the apex by reading the rAF-driven `#hud[data-tell]` signal — at 3 fps that signal
is too stale to hit the ~400 ms scoring window, so every tap MISSed and the gate failed (a pure
environment limitation; gameplay/scoring code was unchanged and unit-tested). Fix:
`window.__bra.nextPeak()` (DEV-only hook in `main.ts`) exposes the next attempt's peak
timestamp, and `e2e/full-loop.mjs` schedules the tap *inside the browser* — sleeping most of the
gap, then **busy-waiting** the final ~350 ms (> one ~300 ms frame) so the single JS thread can't
be preempted by a render frame, landing a precise PERFECT regardless of frame rate. Scoring
itself runs synchronously on `pointerup`, so it never depended on the frame rate. The deprecated
`data-tell` polling path is removed.

### 3k. First-run coach for the core verb — DECIDED (2026-06-21, task 108)

specs.md §Onboarding wants the first session to **actively teach the one core verb**
("wait for the apex, tap BRA"). Before this we only had the passive `?` help overlay
(task 048) behind a button — a new player got no in-context prompt during their first
round. Added an in-context coach pill `#hud-coach` ("Vent på pulsen — trykk BRA!") shown
on the first round only.

- **Pure gate** (`shouldCoachCoreVerb({ masteredCount, hasMarkedSuccessfully })` in
  `src/core/onboarding.ts`, TDD): true only when `masteredCount === 0 &&
  !hasMarkedSuccessfully`. So it shows for a brand-new player, **auto-dismisses on the
  first scoring (PERFECT/OK) mark**, and never shows to a returning trainer.
- **State**: `hasMarkedSuccessfully` is a **runtime** flag in `main.ts` (not persisted —
  like `combo`/engagement). A player who quits before mastering may see the coach again
  next session; harmless, since it dismisses on the first mark. Combined with the
  persisted `masteredCount`, anyone who has mastered a trick never sees it.
- **Render**: the HUD exposes `setCoachVisible(boolean)`, reusing the shared `.hud-gated`
  (visibility+opacity) hide class; `main.ts` calls it on round start and on the first mark.
  CSS is a gold attention pill below the trick label with a gentle pulse that is removed
  under `prefers-reduced-motion` (D13). Visual-Reviewed on a 390×844 portrait viewport
  (independent agent, PASS): coach legible + clean on first run, gone after the first mark.

### 3l. Distractor-reveal coach — DECIDED (2026-06-21, task 109)

specs.md §Onboarding stages systems in "never all at once": distractors arrive around the
second trick. At `masteredCount === 1` the dog starts offering **wrong** behaviors the
player must NOT mark — a real confusion/churn point (a false mark penalises) the spec
calls out, previously uncoached. Extends the 3k pattern with a second contextual pill on
the same `#hud-coach` element.

- **Pure gate** (`shouldCoachDistractors({ masteredCount, dismissed })` in
  `src/core/onboarding.ts`, TDD): true only when `masteredCount === 1 && !dismissed`.
  Disjoint from `shouldCoachCoreVerb` by `masteredCount` (0 vs 1), so the two pills are
  **mutually exclusive** — `main.ts` also guards `!coachVerb` explicitly. The band
  **self-limits**: at `masteredCount >= 2` distractors are no longer new, so it never nags.
- **State**: `distractorCoachDismissed` is a **runtime, per-round** flag in `main.ts` (no
  `GameSave` change, like 3k). Reset on entering a round (`onSelectTrick`); set on that
  round's first scoring (PERFECT/OK) mark. Re-showing on a return visit at the same stage
  is acceptable/helpful.
- **Render**: `setCoachVisible(visible, text?)` gained an optional `text` arg — passing the
  distractor copy swaps `#hud-coach`'s text and adds `.coach-wide` (lets the full sentence
  wrap, max-width matched to `#hud-callback-hint`); omitting it restores the short core-verb
  text. One element, swapped text — HUD stacking unchanged; aria-live + reduced-motion
  parity preserved.
- **Copy**: "Noen ganger gjør hunden noe annet — ikke trykk da. Bare BRA på «{trick}»."
  Names the active trick the player SHOULD wait for. Uses the game's marker voice ("trykk
  BRA"), not an Anglicised "mark" — chosen during the polish pass over the task's example
  wording (task copy was explicitly "e.g.").
- **Visual Review** on a 390×844 portrait viewport (independent agent, PASS): pill legible
  and well-placed below the trick label, clear of the pause button / coins-level chip /
  engagement bar; distinct from the core-verb pill; confirmed gone after a scoring mark and
  absent at `masteredCount >= 2`. Capture script: `scripts/shoot-distractor-coach.mjs`
  (drives state via the `__setTrick` / `__setMasteredCount` dev hooks).

## 4. Marker Voice ("sound like Maren") (flagged)

The spec fixes the target sound: the marker voice **must sound like Maren from
_Bølle til bestevenn_** (a warm, bright, encouraging female Norwegian "bra!" with
an upward, praising lilt — see [specs.md](https://github.com/Kilars/braa/blob/deprecated-game/.docs/specs.md) → Audio). That target is not
open; only *how we source a voice that hits it* is. Open sourcing options, to
research and decide:

- **Record original voice** (the user / a friend) styled after the delivery —
  cleanest rights position, full control, manual to expand.
- **License / get permission** to use the actual voice — authentic, but requires
  outreach and likely cost/agreement.
- **Voice imitation / synth/clone of a real person** — ⚠️ **likeness & rights
  risk.** Imitating an identifiable real person's voice without consent can raise
  personality-rights/likeness issues even for a small/personal project. Treat as
  a flag, not a blocker; prefer consent-based or original-voice routes.
- **Generic TTS** — easy to scale phrases, but risks robotic delivery that
  undercuts the warm show feel.

**Recommendation:** for v1, record an **original** voice in the right *style*
(short, warm, punchy "bra!"). Revisit licensing only if the project goes public.

### 4a. Marker-voice clip pipeline + placeholder — DONE (2026-06-21, task 116)

The *target sound* above stays owner/likeness-gated, but the **whole playback pipeline
is owner-unblocked** and was the dead half: task 074 built the seam (`registerClip` /
`shouldUseClip` / `playBuffer`, and `play` already prefers a registered clip over synth),
yet **nothing ever loaded or registered a clip** (`grep registerClip src/` found only the
definition), so the voiced path was unreachable. 116 makes it live without touching the
gated recording:

- **Loader** `MarkAudio.loadClip(cue, url)` — `fetch` → `decodeAudioData` → `registerClip`,
  called at **bootstrap, off the tap path** (zero added mark latency). Fully **graceful**:
  a missing/failed asset, decode error, non-OK response, or unavailable `AudioContext`
  rejects quietly and the registry is left unchanged — the mark stays on the existing synth
  (no throw, no console spam). Proven by tests asserting `hasClip(cue)` stays `false` after
  a load that can't complete.
- **Pure phrase-keyed selection** (TDD): `voiceCue(result, phraseId?)` derives the lookup
  key (`voice:<id>` when a phrase is loaded, else the result tier); `selectVoiceClip(result,
  phraseId, registry)` is the registry-aware play-site decision — **phrase clip → tier clip
  → `null` (synth)**. `play(result, phraseId?)` is thin glue over it, so each collectible
  phrase can voice its own line (specs §Audio: *"each has its own line"*) with no call-site
  change. `main.ts` threads `loadedPhrase.id` into the mark-time `play(...)`.
- **Placeholder asset** `public/audio/bra-placeholder.wav` — a fully **synthesized,
  original** marker chime (NOT a voice; generator: `scripts/gen-voice-placeholder.mjs`),
  CC0/license-clean, registered under the `PERFECT` cue at bootstrap so a perfect mark
  voices it end-to-end. Provenance in `public/audio/CREDITS.md`. It is explicitly a
  **placeholder**: the real **Maren** marker line (§4 — owner/likeness gate, not producible
  autonomously) is a **drop-in** under the same cue / per-phrase keys with no call-site
  change. Asset path uses `import.meta.env.BASE_URL` so it resolves under the `/braa/` Pages base.

**Verification:** audio is not headless-verifiable (precedent 074/094) — the gate is the
**pure selection/loader tests** (clip chosen when registered, synth otherwise, graceful on
failure) + this code-level record. A human on-device listen of the placeholder is the one
non-blocking follow-up; the **real Maren line remains the owner gate**. **specs.md untouched.**

### 4b. Marker placeholder upgraded chime → spoken Norwegian "Bra!" (2026-06-21, task 121)

The §4a chime placeholder was an abstract tone, not the actual word. The owner asked for
"good sounds" and to **source real "Bra!" noises without blocking on a human listen**, so
the placeholder is now a **spoken Norwegian "Bra!"** — `public/audio/mark-bra-perfect.wav`
(PERFECT, brighter) and `mark-bra-ok.wav` (OK, softer/snappier), registered under those two
cues at bootstrap. Pipeline (reproducible, `scripts/gen-marker-voice.sh`): **espeak-ng**
(Norwegian Bokmål female voice) → an **ffmpeg** warming chain (trim silence, slight pitch
lift, warmth/air EQ + vocal presence, gentle de-robotize via chorus + a tiny room,
`loudnorm` to ≈−16 LUFS, fades).

- **Why TTS, not a chime:** it reads as the real word "Bra!", which is the spec's marker
  intent, while staying fully autonomous. espeak-ng was installed **without sudo** by
  extracting the `.deb`s locally (`apt-get download` → `dpkg-deb -x`) — recorded so the next
  iteration doesn't re-park this as "no TTS in the env" (cf. the verify-blockers rule).
- **License / likeness:** machine-generated TTS output, **no human recording and no imitation
  of an identifiable person** → no personality/likeness exposure (§4). Treated as
  license-clean/public-domain; espeak-ng claims no copyright over generated audio. The
  generator runs **dev-only**; CI just serves the committed WAVs.
- **Still the owner gate:** the real **"sound like Maren"** marker line (§4) — these TTS takes
  are an honest placeholder and drop out for it under the same cues with **no code change**.
  The one non-blocking follow-up is an on-device listen to judge the robotic edge; the
  pure-synth chime generator (`scripts/gen-voice-placeholder.mjs`) is kept as a no-TTS
  fallback. **specs.md untouched.**

## 5. Persistence / Save

Single-player, local progression (coins, XP/level, unlocks, kennel, idle
timestamp for the capped trickle). Needs:

- **IndexedDB** (client-side; structured save, room to grow vs. localStorage).
- A **timestamp** for computing capped idle income on return.
- No backend required for v1. Cloud save = future, only if multi-device matters.

## 6. Content / Data-Driven Design

Breeds, tricks, and phrases are all expandable catalogs. Define them as **data**
(config/tables), not hardcoded, so new content is authored without code changes.
Tunable per entry: window width, distractor rate, learn speed, intrinsic
difficulty, rewards, phrase cooldown/effect, breed stat modifiers + signature
behaviors.

## 7. Phrase Loadout UI + Trade-off Model (from spec review)

- **Loadout/selection UI:** DECIDED (2026-06-19, task 099) — **both** spec-named
  selection paths now exist and neither competes with the timing tap: the bottom-left
  **loadout chip** (tap to cycle, already shipped) **and** **swipe the BRA marker** to
  swap (new). See §7q below.
- **Trade-off model:** DECIDED (2026-06-17, task 087) — see §7p below.

## 8. Tuning Targets — Audited Constant Table (iteration 11, 2026-06-14)

> **DONE (2026-06-20, task 105):** the difficulty mode constants and the app-level
> `PANT_INTERVAL_MS` / `TIMELINE_EVENTS` now live in **`src/core/tuning.ts`** as named
> primitive exports (`NORMAL_WINDOW_WIDTH_MS`, `HARD_FALSE_MARK_DELTA`, …); `difficulty.ts`
> and `main.ts` import them. `tuning.ts` imports nothing from `src/core/*` (no cycle).
>
> **DONE (2026-06-21, task 110):** the playtest-relevant stragglers a balance pass will
> touch are now homed in `tuning.ts` too — `NORMAL_DELTAS` (mark.ts), the engagement
> reward-latency feed + `MARK_ENGAGEMENT_DELTA` (engagement.ts), `CALL_BACK_ENGAGEMENT`
> (disengage.ts), `CONFUSE_WINDOW_MULT` / `CONFUSE_DISTRACTOR_MULT` (difficulty.ts), and
> `BASE_SCHEDULER_TIMING` (gameHelpers.ts). Each domain module imports them from
> `tuning.ts`, thinly re-exporting any name imported widely (e.g. `NORMAL_DELTAS` via
> `mark.ts`) so call-sites stayed stable. Pure, behavior-preserving move — all tests
> passed unchanged. `tuning.ts` still imports nothing from `src/core/*`; the few `Record`/
> `as const` tables it now holds write their key types inline to keep it import-free.
> A tuner edits one file. Remaining low-traffic tunables (kennel.ts, phrases.ts, …) can be
> folded in later the same way.

All values are placeholders authored during initial implementation and have not
been validated by playtest. The table is the single reference for future tuning.

### 7a. Mark Deltas (`src/core/mark.ts`, `src/core/difficulty.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| `NORMAL_DELTAS.PERFECT` | +8 | mark.ts | Learned-bar increase on a perfect tap | Baseline; HARD/EXPERT inherit this |
| `NORMAL_DELTAS.OK` | +3 | mark.ts | Learned-bar increase on an OK tap | |
| `NORMAL_DELTAS.MISS` | 0 | mark.ts | Bar change on a miss | No penalty; neutral |
| `NORMAL_DELTAS.FALSE_MARK` | −4 | mark.ts | Bar decrease on a false mark | HARD overrides to −8; EXPERT to −14 |
| HARD `FALSE_MARK` override | −8 | difficulty.ts | Bar penalty on false mark in HARD mode | 2× NORMAL |
| EXPERT `FALSE_MARK` override | −10 | difficulty.ts | Bar penalty on false mark in EXPERT mode | 2.5× NORMAL — **APPLIED §7n** |

### 7b. Confuse Debuff (`src/core/session.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| `CONFUSE_MS` | 3000 ms | session.ts | Duration the dog is "confused" after a false mark; taps during window do nothing | Refreshes (does not stack) |

### 7c. Scheduler (`src/core/scheduler.ts`, `src/core/difficulty.ts`, `src/main.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| `attemptInterval` | 2000 ms | main.ts | Gap between successive correct-attempt windows | Hardcoded in `buildSchedulerCfg()` |
| `activeSpan` | 800 ms | main.ts | How long the dog visibly holds the behavior | Hardcoded in `buildSchedulerCfg()` |
| NORMAL `windowWidth` | 400 ms | difficulty.ts | Scoring window (tap lands here → OK or PERFECT) | Centered within activeSpan |
| NORMAL `peakRadius` | 80 ms | difficulty.ts | Half-width of the PERFECT sub-band | |
| NORMAL `distractorRate` | 0.2 | difficulty.ts | Probability of a distractor between correct attempts | Gated to 0 until first mastery (onboarding) |
| HARD `windowWidth` | 280 ms | difficulty.ts | Tighter window than NORMAL 400 ms | −30% |
| HARD `peakRadius` | 50 ms | difficulty.ts | Tighter PERFECT band than NORMAL 80 ms | −37.5% |
| HARD `distractorRate` | 0.45 | difficulty.ts | Higher distractor chance than NORMAL 0.2 | +125% |
| EXPERT `windowWidth` | 160 ms | difficulty.ts | Tighter window than HARD 280 ms | −60% from NORMAL |
| EXPERT `peakRadius` | 25 ms | difficulty.ts | Tighter PERFECT band than HARD 50 ms | −69% from NORMAL |
| EXPERT `distractorRate` | 0.55 | difficulty.ts | Higher distractor chance than HARD 0.45 | +175% from NORMAL — **APPLIED §7n** |
| `TIMELINE_EVENTS` | 20 | main.ts | Events per segment before the timeline loops | Approximately 40 s per segment at 2 s interval |
| Untrain calm-gap minimum | 100 ms | scheduler.ts | Minimum gap duration to count as a markable calm window | Hard-coded inline |
| Untrain `peakRadius` (derived) | min(80, gapLen/4) ms | scheduler.ts | PERFECT sub-band for untrain attempts; adapts to gap width | |

### 7d. Difficulty Tell Intensity (`src/core/difficulty.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| NORMAL `tellIntensity` | 1.0 | difficulty.ts | Apex visual pulse strength (1 = clearest) | |
| HARD `tellIntensity` | 0.6 | difficulty.ts | Fainter pulse cue in HARD mode | −40% vs NORMAL |
| EXPERT `tellIntensity` | 0.3 | difficulty.ts | Faintest cue in EXPERT mode | −70% vs NORMAL |

### 7e. Reward Multipliers (`src/core/difficulty.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| NORMAL `rewardMultiplier` | 1.0 | difficulty.ts | Scales mastery coin + XP payout | Baseline |
| HARD `rewardMultiplier` | 1.3 | difficulty.ts | 30% bonus payout in HARD mode | **APPLIED §7n** |
| EXPERT `rewardMultiplier` | 2.5 | difficulty.ts | 150% bonus payout in EXPERT mode | |

### 7f. Tricks (`src/core/tricks.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| Sitt `learnMult` | 1.0 | tricks.ts | Positive delta multiplier (PERFECT/OK); 1 = baseline | Easiest trick |
| Sitt `windowMult` | 1.0 | tricks.ts | Scales windowWidth and peakRadius | No change from mode defaults |
| Sitt `distractorBonus` | 0.0 | tricks.ts | Added to distractorRate | No extra distractors |
| Ligg `learnMult` | 0.75 | tricks.ts | 25% slower bar fill than Sitt | Medium trick |
| Ligg `windowMult` | 0.8 | tricks.ts | 20% tighter window than Sitt | |
| Ligg `distractorBonus` | 0.1 | tricks.ts | +10 pp distractor rate | |
| Legg deg `learnMult` | 0.5 | tricks.ts | 50% slower bar fill than Sitt | Hardest starter trick |
| Legg deg `windowMult` | 0.6 | tricks.ts | 40% tighter window than Sitt | |
| Legg deg `distractorBonus` | 0.2 | tricks.ts | +20 pp distractor rate | |
| Ikke hopp `learnMult` | 0.8 | tricks.ts | Slower bar fill (untrain trick) | Medium-hard untraining trick |
| Ikke hopp `windowMult` | 0.9 | tricks.ts | 10% tighter calm-gap window | |
| Ikke hopp `distractorBonus` | 0.3 | tricks.ts | +30 pp bad-habit appearance rate | |

### 7g. Breeds (`src/core/breeds.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| Labrador `intrinsic` | 1.0 | breeds.ts | Difficulty multiplier applied via `composeDifficulty` | Neutral; starter breed (free) |
| Labrador `learnSpeed` | 1.0 | breeds.ts | Personality stat (informational for now) | |
| Labrador `distractibility` | 0.5 | breeds.ts | Personality stat | |
| Border Collie `intrinsic` | 1.5 | breeds.ts | Window ÷ 1.5, distractor rate × 1.5 vs baseline | Harder to train |
| Border Collie `learnSpeed` | 1.4 | breeds.ts | Personality stat | |
| Border Collie `distractibility` | 0.9 | breeds.ts | Personality stat | |
| Border Collie `adoptCost` | 200 coins | breeds.ts | Purchase price in the adopt shop | |
| Bulldog `intrinsic` | 1.3 | breeds.ts | Window ÷ 1.3, distractor rate × 1.3 vs baseline | Moderately harder |
| Bulldog `learnSpeed` | 0.7 | breeds.ts | Personality stat | |
| Bulldog `distractibility` | 0.3 | breeds.ts | Personality stat | |
| Bulldog `adoptCost` | 150 coins | breeds.ts | Purchase price in the adopt shop | |
| Husky `intrinsic` | 1.8 | breeds.ts | Window ÷ 1.8, distractor rate × 1.8 vs baseline | Most challenging breed |
| Husky `learnSpeed` | 1.1 | breeds.ts | Personality stat | |
| Husky `distractibility` | 0.95 | breeds.ts | Personality stat | |
| Husky `adoptCost` | 300 coins | breeds.ts | Purchase price in the adopt shop | |

### 7h. Economy (`src/core/economy.ts`, `src/core/game.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| `MASTERY_BASE_PAYOUT.coins` | 50 | game.ts | Base coin reward on mastering a trick | Scaled by difficulty × kennel × prestige |
| `MASTERY_BASE_PAYOUT.xp` | 30 | game.ts | Base XP reward on mastering a trick | Same scaling |
| `LEVEL_THRESHOLDS[1]` | 0 XP | economy.ts | XP to reach level 1 | Starting level |
| `LEVEL_THRESHOLDS[2]` | 100 XP | economy.ts | XP to reach level 2 | ~3–4 masteries at NORMAL |
| `LEVEL_THRESHOLDS[3]` | 300 XP | economy.ts | XP to reach level 3 | +200 XP from L2 |
| `LEVEL_THRESHOLDS[4]` | 600 XP | economy.ts | XP to reach level 4 | +300 XP from L3 |
| `LEVEL_THRESHOLDS[5]` | 1000 XP | economy.ts | XP to reach level 5 | +400 XP from L4; max defined level |

### 7i. Kennel (`src/core/kennel.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| Treats Pouch `cost` | 100 coins | kennel.ts | Price of the first kennel upgrade | |
| Treats Pouch `payoutMultiplier` | 1.2× | kennel.ts | Multiplies mastery payout while owned | +20% |
| Pro Clicker `cost` | 250 coins | kennel.ts | Price of second kennel upgrade | |
| Pro Clicker `payoutMultiplier` | 1.5× | kennel.ts | Multiplies mastery payout while owned | +50% |
| Training Dummy `cost` | 500 coins | kennel.ts | Price of third kennel upgrade | |
| Training Dummy `payoutMultiplier` | 2.0× | kennel.ts | Multiplies mastery payout while owned | +100% |
| `IDLE_RATE_PER_MS` | 0.001 coins/ms | kennel.ts | Coins earned per millisecond while idle (= 1 coin/second) | |
| `IDLE_CAP_COINS` | 110 coins | kennel.ts | Maximum coins claimable on return from idle | **APPLIED §7n** |

### 7j. Phrases (`src/core/phrases.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| BASE_PHRASE (`bra`) `windowBonusMs` | 0 ms | phrases.ts | Window expansion from using this phrase | Always available; no effect |
| BASE_PHRASE `rewardBonus` | 0.0 | phrases.ts | Additive reward fraction from using this phrase | |
| BASE_PHRASE `cooldownMs` | 0 ms | phrases.ts | Cooldown before phrase can fire again | No cooldown |
| FLINK_PHRASE `windowBonusMs` | 150 ms | phrases.ts | Scoring window expansion (±150 ms) | |
| FLINK_PHRASE `rewardBonus` | 0.1 | phrases.ts | +10% additive to reward | |
| FLINK_PHRASE `cooldownMs` | 8000 ms | phrases.ts | 8 s cooldown between uses | |
| FLINK_PHRASE `unlockCost` | 50 coins | phrases.ts | Shop price to unlock | |
| FLINK_PHRASE `unlockLevel` | 1 | phrases.ts | Minimum player level required | Available from level 1 |
| SUPER_PHRASE `windowBonusMs` | 250 ms | phrases.ts | ±250 ms window expansion | |
| SUPER_PHRASE `rewardBonus` | 0.2 | phrases.ts | +20% additive to reward | |
| SUPER_PHRASE `cooldownMs` | 12000 ms | phrases.ts | 12 s cooldown between uses | |
| SUPER_PHRASE `unlockCost` | 275 coins | phrases.ts | Shop price to unlock | **APPLIED §7n** |
| SUPER_PHRASE `unlockLevel` | 3 | phrases.ts | Requires player level 3 | Locks until 300 XP |

### 7p. Phrase Trade-off Model — DECIDED (2026-06-17, task 087)

**Model:** each phrase's `peakRadiusPenaltyMs` shrinks the PERFECT band
(`peakRadius`) when `applyPhraseToAttempt` is called, clamped to a positive
floor (`PEAK_RADIUS_FLOOR_MS = 20 ms`) so PERFECT stays achievable.

```
peakRadius_effective = max(20, attempt.peakRadius − phrase.peakRadiusPenaltyMs)
```

The outer scoring window (`windowBonusMs`) is unchanged — stronger phrases still
widen it. The downside is exclusively in the PERFECT sub-band: a bigger reward
multiplier demands tighter peak timing (*precision-for-payout*). `BASE_PHRASE`
(`bra`) keeps `peakRadiusPenaltyMs: 0` and is never penalised.

**Per-phrase values (all tunable):**

| Phrase | `peakRadiusPenaltyMs` | Rationale |
|--------|-----------------------|-----------|
| bra (base) | 0 | Neutral default; always available, no penalty |
| flink | 0 | Onboarding-gentle; first purchase should feel like a win |
| dyktig | 25 | Small penalty; noticeable but not punishing |
| super | 40 | Medium penalty; genuine skill check for the +20% reward |
| kjempebra | 65 | Largest penalty; +30% reward requires near-floor precision at NORMAL peakRadius |

At NORMAL `peakRadius = 80 ms`: kjempebra leaves `max(20, 80-65) = 20 ms` — still
hittable but very tight. At HARD `peakRadius = 50 ms`: kjempebra leaves
`max(20, 50-65) = 20 ms`. At EXPERT `peakRadius = 25 ms`: kjempebra leaves
`max(20, 25-65) = 20 ms` (floor). The floor ensures PERFECT is never locked out.

Resolves the open "trade-off model" design item in §7. Values are conservative
placeholders — adjust after playtesting.

### 7q. Phrase Swipe-to-Swap on the BRA Marker — DECIDED (2026-06-19, task 099)

Implements the spec's second named phrase-selection gesture (specs §Marker Phrases:
"swapped by swiping the BRA marker itself; the round is still one tap"). Closes the
open "loadout/selection UI" item in §7.

**Pure core (`src/core/swipeGesture.ts`, TDD, 10 tests):**
- `classifySwipe(dx, dy, threshold = 40px)` → `{type:'tap'}` unless the press travels
  **≥ threshold horizontally AND horizontal travel dominates vertical**, then
  `{type:'swipe', dir}` (swipe-left = `next`, swipe-right = `prev`). A wobble or a
  vertical drag stays a tap, so the timing mark is never lost to an accidental swipe.
- `cycleIndex(current, length, dir)` — wrap-around index step; no-op for length ≤ 1.

**The timing tradeoff (the one real risk, and its resolution):** the BRA marker is now
**press-then-release**. `pointerdown` records the press instant (`onBraTapDown` →
`pendingDownAt`); the mark **commits on `pointerup`/`pointercancel`** — but only if the
gesture was a tap. A swipe calls `onSwapPhrase(dir)` and **suppresses the mark** (so a
deliberate phrase-swap never fires a stray FALSE_MARK + confuse). Crucially, scoring uses
the recorded **pointerdown** instant, not release, so swipe support adds **zero latency**
to the timing tap. The e2e BRA taps were updated to dispatch `pointerdown`+`pointerup`
(a zero-movement down→up = tap); full-loop still plays to mastery via apex-timed taps —
that green run is the scoring-precision regression guard. `setPointerCapture` is
try/guarded (synthetic events have no active pointer).

**Visual (Visual Review: PASS after one fix round):** a faint "‹ swipe ›" hint appears
under the marker only when `available.length > 1` (more than base "bra"); a swap flashes
the new phrase word in gold above the marker, sliding in the swipe direction, with a brief
button nudge. `prefers-reduced-motion` → cross-fade, no slide/nudge (D13). Round-1 review
flagged the hint cramped against the bottom gesture zone and the swap word too close /
low-contrast; fixed by lifting `#hud-bottom` padding (40px + safe-area, loadout-chip calc
kept in sync), raising the swap word with a dark halo + richer gold. New dev/screenshot
hook `__forcePhrases()` + a `--eval` flag on `scripts/shoot.mjs`.

### 7k. Combo (`src/core/combo.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| Combo increment formula | +1 per PERFECT/OK; 0 on MISS/FALSE | combo.ts | Combo counter per-tap | Resets on any non-hit |
| Combo multiplier formula | min(2, 1 + 0.1 × max(0, combo−1)) | combo.ts | Multiplier applied to positive learned-bar deltas | Caps at 2.0× |
| Combo cap (effective) | 2.0× at combo 11+ | combo.ts | Maximum combo bonus to learned-bar fill | Reached at combo count = 11 |

### 7l. Prestige (`src/core/prestige.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| `PRESTIGE_PER_GRADUATION` | 1 point | prestige.ts | Prestige points earned per dog graduation | |
| `prestigeMultiplier` formula | min(2.5, 1 + points × 0.1) | prestige.ts | Multiplies mastery payout coins and XP | Capped at 2.5× (15 prestige points) — **APPLIED §7n** |

### 7m. Onboarding Thresholds (`src/core/onboarding.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| Distractors revealed at | ≥1 mastered trick | onboarding.ts | When distractors appear in sessions | Also gates economy reveal |
| Economy revealed at | ≥1 mastered trick | onboarding.ts | When coin/XP display appears | Same threshold as distractors |
| Phrases revealed at | ≥2 mastered tricks | onboarding.ts | When phrase chip appears in HUD | |
| Kennel revealed at | ≥3 mastered tricks | onboarding.ts | When kennel shop becomes visible | |
| Difficulty revealed at | ≥3 mastered tricks | onboarding.ts | When difficulty selector appears | Same threshold as kennel |
| Untraining tricks revealed at | Never (v1) | onboarding.ts | When untrain tricks appear in trick-select | Controlled by `untrainTricksUnlocked()` predicate; always returns `false` for v1 |

### 7m-untrain. Untraining Gate — DECIDED (2026-06-17)

**Untraining is gated off for v1** per specs.md (post-v1 later addition, onboarding depth). The v1 build never surfaces untrain tricks in the trick-select, preventing onboarding confusion on a fresh player who sees "Ikke hopp" with no context.

- **Gate location:** `src/core/onboarding.ts`, `untrainTricksUnlocked(masteredCount: number)` — a pure, tested predicate.
- **Current behavior:** always returns `false` (v1: never unlock).
- **Post-v1 unlock condition:** when untraining is formally introduced, flip the condition in `untrainTricksUnlocked()` to a real threshold (e.g. `masteredCount >= N` or a flag from a deeper onboarding stage). This is a one-line, tested change.
- **Untrain mechanic code (dormant):** `untrainAttemptAt`, misbehaving visual state, scheduler untrain constants remain in the codebase (not deleted) — they are the post-v1 implementation, just not surfaced. No behavioral impact on v1 play.
- **Wire point:** `src/main.ts`, `getTricks()` — queries the gate before appending `UNTRAIN_TRICKS` to the trick list.

---

### 7n. Balance Sanity-Check (2026-06-14 audit — findings only, no code changes)

#### Mastery Reachability

With PERFECT delta = +8 and bar range 0–100, a player needs **13 perfect taps** to
reach 100 (13 × 8 = 104, capped at 100). A combo multiplier can halve this further.
At an attempt interval of 2 s, 13 perfect taps take under 30 seconds of wall time —
provided every tap is perfect. In practice (mix of OK and MISS) with NORMAL Sitt
(learnMult = 1), a realistic session converges to around 30–60 s, which is
**reasonable for a short-session mobile game**.

For Legg deg on EXPERT, however: EXPERT PERFECT delta = 8 × learnMult 0.5 = 4,
window 160 × 0.6 = 96 ms with peakRadius 25 × 0.6 = 15 ms. Reaching 100 requires
25 perfect taps in a 96 ms window (a 15 ms PERFECT band). That is near-frame-perfect
timing. **Flagged: Legg deg + EXPERT stacks two penalties (learnMult 0.5 × harder
window) without a corresponding reward multiplier bonus for the trick itself, making
this combination extremely grindy.**

#### Economy Progression vs Costs

Mastery payout at NORMAL, no upgrades, no prestige: 50 coins, 30 XP.

Kennel costs: 100, 250, 500 (total 850 coins). To buy all three, at 50 coins/mastery,
a player needs **17 masteries** (3–4 tricks × repeatable via prestige). Across 4
tricks this is roughly 4–5 graduation cycles. This is on the **grindy side** for a
mobile casual game; the Treats Pouch at 100 coins (2 masteries) is accessible, but
the Training Dummy at 500 (10 masteries) may feel very far away without HARD/EXPERT
play.

Adopt costs (200, 150, 300) are reachable in 4–6 masteries each at NORMAL. The Husky
at 300 coins is attainable in under a dozen sessions — reasonable.

Phrase costs (50, 150) are fast. FLINK at 50 coins = 1 mastery; SUPER at 150 = 3.
**These are very cheap and will be unlocked within the first two play sessions —
consider raising SUPER to 250–300 if the level-3 gate is meant to be a meaningful
filter.**

Level thresholds vs mastery XP (30 base at NORMAL): level 2 at 100 XP = ~3–4
masteries; level 3 at 300 XP = ~10 total. The SUPER phrase gate (level 3 + 150 coins)
is the most significant checkpoint, but 10 masteries is reachable in a couple of
sessions. **The level table only defines 5 levels (up to 1000 XP = ~33 NORMAL
masteries); there is no defined content beyond level 5.** Flag as a gap.

#### Difficulty EV (Expected Value Analysis)

At NORMAL (no false marks): perfect 13 taps → 50 coins.
At HARD (FALSE_MARK −8, distractors 45%, window 280 ms, mult 1.5×):
  Payout if mastered: 50 × 1.5 = 75 coins.
  Cost: tighter window + more distractors increase false-mark exposure.
  EV is positive for skilled players: the 50% payout premium more than offsets the
  penalty risk for a player landing PERFECT most of the time.

At EXPERT (FALSE_MARK −14, distractors 70%, window 160 ms, mult 2.5×):
  Payout if mastered: 50 × 2.5 = 125 coins.
  Cost: a single false mark sets the bar back 14 points (nearly two perfects). With
  70% distractor rate, false marks are frequent. A player who cannot maintain near-
  perfect accuracy on a 160 ms window will regress indefinitely. **Flagged: EXPERT
  may be EV-negative for average players — not "harder but worth it" but just
  punishing. Recommend softening EXPERT FALSE_MARK to −10 (from −14) and/or
  reducing distractorRate to 0.55 (from 0.7) as starting points.**

HARD remains the most EV-positive difficulty for the majority of players (big reward
with a manageable penalty). NORMAL and EXPERT could end up dominated: NORMAL because
HARD is strictly better for any competent player; EXPERT because the EV goes negative
for all but the most precise players. **Recommendation: tighten HARD's reward to
1.3× and relax EXPERT's false-mark penalty to −10 so there is a smooth skill
gradient rather than a cliff.**

#### Idle Cap vs Typical Session Payout

Idle rate: 1 coin/second. Idle cap: 200 coins.
Cap reached after 200 seconds (3 min 20 s) of idle time.
Typical active session at NORMAL: ~50 coins per mastery; a 10-minute session might
yield 2–3 masteries = 100–150 coins.
**The idle cap (200) slightly exceeds one medium active session (100–150 coins),
which risks making idle income feel competitive with active play, undermining the
"nudge not replacement" goal. Recommend lowering IDLE_CAP_COINS to 100–120.**

#### Combo / Prestige Runaway Check

Combo: capped at 2.0× (reached at combo count 11). No runaway risk.

Prestige: `1 + points × 0.1` — linear, **unbounded**. At 10 prestige points the
multiplier is 2.0×; at 20 points it is 3.0×; at 50 it is 6.0×. Because graduation
costs remastering all 3 STARTER_TRICKS per dog, each prestige point requires
substantial work, but the multiplier will eventually trivialize all content.
**Recommendation: cap `prestigeMultiplier` at 2.5× (25 prestige points) or switch
to a diminishing-returns formula such as `1 + log(1 + points) × 0.5`.**

#### Summary of Recommended Number Changes (iteration 11 audit; 6 of 7 APPLIED in iteration 12)

| Item | Old | New | Reason | Status |
|---|---|---|---|---|
| EXPERT `FALSE_MARK` delta | −14 | −10 | EV goes negative; too punishing vs reward | **APPLIED** |
| EXPERT `distractorRate` | 0.7 | 0.55 | Combined with tight window makes mastery near-impossible for average players | **APPLIED** |
| HARD `rewardMultiplier` | 1.5× | 1.3× | HARD currently dominates NORMAL in EV; gap should be smaller | **APPLIED** |
| `IDLE_CAP_COINS` | 200 | 110 | Cap exceeds a medium active session; undermines "nudge not replacement" | **APPLIED** |
| SUPER phrase `unlockCost` | 150 | 275 | Unlocked too quickly; level-3 gate loses meaning | **APPLIED** |
| `prestigeMultiplier` | unbounded linear | cap at 2.5× | Unbounded growth trivializes late content | **APPLIED** |
| Legg deg on EXPERT | (stacked penalty) | `trickRewardMultiplier` uplift folds into difficulty-mult term; legg-deg earns ~1.7× sitt at same mode/kennel/prestige | Hard tricks now pay proportionally more — no longer strictly dominated | **RESOLVED** (2026-06-18) |

**Per-trick reward uplift — APPLIED (2026-06-18):** `trickRewardMultiplier(trick)` in `src/core/tricks.ts` derives a reward multiplier from the trick's existing `learnMult`/`windowMult` penalties — no per-trick hand-tuned field, so retuning a trick's difficulty keeps its pay consistent automatically. Formula: `min(REWARD_UPLIFT_CAP, 1 + (1 − learnMult) + (1 − windowMult) × 0.5)`. `REWARD_UPLIFT_CAP = 2.2`. Sitt (learnMult=1, windowMult=1) → 1.0× (unchanged). Legg deg (learnMult=0.5, windowMult=0.6) → 1.0 + 0.5 + 0.2 = 1.7×. Synthetic worst-case (learnMult=0, windowMult=0) → clamped to 2.2×. This uplift folds into the difficulty-mult term; the documented payout order (`base × trickMult × modeMult × kennelMult × prestige`) is unchanged. Both `completeMastery` and `completePractice` accept an optional `trick?: Trick` param (backward-compatible: omitting it defaults to 1×). The `main.ts` call sites pass `activeTrick` so every mastery/re-practice event uses the correct uplift.

## 10. Level-Gated Unlock Ladder (Placeholder Tuning) — DECIDED

Two-step gate: **level makes content purchasable; coins purchase it** (specs.md §Economy & Progression).
`isTierUnlocked(level, requiredLevel)` is the single primitive for both phrases and breeds.

### Phrase `unlockLevel` (in `PHRASE_CATALOG`)

| Phrase | `unlockLevel` | `unlockCost` |
|--------|--------------|--------------|
| bra (base) | 1 | 0 (free) |
| flink | 1 | 50 |
| dyktig | 2 | 175 |
| super | 3 | 275 |
| kjempebra | 4 | 450 |

### Breed `requiredLevel` (in `BREED_CATALOG`)

| Breed | `requiredLevel` | `adoptCost` |
|-------|----------------|-------------|
| Labrador (starter) | 1 | 0 (given) |
| Bulldog | 2 | 150 |
| Border Collie | 3 | 200 |
| Puddel | 4 | 225 |
| Husky | 5 | 300 |

### Gate legibility — adopt panel mirrors phrase loadout (2026-06-17, task 072)

For the two-step model to *read* as designed, the player must see **which** gate
blocks them. The phrase loadout already distinguishes this via
`getLoadoutState().nextLockedIsLevelGated` (shows `Lvl N` instead of a coin price).
The adopt panel now mirrors it: `getAdoptableBreeds()` returns a display-only
`levelGated` flag (`isBreedLevelLocked(breed, level)` = `!isTierUnlocked(...)`), and a
level-locked breed renders a `Lvl N` badge + `level-locked` class + "reach level N to
unlock" aria-label instead of the coin-shortage styling. `canAdopt` stays the single
authoritative purchase gate; `levelGated` never relaxes it. This prevents a low-level
player from grinding coins pointlessly for a breed they cannot yet adopt.

## Re-Practice Payout — DECIDED (2026-06-17)

**`PRACTICE_BASE_PAYOUT = { coins: 15, xp: 0 }`** (vs `MASTERY_BASE_PAYOUT = { coins: 50, xp: 30 }`).

When a round completes on a trick the active dog had **already mastered** before the round started, `completePractice` is called instead of `completeMastery`. The same difficulty × kennel × prestige multiplier stack applies to whichever base is used.

**No XP on re-practice.** XP is the skill-gated progression currency (specs.md §Economy); granting it on re-practice would let players farm levels by grinding easy known tricks, bypassing the two-step unlock (task 069). The reduced coin payout serves as the **anti-softlock income floor** (specs.md:108–109): even when nothing new is affordable, a player can always re-practice for coins.

The `wasAlreadyMastered` flag is captured in `onSelectTrick` (before `startFreshRound` / `recordMastery` fires) so the branch at the mastery edge reads the pre-round state.

These are placeholder values for v1 — the progression feel should be validated in playtesting and adjusted via the tuning table above.

## Mark SFX — Layered Click + Clip-Fallback Policy — DECIDED (2026-06-17, task 074)

**The mark sound is two layers: a short square-wave click transient + a sine praise tone.**

Click envelope (shared across PERFECT and OK):
- `freq: 2000 Hz`, `type: 'square'`, `durationMs: 12`, `gain: 0.35`
- MISS uses the same click at `gain: 0.12` (subtle; no praise tone).
- FALSE_MARK bypasses the click entirely: `freq: 180 Hz`, `type: 'sawtooth'`, `durationMs: 90`, `gain: 0.5` — the existing low negative buzz character is preserved.

Praise tone gains (layered after the click):
- PERFECT: `gain: 0.9`, `freq: 880 Hz`, `durationMs: 140`
- OK: `gain: 0.5`, `freq: 660 Hz`, `durationMs: 120`

**Clip-fallback policy:** `MarkAudio.registerClip(cue, buffer)` registers an `AudioBuffer` keyed by result string (e.g. `'PERFECT'`). `play(result)` checks `shouldUseClip(result, clips)` — if a buffer is registered for that exact cue it plays via `playBuffer` (a thin `BufferSourceNode → GainNode → destination` chain); otherwise it synthesizes the layered `SoundSpec[]` from `markLayers()`. This makes the engine voice-ready: drop in a clip and the synth fallback is bypassed automatically, with no call-site changes.

**Voice sourcing remains the open §4 decision.** The intended clip is a Maren-style Norwegian "bra!" marker voice. Its sourcing — recorded original / licensed / TTS — carries likeness/legal weight and is not decided here. The `registerClip` path is the future hook for that asset.

## Dog Foley + Ambient Bed — DECIDED (2026-06-17, task 094)

**Three synthesised dog foley events** layered into the existing lazy/mute-aware audio path, plus an enriched ambient bed. All gains sit well under the PERFECT praise tone (gain 0.9) and play sequentially (same cursor-advance pattern as `masterySound`).

### Foley events

| Event | Layers | freq (Hz) | durationMs | type | gain |
|-------|--------|-----------|-----------|------|------|
| `idle-pant` | puff-in | 300 | 70 | sine | 0.04 |
| | puff-out | 340 | 60 | sine | 0.03 |
| `mastery-bark` | syllable 1 | 520 | 90 | triangle | 0.22 |
| | syllable 2 | 430 | 110 | triangle | 0.18 |
| `false-huff` | huff | 170 | 70 | sine | 0.12 |

All gains are well under the PERFECT praise tone (0.9) — foley never masks the mark SFX.

### Trigger edges

- **mastery-bark**: layered immediately after the mastery jingle (`markAudio.playMastery()`) on the mastery false→true edge in `tick()`.
- **false-huff**: played in `onBraTap` right after `markAudio.play(result)` when `result === 'FALSE_MARK'`.
- **idle-pant**: throttled to `PANT_INTERVAL_MS = 7000` ms and gated to `dogVisualState(state, now, ...) === 'idle'`. Evaluated in the normal training path of `tick()` (after the confuse-edge block, before `renderTraining`). Does not run in the early-return mastery branch.

### Enriched ambient bed

Three partials replace the single 160 Hz drone:

| freq (Hz) | durationMs | type | gain |
|-----------|-----------|------|------|
| 160 | 0 (looping) | sine | 0.04 |
| 163 | 0 (looping) | sine | 0.03 |
| 240 | 0 (looping) | triangle | 0.025 |

The 163 Hz partial gives a ~3 Hz beat shimmer against the 160 Hz root; the 240 Hz triangle adds a soft fifth for body. Sum of gains = 0.095, well under 0.12. Still lazy + mute-aware: `startAmbient` loops over `ambientLayers()` creating one oscillator per partial; `stopAmbient` stops every oscillator in `_ambientOscs` and resets the array. `ambientSpec()` delegates to `ambientLayers()[0]` for back-compat.

**Not aurally verifiable headless — a human on-device listen is the remaining verification (precedent: task 074).**

## Mobile Resume Grace — DECIDED (2026-06-17, task 073)

**`RESUME_GRACE_MS = 400`** (`src/core/resumeGrace.ts`).

Spec (specs.md §Mistakes → Mobile grace) requires that taps in the brief moment
after the app resumes from background are ignored, so a notification, lock, or
fat-finger never triggers a false mark / confuse. `main.ts` stamps `resumedAt =
performance.now()` on every `visibilitychange → visible`, and `onBraTap` returns
silently (no classify / applyMark / audio / scene notify) when
`isWithinResumeGrace(now, resumedAt, RESUME_GRACE_MS)`.

**Why 400 ms:** long enough to swallow the stray tap that dismisses a notification
or wakes the screen, short enough to be invisible in normal play (well below a
deliberate reaction tap, ~250–500 ms). The window is **half-open** — a tap exactly
400 ms after resume is allowed — and `resumedAt` starts at `-Infinity` so the first
taps of a fresh session are never eaten. Placeholder value; a one-line tuning knob.

We deliberately do **not** pause the round timeline on background: the loop time base
is `performance.now()` and the scheduler loops, so swallowing the resume tap (what the
spec mandates) is sufficient. Timeline pause is out of scope. **(Superseded by the
In-Round Pause Clock below — task 106 now adds explicit pause/resume, including an
auto-pause on background.)**

## In-Round Pause Clock — DECIDED (2026-06-21, task 106)

Spec (specs.md §Round States: *"Pause/resume supported; no timer forces play."*) is a
listed v1 behavior that had no implementation. Added a **pure pause clock**
(`src/core/pauseClock.ts`): `createPauseClock(startNow)` → `{ isPaused, pause(now),
resume(now), elapsed(now) }`.

**Model — "effective time".** Round time is `now − startNow − lostMs`, where `lostMs`
accumulates every paused span; while paused, `now` is clamped to the pause instant so
`elapsed` freezes. The **timeline lives in this effective frame** and *every* round-time
read in `main.ts` goes through it (`effNow(now) = pauseClock.elapsed(now)`): the rAF
`tick` (timeline loop, confuse expiry, view model, dog pose), and `onBraTapCommit`
(`attemptAt` / `classifyMark` / `applyMark` / `rewardLatencyMs` / scene `notifyMark`).
Because `tick` early-returns while paused, the dog holds, the apex tell stops advancing,
and the timeline never loops. A resumed round therefore **continues exactly where it
left off** — no skip-ahead by the paused wall-clock span. One clock for the session:
each round re-bases `timelineOffset = effNow(now)` at start, so carrying `lostMs` across
rounds is harmless (the offset cancels it).

**Why pure + time-injected:** the no-skip-ahead math is fully unit-tested without
Babylon/DOM (8 tests: advances normally, frozen-while-paused, resume-continues,
multi-cycle accumulation, double-pause/double-resume idempotence). The button + overlay
are thin glue in `hud.ts` (`setPaused` on the handle, `onTogglePause` callback).

**Frames kept separate on purpose.** Phrase cooldown stays in **wall clock** (it is a
UI affordance the HUD compares against `performance.now()`), so `onBraTapCommit` scores
the timeline in effective time (`tnow`) but stamps/reads `lastUsedAt` in wall time
(`downAt`). The dev-only `__bra.nextPeak()` hook now converts the (effective-frame)
timeline peaks back to wall clock by adding `lostMs` (0 when never paused, so the
full-loop e2e — which never pauses — is unchanged).

**Auto-pause on background.** `visibilitychange → hidden` during training auto-pauses
(the round never runs without the player); resume is **manual** via the overlay. On
manual resume we reuse the resume-grace window (`resumedAt = now`, D073) to swallow a
stray tap landing on the resume frame. This replaces the "timeline pause out of scope"
stance noted in Mobile Resume Grace above.

**UI.** A 44px ⏸ pause button sits top-left of the training HUD; the difficulty selector
shifts right (`left: 68px`) to clear it. The paused overlay is an opaque dimmed scrim
(`rgba(6,12,9,0.88)` + 2px blur) with a "Paused" label and a big yellow "▶ Resume"
pill; `prefers-reduced-motion` drops the fade-in. Visual-Reviewed by an independent
agent on a 390×844 portrait viewport (PASS; review nits — uniform dim, 44px tap target,
glyph contrast — applied).

## Engagement Meter + Disengage Beats — COMPLETE (098 + 107 + 112; 2026-06-19 → 2026-06-21)
<!-- 098 shipped the pure model + HUD meter; 100 wired reward-latency; 107 added the on-dog
     walk-off + call-back; 112 added the intermediate itch/flop/bark beats on the dog (both
     procedural, no clips). 098 is fully closed. See the three sub-sections below. -->


Spec (specs.md §Mistakes → *Wrong-behavior beats & disengagement*) calls for an
engagement meter that drains on sloppy/false marks or slow rewards and refills on good
timing, with the dog's offered wrong-behaviors escalating as it empties. Task 098
**depends on 079** (real Labrador clips) for the on-dog expression, so this iteration
shipped the **unblocked layer**: the pure model + a visible HUD meter. The dog-behavior
beats + walk-away/call-back remain 079-gated.

**Pure model (`src/core/engagement.ts`):**
- `engagement(prev, event)` — clamped 0..1. Mark deltas mirror the learned-bar
  sign/severity but at meter scale: **PERFECT +0.15, OK +0.08, MISS −0.06,
  FALSE_MARK −0.2**. Reward-latency event ramps linearly: **≤800 ms → +0.05**
  (snappy keeps the dog eager) down to **≥2400 ms → −0.15** (slow bores it).
- `disengageBeat(level)` → `engaged / itch / flop / bark / walk-off` at thresholds
  **0.75 / 0.5 / 0.25 / 0** (monotonic; spec escalation order itch→…→walk-off).
- **Not persisted** — like `combo`, it's a transient session feel; every fresh round
  starts at `ENGAGEMENT_FULL` (1) so a returning player meets an eager dog. Only
  mark-quality is wired live so far; the reward-latency event is implemented + tested
  but not yet fed from the loop (deferred with the rest of the 079 wiring).

**HUD reflection (DOM layer, no Labrador needed):** a top-right "mood" pill stacked
under coins/level. Chosen because the spec frames the meter's *visibility* through the
dog, which needs 079's clips — a small DOM meter surfaces the live value now and is
fully phone-portrait reviewable. Revealed at the economy stage (with stats).

### Reward-latency feed wired live — DONE (2026-06-19, task 100)

098 listed *"wire the reward-latency event live"* under its **079-gated** remainder. That
bundling was **over-broad**: the `{ kind:'reward', latencyMs }` event needs only the
active attempt's apex (`attempt.peak`) and the tap instant — pure timing, **no Labrador
clips**. Task 100 carves it out and wires it. New pure `rewardLatencyMs(tapTime,
apexTime)` (= `max(0, tapTime − apexTime)`; clamped so a pre-apex tap is "instant", not
negative) in `engagement.ts`. In `main.ts` `onBraTap`, after the `mark` event, a
**PERFECT/OK** mark (a real reward) also fires `engagement(…, { kind:'reward',
latencyMs })`. MISS/FALSE_MARK do **not** fire it — they are not rewards and their drain
is already applied by the `mark` event (no double-count). So the spec's "slow rewards
drain it" half is now live on the HUD mood meter: a correct-but-slow mark nets less
engagement than a snappy one. Still transient (resets to `ENGAGEMENT_FULL` per round).
The **on-dog** beats are now fully expressed too: walk-off + call-back (task 107) and the
intermediate itch/flop/bark beats (task 112) — both **procedural, no clips** — so the
"079-gated" deferral is fully retired and **098 is closed** (see the two sub-sections below).

**HUD chrome consistency change (deliberate):** stacking the meter under the stats pill
exposed that `#hud-stats` was the *only* HUD element docked **flush to the screen edge
with a square outer corner** (`border-radius: 0 0 0 12px`); every other chrome element
(diff-selector / kennel / loadout / combo) **floats inset 12–16px with full rounding**.
Visual Review flagged the docked look as "sheared/broken," so both stats + meter now sit
in a `#hud-stats-cluster` that floats inset (`margin-right: 14px`) with `border-radius:
12px` and shares one width (`align-items: stretch` + `min-width`), with coins/level
spread via `justify-content: space-between`. Net: stats moved from edge-docked to
floating-inset to match the rest of the HUD.

### On-dog walk-off + call-back — DONE (2026-06-21, task 107); completes the 098 remainder

098's deferred remainder (the **on-dog disengage beats / walk-away + call-back**) was
parked as **"079-gated"** — needing the licensed-Labrador clips. That deferral was
**over-broad**: the licensed dog is DEV-only (flag OFF, packaging-gated — §3i/§3j); the
**procedural primitive dog is what ships**, and the walk-off + call-back express
**procedurally** on it exactly like the existing turned-away `distractor` state. So 107
closes the remainder with **no clips** and gives the engagement meter real gameplay teeth.

**Pure logic (`src/core/disengage.ts`, TDD):**
- `isDisengaged(beat)` = `beat === 'walk-off'` — the dog has left only at the empty meter.
- `canScoreMark(beat)` = `beat !== 'walk-off'` — no marks score while walked off.
- `callBackEngagement(prev)` → **0.5** (clamped 0..1). `disengageBeat(0.5)` = `itch` —
  comfortably above walk-off **and** the adjacent `bark` band, so a single subsequent bad
  mark can't bounce the dog straight back off (anti-oscillation; tested through the beat).

**State + render (`dogState.ts` / `dogPose.ts` / `scene.ts`):**
- New `DogVisual` `'disengaged'`, selected when `opts.disengaged` (walk-off). Precedence:
  `mastered (happy)` > `disengaged` > `confused` > `offering` > `distractor` > `idle` — a
  won round still wins; otherwise a walked-off dog isn't "offering/confused/distracted".
- `disengaged` pose: **back-turned** `bodyYaw = −π/2`, **seated** `crouchY = −0.34`, head
  dropped `headPitch = −0.25`, near-still tail. The yaw is **−90°, not 180°**: the
  `ArcRotateCamera` sits at `alpha = −π/2` (looking along +Z), so a 180° yaw only shows the
  *other flank* — a −90° yaw turns the **rump toward the trainer** (a true back-turn) AND
  narrows the on-screen footprint so the dog can sit at the frame edge **without clipping**.
- `scene.ts`: a **cool blue** tint `(0.34, 0.41, 0.6)` (deliberately bluer than the neutral
  `distractor` grey so the two never collide), `scale 0.82` (withdrawn/farther), and a
  lateral edge offset `x = 0.6` (`DISENGAGED_EDGE_X`) — "trotted off to the side".
- Static reads (yaw/crouch/pitch/tint/position) survive `prefers-reduced-motion`; only the
  breathing/tail sway scales with `m` (D13 — dampened, not removed).
- Imported-dog clip map (`dogAnimationMap.ts`, task 080) gains a `disengaged` preference
  (`Sitting_loop_1` → … → `Idle_1`); the back-turn rides on yaw, not the clip.

**Tap routing (`main.ts`):** in `onBraTapCommit`, **before** mark classification (and
after the paused + resume-grace gates), `if (isDisengaged(disengageBeat(engagementMeter)))`
→ `engagementMeter = callBackEngagement(...)`, `combo = 0` (the tempo cost), play a soft
`playTap()` ack, and `return` — so a call-back **never scores nor false-marks**. The render
loop threads `disengaged` into `updateDog` + the idle-pant gate so a walked-off dog reads
disengaged (not idle), and `toViewModel` exposes a `disengaged` flag.

**Apex-tell suppression while disengaged (2026-06-21, task 118; PO Review #4).** The tap is
gated above, but the *cue* was not: `toViewModel` computed `tellStrength` (gold BRA ring) and
`peakProximity` (on-dog apex crest) purely from the attempt geometry, so a peak overlapping a
walked-off moment still pulsed "mark now" — directly contradicting the call-back affordance
(two opposite meanings on one cue). Fix: after deriving `disengaged`, `toViewModel` clamps
**both** `tellStrength` and `peakProximity` to `0` while disengaged. Engagement-scoped (an
engaged dog at the peak is untouched) and a single source of truth — because the on-dog apex
shares `peakProximity`, the mesh crest is suppressed for free. Pure logic, TDD
(`viewModel.test.ts`); no `hud.ts` change (the ring opacity already tracks `tellStrength`).

**HUD (`hud.ts` / `hud.css`):** a faint blue `#hud-callback-hint` pill ("Hunden gikk —
trykk for å kalle den tilbake") shows only while `vm.disengaged`, mirroring the swipe/coach
hint pattern. While disengaged the first-run **coach is suppressed** (`.coach-suppressed`,
orthogonal to `setCoachVisible`'s `.hud-gated`) so the two prompts never contradict
("trykk BRA" vs "kalle tilbake"); it returns automatically on call-back.

**Visual Review (blocking):** real phone-portrait screenshots via
`scripts/shoot-disengage.mjs` (engaged / walk-off / called-back / walk-off-reduced).
Round 1 (independent agent) = **FAIL** — the dog read as the idle pose recolored: not
back-turned (180° yaw showed the same flank), barely seated, centered, grey-not-blue.
Fixed (−90° yaw rump-to-camera, deeper crouch + head-down, bluer tint, edge offset enabled
by the narrow footprint). Round 2 (fresh independent agent) = **PASS WITH NITS** (the
uniform-crouch "sit" reads as a low crouch rather than a haunches-down sit — the primitive
dog has no per-leg control, so a uniform `crouchY` is the available approximation; nit, not
blocking). **specs.md untouched** (read-only for the build loop).

### Intermediate disengage beats on the dog — DONE (2026-06-21, task 112); closes 098

107 expressed only the **empty-meter walk-off** on the dog; the meter's intermediate
escalation (`itch → flop → bark`) drove the **HUD pill** but left the *dog* unchanged until
it suddenly trotted off. The dog is the game's primary state channel (spec §The Dog), so the
runup must read **off the dog**. 112 expresses the three intermediate beats procedurally (no
licensed clips), which was **098's last remaining slice** — so 098 is now closed.

**Routing (`dogState.ts`, pure, TDD — 10 new tests):** `DogVisual` gains `'itch' | 'flop' |
'bark'`; `DogVisualOpts.beat?: DisengageBeat`. The beats **replace the plain `idle` state
during lulls only** — they never mask an active correct `offering` (the player must always be
able to read the markable behavior), and yield to the existing precedence
(`mastered > disengaged(walk-off) > confused > offering > distractor > beat > idle`).
`engaged` (or absent) stays idle. The empty-meter `walk-off` is still the `disengaged` branch
(opts.disengaged), so the beat tail routes only itch/flop/bark — never walk-off.

**Why idle-only (and distractor left intact):** the beats are a **meter-driven ambient layer**,
conceptually separate from the timeline's `distractor` (a wrong *behavior* the player must not
mark). Folding them together would blur D9 (distractor must read distinct from a correct
attempt). Keeping beats on the idle lull preserves D9 and still surfaces the escalation during
the natural gaps between attempts.

**Poses (`dogPose.ts`) — a legible story, reduced-motion-safe:**
- `itch` — `headTiltZ 0.32` (cocked toward an ear-scratch) + a quick rhythmic wobble: mild "meh".
- `flop` — `crouchY −0.40` + `headPitch −0.30`: flopped low, head down, bored (forward-facing,
  distinct from the **back-turned** walk-off).
- `bark` — `headPitch 0.5` + `headLiftY 0.08` + small sharp `bounceY`: head-up protest/sass —
  the last beat before walk-off.
- Static channels (`headTiltZ`/`crouchY`/`headPitch`) survive `prefers-reduced-motion`; only the
  oscillation scales with `m` (D13).

**Tint/scale (`scene.ts`) — a graded withdrawal ramp** landing on the cool walk-off blue:
`ITCH (0.62,0.6,0.55)` warm-grey → `FLOP (0.52,0.54,0.58)` cool-grey → `BARK (0.45,0.5,0.62)`
steely cool-blue (+ faint emissive "agitated") → `DISENGAGED (0.34,0.41,0.6)`. `FLOP_SCALE 0.95`
/ `BARK_SCALE 0.93` subtly reinforce the "pulling away".

**Imported-rig map (`dogAnimationMap.ts`, flag-off):** the new states map to literal clips —
`itch→Scratching`, `flop→Lie`, `bark→Bark` (each falling back to an `Idle` clip) — so the same
escalation reads on either dog when the licensed model is enabled.

**Wiring (`main.ts`):** `const beat = disengageBeat(engagementMeter)` is computed once and
threaded into `updateDog` **and** the idle-pant gate (so a sulking dog isn't treated as idle
and doesn't pant). `disengaged` is now derived from that same `beat`.

**Visual Review (blocking) — PASS.** `scripts/shoot-beats.mjs` captures engaged → itch → flop →
bark → walk-off on a 390×844 viewport (+ a reduced-motion pass). Because the beats show only in
the idle gap, each capture waits for `offering` then for the beat (landing at the gap's start)
so the screenshot can't race the cycle. Real screenshots confirmed a clearly graded, "funny not
punishing" escalation — fidget → flop down → bark up → leave — each tellable apart at a glance;
reduced-motion poses read identically (only motion damped). Nit (non-blocking): `itch` is the
subtlest (tint + head-cock), which is appropriate for the mildest beat. **specs.md untouched.**

### Tap engagement/call-back decisions extracted + unit-tested — DONE (2026-06-21, task 117)

`onBraTapCommit` (`main.ts`) holds the loop's most ordering-sensitive logic, in the one
source file with **no unit test** (the bootstrap IIFE), covered only indirectly by
`e2e/full-loop.mjs`. Two braided rules were the edit-fragility risk: (1) **call-back must
branch BEFORE mark classification** — a walked-off tap calls the dog back and must never
score or false-mark; (2) the **reward-latency engagement leg fires only on a real reward**
(`PERFECT|OK` **with** an `attempt`), *after* the unconditional `{kind:'mark'}` transition.
Both are pure decisions that were tangled with side effects (audio/scene/coach), so they
couldn't be unit-tested in place. 117 is a **surgical, behavior-preserving extraction** into
two pure helpers in `gameHelpers.ts` (the established home for `main.ts`-extracted pure
logic — tasks 033/092), each TDD'd:

- `isCallBackTap(engagementMeter)` = `isDisengaged(disengageBeat(meter))` — names the "branch
  before classification" rule. Tested: true at empty meter (walk-off), false at full, false at
  a low-but-nonzero `bark` beat (only walk-off is a call-back).
- `tapEngagement({ engagementMeter, result, attempt, tnow })` — single source of truth for the
  mark transition **plus** the conditional reward-latency leg + its order. Tested: PERFECT/OK
  with an attempt apply **both** transitions (asserted ≠ mark-only, proving the reward leg
  ran); MISS/FALSE_MARK apply **only** the mark transition; `attempt === null` skips the reward
  leg even for a PERFECT tier (guards the `&& attempt` condition).

`onBraTapCommit` now calls the helpers instead of the inline expressions; the side effects
(`combo = 0`, `playTap`, `return` on call-back; audio/scene/coach on a mark) stay in the
handler — only the *decisions* moved. **Behavior-preserving**: full gate green **and**
`e2e/full-loop.mjs` still masters a trick by apex-timed taps. **specs.md untouched.**

## Idle "Welcome Back" Toast — DECIDED (2026-06-21, task 115)

specs.md §Kennel calls the capped idle trickle the game's gentle reason to return, "collected
on return." The economy half already existed — `idleIncome(idleTimestamp, now)` (capped at
`IDLE_CAP_COINS = 110`) is granted at load (`main.ts`) — but nothing **announced** it, so the
payoff never reached the screen. Task 115 adds the surfacing only:

- **Pure gate** `shouldShowIdleWelcome({ earnedCoins, economyRevealed })` in `onboarding.ts`
  (TDD): show iff coins accrued **and** the economy stage is revealed. The reveal gate matters —
  a brand-new player's coins are still hidden (staged reveal §7m), so a coin toast then would leak
  the economy before the first payout. Driven once at bootstrap (after `showSelect()`), never from
  `tick()`, so it can't appear mid-round.
- **HUD** `#hud-idle-welcome` toast + `showIdleWelcome(coins)` on the handle (mirrors the coach
  pill, task 108): a green "Velkommen tilbake! +N 🪙" pill at top-centre of the select screen, opaque,
  `aria-live="polite"`, distinct green from the gold coach. Slides + fades in, then auto-re-gates
  after `IDLE_WELCOME_MS = 4200` (a CSS-paired UI timeout, kept local per §8 — not a gameplay
  tunable) so it never blocks play. Reduced-motion drops the slide (pill still appears, D13).
- The 110-coin cap means the widest copy is "+110 🪙" — barely wider than the reviewed "+37", well
  clear of the side ?/⚙ buttons; no width-capping needed.

**Visual Review (blocking) — PASS.** `scripts/shoot-idle-welcome.mjs` shoots the toast on a
390×844 viewport (+ a reduced-motion pass); an independent review agent confirmed legibility,
clear gaps to the ?/⚙ buttons and the "Rex" heading, safe-area clearance, and reward-positive fit
(non-blocking nit only: the green is slightly higher-chroma than the muted chrome — intentional
pop). **specs.md untouched.**
