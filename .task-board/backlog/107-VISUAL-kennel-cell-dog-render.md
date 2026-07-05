# 107 — VISUAL: Kennel cells show a dog render behind the bars (K-1)

**Type:** VISUAL (3D→texture bake + render glue → **Visual Review**; no TDD — asset glue is exempt)
**Phase:** 8 (Kennel — current)
**Stories:** K-1 (browse the roster — "each cell reads at a glance: **dog render**, name, breed…").
**Depends on:** 105 (the grid + `_make_band`), the licensed/CC0 dog loader already in `main.gd`.
**Source:** PO Review 2026-07-05, Improvement 2.

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

- [ ] A single Labrador silhouette is baked to a shared `Texture2D` (SubViewport render of the real
      loaded dog model — never a primitive), reused across all 8 cells.
- [ ] Each cell shows the dog **bottom-anchored behind the steel bars**, `modulate`-tinted toward its
      `band_tint`, so all 8 cells read as visibly-distinct tinted dogs (dark Nova, brown Balder,
      blue-grey Bella, etc.) — verified by eye on a 390×844 grid capture.
- [ ] The steel bars now read as metal over a dog, not stripes over flat colour (no separate bar fix
      needed).
- [ ] Headless `verify.sh` stays green — the bake must not error the headless boot (guarded / lazy).
- [ ] `nix develop -c bash verify.sh` green (import·boot·test·export).
- [ ] Visual Review PASS on the live web build (real canvas, 390×844): 8 tinted dogs behind bars, and
      the Phase-6 training page still intact behind the «Kennel» pill (no regression).
