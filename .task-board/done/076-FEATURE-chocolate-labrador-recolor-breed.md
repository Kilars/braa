# 076 — FEATURE: Chocolate Labrador — a 2nd breed via runtime coat recolor (P3-1 / P3-2)

**Type:** FEATURE (visual/asset recolor + logic wiring; Visual-Review gated) · **Phase:** 3
(current) · **Source:** **BUST-074** (2026-07-02) — the chocolate-Lab flag-bust concluded a second,
breed-distinct dog is **buildable WITHOUT the owner** by tinting the licensed Labrador's single coat
material at runtime · **Priority:** P2 — this is the **first real second breed**, the Phase-3 headline,
from assets already in the repo. **Do after 075 (BreedPersonality)** so the chocolate breed gets its
own temperament, not just a recolor.

## What it addresses

Phase 3 is "dog breeds," and the only breeds gated on the owner are *new models*. BUST-074 proved a
**Chocolate Labrador is not a new model** — it is the same rig with a warm-brown coat, achievable by
a runtime `albedo_color` multiply on the one coat surface. That yields a genuine second breed
(distinct look, same 3-trick roster Sitt/Ligg/Legg deg, its own personality) with no owner asset.

## Findings this builds on (from BUST-074 — see `done/074-BUST-chocolate-labrador-breed.md`)

- The licensed Labrador is **one mesh / one primitive / one `StandardMaterial3D` (`Labrador`)**; the
  glTF `baseColorFactor` is white `[1,1,1,1]`, so ALL coat colour lives in the baked albedo atlas
  `assets/models/dog_licensed_Labrador_Albedo.png` (2048²). Godot's `albedo_color` multiplies over
  that atlas.
- `CoatOpaque.flatten()` already **clones** that material into a surface-override
  (`scripts/coat_opaque.gd` `_flatten_surface`) — the tint hooks the same cloned material, so it
  never mutates a shared resource.
- The bust's calibrated tint `albedo_color = Color(0.668, 0.491, 0.321)` (≈`#AA7D51`) maps the coat
  body into the real chocolate-Lab range (`#6B4020`–`#8A5530`), preserves fur-strand contrast
  (1.71×→1.69×), keeps nose/pads dark. **Caveat:** the mouth interior (~0.84% of the atlas) tints to
  a brownish-red — cosmetically off-anatomy but tiny (~10–20 px at phone scale, only during
  reaction/scratch). Acceptable to ship; a re-painted atlas is the owner-gated cosmetic residual.
- **This tint value is a STARTING POINT, not gospel** — the bust was a computed pixel simulation, not
  a rendered frame. The Visual Review below judges the REAL render and the implementer tunes the
  colour until it honestly reads as a chocolate Lab. If the real render looks muddy and no tint
  rescues it, that is a genuine finding → re-flag as owner-gated (re-painted atlas), do NOT ship a mud-wash.

## Technical approach

A per-breed **coat tint** applied to the cloned coat material, selected by the active breed. Keep it
dog-agnostic and additive: the yellow Labrador is tint `Color(1,1,1)` (identity — unchanged), the
chocolate Labrador is `~#AA7D51`.

- Add a small tinting step that runs right after `CoatOpaque.flatten()` (which already produced the
  cloned override material). It sets `albedo_color` on the coat surface's override material to the
  active breed's coat tint. Guard on the surface actually being the coat (the alpha-textured body
  surface CoatOpaque targets), so eyes/other surfaces are untouched.

  **Before** (coat left at the atlas's own colour — always yellow):
  ```gdscript
  # after instancing the dog:
  CoatOpaque.flatten(dog)   # clones the coat material opaque; colour = the baked yellow atlas
  ```
  **After** (breed tint multiplies the atlas):
  ```gdscript
  CoatOpaque.flatten(dog)
  CoatTint.apply(dog, _breed.coat_tint())   # yellow lab: Color(1,1,1) identity; chocolate: ~#AA7D51
  ```
  Implement `CoatTint.apply(dog, tint)` in a new `scripts/coat_tint.gd` (walk the same surfaces
  CoatOpaque touched; set `albedo_color = tint` on their override materials). Pure-ish node glue —
  it mutates only the already-cloned override, mirroring CoatOpaque's pattern.

- Add `coat_tint` to `BreedPersonality` (075): `labrador()` → `Color(1,1,1)`; add
  `chocolate_labrador()` → `Color(0.668, 0.491, 0.321)` with its own temperament (bust suggests a
  livelier chocolate: higher distractibility / energy, still trainable). Both are breed entries in
  the roster spine.

- Wire the chocolate Labrador as **breed #2** behind the economy/roster (P3-D3): it is a coin-unlock
  in the (buildable) roster; the yellow Labrador stays the default so the PO-signed current
  experience is unregressed. A debug seam (e.g. `?bra_breed=chocolate`, mirroring `?bra_trick=`) lets
  the Visual Review and the owner see the chocolate coat before the adopt/select UI (owner-gated
  spotlit select screen) exists.

### TDD (follow `.claude/skills/tdd/SKILL.md`) for the LOGIC only

- `BreedPersonality.chocolate_labrador()` exists, has `coat_tint() == Color(0.668,0.491,0.321)`, a
  distinct temperament from `labrador()`, and is a distinct roster entry. `labrador().coat_tint()`
  is the identity `Color(1,1,1)`.
- `CoatTint.apply` sets `albedo_color` on the coat override material to the passed tint (assert via a
  headless MeshInstance3D + StandardMaterial3D fixture, mirroring `test_coat_opaque.gd`).
- The **coat colour itself** (does it read as a real chocolate Lab) is **Visual-Review**, not a test.

## Acceptance criteria

- [x] TDD (logic): `BreedPersonality.chocolate_labrador()` (distinct `coat_tint` + temperament +
      roster entry) and `CoatTint.apply` (sets `albedo_color` on the coat override) — tests first,
      RED→GREEN. `labrador().coat_tint()` is identity `Color(1,1,1)` (yellow lab unchanged).
- [x] `CoatTint` tints ONLY the coat surface(s) CoatOpaque targets (eyes/nose/other untouched); runs
      after `CoatOpaque.flatten()` on the cloned override (never mutates a shared resource).
- [x] Chocolate Labrador reachable as breed #2 via a debug seam (`?bra_breed=chocolate`); the
      yellow Labrador stays the default (no regression to the PO-signed experience).
- [x] **Visual Review (blocking, phone-portrait, REAL render):** PASS — captured the chocolate dog at
      390×844 on the local licensed bundle (`?bra_breed=chocolate`) and confirmed by eye: warm dark
      chocolate-brown body, dark nose, fur detail intact, unmistakably distinct from the cream yellow
      reference — NOT a mud-washed yellow lab.
- [x] Placeholder check clean; `nix develop -c bash verify.sh` green (import·boot·test·export).

## Completion notes (2026-07-02)

**What shipped:**
- `BreedPersonality.chocolate_labrador()` — breed #2 on the SAME licensed rig: temperament distinct on
  every axis from the yellow Lab (learn 1.1 / distract 1.1 / window 1.0 / energy 1.1 — a warmer, busier
  retriever, still very trainable) + `coat_tint()`. Added a `_coat_tint` field (optional trailing
  `_init` param, default `Color(1,1,1)`) with a `coat_tint()` accessor; `labrador()`/neutral are identity.
- `scripts/coat_tint.gd` (`CoatTint.apply`) — walks the dog subtree, and on each albedo-TEXTURED coat
  surface (the exact surface `CoatOpaque` targets) duplicates the material, multiplies `albedo_color` by
  the breed tint (keeping the atlas texture so fur/nose detail survive), assigns it back as an override.
  Never mutates a shared resource; textureless eye/glass fades left alone. Runs right after
  `CoatOpaque.flatten()` in `_load_dog`.
- `main.gd` — `_query_breed()` reads `?bra_breed=chocolate` (STRING sentinel, dodges the web null-Variant
  gotcha); `_breed = _query_breed()` set at top of `_ready()` (before `_load_dog`/`_start_dog`); boot log
  now reports `N tinted for breed '<id>'`.

**Tuning (Visual Review):** the bust's computed `~#AA7D51` rendered a light, reddish milk-chocolate under
the bright scene sun. Darkened to `Color(0.50, 0.37, 0.26)` (`~#805E42`) so it reads as a deep coffee-brown
Chocolate Lab. Evidence: `.screenshots/076-chocolate2-*.png` (chocolate) vs `076-yellow-*.png` (reference).

**Residuals (unchanged, not blockers):** the multi-breed adopt/select UI stays owner-gated (P3-D1/D2/D4 +
appearance polish); the mouth-interior tint (~0.84% of the atlas) is the accepted cosmetic residual
(re-painted atlas is owner-gated). Yellow Lab remains the default — PO-signed experience unregressed.
Tests +8 (5 new in `test_coat_tint.gd`, 3 new in `test_breed_personality.gd`). Verify gate green.

## Notes

Depends on **075 (BreedPersonality)** landing first (the chocolate breed needs its temperament +
the roster entry). The multi-breed **adopt/select UI** (spotlit select screen) stays owner-gated
(P3-1/P3-2 appearance polish + P3-D1/D2/D4 decisions) — this task only makes the second breed exist
and be reachable; the pretty selection surface is a later, owner-gated story. The known coat-seam
(WONTFIX cosmetic) and the mouth-interior tint (0.84% atlas) are accepted cosmetic residuals; do not
regress them, but they don't block.
