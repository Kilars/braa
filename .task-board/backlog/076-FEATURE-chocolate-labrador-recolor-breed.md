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

- [ ] TDD (logic): `BreedPersonality.chocolate_labrador()` (distinct `coat_tint` + temperament +
      roster entry) and `CoatTint.apply` (sets `albedo_color` on the coat override) — tests first,
      RED→GREEN. `labrador().coat_tint()` is identity `Color(1,1,1)` (yellow lab unchanged).
- [ ] `CoatTint` tints ONLY the coat surface(s) CoatOpaque targets (eyes/nose/other untouched); runs
      after `CoatOpaque.flatten()` on the cloned override (never mutates a shared resource).
- [ ] Chocolate Labrador reachable as breed #2 via a debug seam (e.g. `?bra_breed=chocolate`); the
      yellow Labrador stays the default (no regression to the PO-signed experience).
- [ ] **Visual Review (blocking, phone-portrait, REAL render):** the chocolate coat honestly reads as
      a Chocolate Labrador (warm dark brown body, dark nose, fur detail intact) — NOT a mud-washed
      yellow lab. Capture the chocolate dog at 390×844; orchestrator confirms by eye. If it can't be
      made convincing by tuning the tint, re-flag as owner-gated (re-painted atlas) rather than ship a stub.
- [ ] Placeholder check clean; `nix develop -c bash verify.sh` green (import·boot·test·export).

## Notes

Depends on **075 (BreedPersonality)** landing first (the chocolate breed needs its temperament +
the roster entry). The multi-breed **adopt/select UI** (spotlit select screen) stays owner-gated
(P3-1/P3-2 appearance polish + P3-D1/D2/D4 decisions) — this task only makes the second breed exist
and be reachable; the pretty selection surface is a later, owner-gated story. The known coat-seam
(WONTFIX cosmetic) and the mouth-interior tint (0.84% atlas) are accepted cosmetic residuals; do not
regress them, but they don't block.
