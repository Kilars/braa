# 107 — VISUAL: Kennel cells show a dog render behind the bars (K-1)

**Type:** VISUAL (3D→texture bake + render glue → **Visual Review**; no TDD — asset glue is exempt)
**Phase:** 8 (Kennel — current)
**Stories:** K-1 (browse the roster — "each cell reads at a glance: **dog render**, name, breed…").
**Depends on:** 105 (the grid + `_make_band`), the licensed/CC0 dog loader already in `main.gd`.
**Source:** PO Review 2026-07-05, Improvement 2.

## ⚠️ Attempt 1 (2026-07-05) — REVERTED. Read before retrying.

A first pass tried the **live-SubViewport-bake** route below (`main._bake_kennel_portrait()` →
`SubViewport(own_world_3d) + Camera3D + DirectionalLight` → `get_texture()` shared into the kennel
cells' `TextureRect`s, per-cell `modulate`). It was **reverted** (source restored to the 106 commit)
because the Visual Review FAILED on three counts:
1. **Framing unusable.** The camera framed by the dog's *height* (`dist = dog_height*0.5 / tan(fov/2) / 0.85`).
   A Labrador is a quadruped — far longer than tall — so height-fit put the camera on top of the dog:
   every cell showed an extreme close-up of belly/leg fur, **no head, no readable dog silhouette**.
2. **Training-dog bleed-through.** Two large dog legs rendered at the **bottom of the screen** below
   the grid (the 106 grid had clean grey there) — the portrait `Camera3D` / world was not cleanly
   isolated from the main training viewport (suspected: the portrait camera became `current` in a
   shared world, or the `SubViewport` added to the scene root leaked its render).
3. **New boot errors.** `ERROR: Condition "!is_inside_tree()" is true. Returning: Transform3D()` — the
   portrait camera's `look_at`/transform ran before the node was settled in the tree.

**Recommended retry route — bake OFFLINE to a committed PNG (robust, no runtime 3D).** This sidesteps
all three failures: no live SubViewport, no camera-isolation risk, no per-frame timing, headless-safe,
and it literally matches the spec's *"baked Texture2D per breed in-grid for perf (X-7)"*.
- Add a small **headless capture scene/script** (mirror `tools/capture_apex.tscn` / `capture_reaction.tscn`):
  load the dog via the same `_dog_path()` logic, `CoatOpaque.flatten()`, frame it **3/4-front,
  bottom-anchored, whole dog with head visible** (fit by the dog's *bounding-box max extent* viewed
  from the front-quarter, NOT its height), render one settled frame to a transparent-bg image, and
  save a PNG to `assets/kennel/dog_portrait.png`. Run it once via `nix develop -c godot --headless`
  (offline tool, like the espeak/Piper bakes) and **commit the PNG**. (A portrait render doesn't expose
  the protected licensed geometry — the live game already shows this dog to every player — so it is not
  additional asset exposure. If licensing is a concern, bake from the CC0 `dog.glb` instead — still a
  real dog silhouette, honest stand-in.)
- The kennel then just `load("res://assets/kennel/dog_portrait.png")` as a static `Texture2D`, no
  SubViewport, no `main.gd` bake — pass it to `set_portrait(tex)` (or load it directly in
  `kennel_screen.gd`). `_make_band` adds the `TextureRect` behind the bars, `modulate` per `band_tint`.
- **Verify the framing by eye FIRST** (open the baked PNG) before wiring 8 cells, so a bad frame is
  caught once, not multiplied by 8.

If the live-SubViewport route is retried instead, the two must-fixes are: frame by the dog's overall
extent from a front-quarter angle (not height), and **prove world isolation** (the training viewport's
camera stays current; no bleed-through) + defer the camera transform until the portrait node
`is_inside_tree()` (no boot errors). The offline-PNG route is preferred — fewer moving parts.

## What this addresses

Every kennel cell's portrait band is a **flat tinted rectangle with zero dog inside** — the steel
bars sit over nothing, so the "dogs behind clean steel bars" read collapses and the 8 cells are
indistinguishable coloured panels. K-1 requires each cell to show a **dog render** so the roster
reads at a glance without a tap. The PO explicitly ruled this **not owner-gated**: the licensed
Labrador renders live in training, the chocolate-Lab `CoatTint` recolor already proved a **tinted
stand-in** ships with no new model, and phase8.md's own asset note says *"every buildable slice
(recolor breeds à la the chocolate Lab) ships first."* Tint-only bands over-claim the BUST-068 gate.

## Why now

- The PO named it a defect in the reviewed grid; the grid can't be signed off looking like empty
  colour panels.
- It's the last thing making the cells "read at a glance" before the modal/adopt spine layers on.

## Technical approach

**Honest stand-in, no faked distinct breeds.** All 8 dogs share the one licensed Labrador rig
(distinct breed models are owner-gated, BUST-068). So render **one Labrador silhouette**, reused per
cell and **tinted toward each dog's `band_tint`**, bottom-anchored behind the existing steel bars.
This is exactly what the PO asked for ("at minimum the real Labrador silhouette tinted to the dog's
band tint, baked to a `Texture2D` for grid perf, X-7"). Do **not** author fake per-breed
silhouettes.

**Bake once, reuse 8×** (phase8.md Godot notes: "Portrait = baked `Texture2D` per breed in-grid for
perf, X-7"):

1. **Render the Labrador to a texture once.** Add a small baker (e.g. `scripts/dog_portrait.gd` or a
   helper in `main.gd`) that instances the already-loaded dog model into a `SubViewport`
   (transparent background, `TRANSPARENT_BG = true`), frames it with a `Camera3D` so the dog fills
   the band aspect **bottom-anchored** (feet near the band bottom, head up), renders a frame, and
   grabs `SubViewport.get_texture().get_image()` → an `ImageTexture`. Reuse the project's existing
   dog loader (the same path `main.gd` uses — CC0 dog locally, licensed on deploy); **never** a bare
   primitive stand-in (CLAUDE.md — hold hidden until the model is ready, no capsule/sphere for even
   one frame).
2. **Per-cell tint.** In `_make_band`, add a `TextureRect` (the baked silhouette) **under** the
   `_SteelBars` overlay and above the tint `ColorRect`, bottom-anchored, `STRETCH_KEEP_ASPECT_CENTERED`
   (or `_KEEP_ASPECT` anchored to the band bottom). Set `modulate` from the row's `band_tint`
   (darkened/desaturated a touch so the dog reads as a tinted animal, not a flat colour) so Bella
   reads blue-grey, Nova dark, Balder brown, etc. — a real dog shape in every cell, tinted per dog.
3. **Grid perf / X-7:** bake the base texture **once** and share the one `ImageTexture` across all 8
   `TextureRect`s (each just re-`modulate`s) — no 8 live viewports. Offline after first load.

**Headless / GL-Compatibility care (gotchas that have bitten):**
- The bake touches the SceneTree + a viewport render — guard it on `is_inside_tree()` and skip
  cleanly headless (the headless verify boot must not error). If the viewport texture can't be
  grabbed headless, the bake may run lazily on first real `_open_kennel()` (web/editor) — the band
  falls back to the tint-only look **only** in the headless harness, never in the shipped web build.
- Skinned-dog transforms are ~origin until frame 1 — let the model settle a frame before framing the
  camera / grabbing (accumulate node-local transforms; cf. CLAUDE.md).
- Local Chromium capture needs `env -u LD_LIBRARY_PATH`.

### Before

```gdscript
# kennel_screen.gd _make_band(): tint ColorRect + steel bars only — no dog.
var bg := ColorRect.new(); bg.color = row.band_tint; band.add_child(bg)
var bars := _SteelBars.new(); band.add_child(bars)   # bars over empty colour
```

### After

```gdscript
# kennel_screen.gd _make_band(): tint bg → tinted Labrador silhouette → steel bars on top.
var bg := ColorRect.new(); bg.color = row.band_tint; band.add_child(bg)

var dog := TextureRect.new()                     # the baked Labrador, reused across cells
dog.texture = _portrait_texture                  # one shared ImageTexture (baked once)
dog.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
dog.modulate = _band_dog_tint(row.band_tint)     # per-dog tint so each cell reads distinct
dog.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)   # bottom-anchored
band.add_child(dog)

var bars := _SteelBars.new(); band.add_child(bars)   # bars now read as metal OVER a dog
```

## Placeholder / tofu check

- Grep the diff for `placeholder|stub|dummy|fake|primitive|capsule|sphere|cylinder` — none may
  stand in for the dog. A tint-only fallback is allowed **only** in the headless harness and must be
  noted as such (it is not the shipped web render).
- The tinted-Labrador-shared-silhouette is the honest stand-in the open BUST-068 flag already names
  (distinct per-breed models owner-gated) — not a new stub.

## Acceptance criteria

- [x] A single Labrador silhouette is baked to a shared `Texture2D` (SubViewport render of the real
      loaded dog model — never a primitive), reused across all 8 cells.
- [x] Each cell shows the dog **bottom-anchored behind the steel bars**, `modulate`-tinted toward its
      `band_tint`, so all 8 cells read as visibly-distinct tinted dogs (dark Nova, brown Balder,
      blue-grey Bella, etc.) — verified by eye on a 390×844 grid capture.
- [x] The steel bars now read as metal over a dog, not stripes over flat colour (no separate bar fix
      needed).
- [x] Headless `verify.sh` stays green — the bake must not error the headless boot (guarded / lazy).
- [x] `nix develop -c bash verify.sh` green (import·boot·test·export).
- [x] Visual Review PASS on the local web build (real canvas, 390×844, Chromium/SwiftShader): 8 tinted
      dogs behind bars (`.screenshots/105-kennel-01-grid.png`), and the Phase-6 training page still intact
      behind the «Kennel» pill, no regression (`.screenshots/105-kennel-03-closed.png`).

## Attempt 2 (2026-07-05) — SHIPPED. What changed vs the plan.

The recommended route was "bake OFFLINE via `godot --headless`". **That is impossible in this environment:
local Godot GL is broken** — hardware GLX segfaults (`Parameter "fbc" is null` → signal 11), and the
software-GL fallback (Xvfb + llvmpipe) segfaults too. The project's ONLY working render path is
Chromium/SwiftShader on the Web export (why every PO review runs there). So the bake was adapted to that
proven path, keeping the SAME committed-static-PNG outcome the spec wants:

- **`main._bake_portrait()`** — a `?bra_bake_portrait=1` web-gated route (dormant in normal play). Renders
  the **CC0** dog (forced `DOG_SCENE_PATH`, never the licensed Labrador — see flag) to a transparent
  `SubViewport` (`own_world_3d` → no bleed; attempt-1 #2), frames a **telephoto** (fov 30°) camera by the
  **bounding-sphere** extent (attempt-1 #1 height-fit close-up), strips the CC0 glb's bundled Camera3D (it
  stole `current`), desaturates to a tintable mid-grey silhouette, crops to the used rect, hands the PNG
  base64 to `window.__bra_portrait_png`. Deferred until in-tree → no `Transform3D()` boot error (attempt-1 #3).
- **`tools/bake_kennel_portrait.mjs`** — one-shot Playwright harness: boots the bundle with the bake query,
  reads the base64, writes **`assets/kennel/dog_portrait.png`** (249×305, committed).
- **`kennel_screen.gd`** — loads that ONE static `Texture2D` (X-7: bake once, reuse 8×, zero runtime 3D),
  adds a bottom-anchored `TextureRect` behind the steel bars per cell, `modulate`-tinted via `_band_dog_tint`
  (adaptive: lighten on dark bands, `band_tint` on light bands so the grey base renders a darker silhouette).
  Absent-PNG → clean tint-only fallback (headless-safe, never a primitive).

The modal band (K-2) was left tint-only this slice — it centres the dog NAME full-rect, so a silhouette
behind it is a separate polish call, out of K-1 scope.
