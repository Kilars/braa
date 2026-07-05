# 116 — VISUAL: kennel dogs read as the stylized-realism Labrador (X-4 / K-1 Visual-Review)

**Phase 8 (kennel) · current-phase · NOT owner-gated · from PO Review 2026-07-05 (HEAD `d29c032`)**

## The directive (father, po-review.md Improvement #1)

The kennel cells + modal header currently render a single shared, chunky **CC0 voxel dog**
(baked into `assets/kennel/dog_portrait.png`, tinted per breed), framed side-/rear-on with
the head turned down. Task 115 enlarged it, so 8 blocky dogs now dominate the screen. Against
the signed-off training page — the warm stylized-realism licensed Labrador facing camera — the
kennel reads as **placeholder art**. This **fails X-4** ("the dog always reads as a real dog
and as its breed" — a voxel dog reads as neither) and Phase 8's own Visual-Review acceptance
("same Pokémon-GO stylized-realism as training").

**This is NOT the owner gate.** Distinct per-breed *models* stay owner-gated (BUST-068 / P3-2)
— which only justifies the 8 dogs *sharing one silhouette*, tinted — but that silhouette must be
the **same stylized-realism licensed Labrador the training page already renders and coat-tints**,
not a separate low-poly CC0 model.

## Definition of done (Good, per the PO)

1. The kennel dog render reads as the **stylized-realism Labrador** (the game's actual dog:
   licensed on deploy, CC0 locally — pick it via the SAME path as `main._dog_path()`), framed
   **facing the viewer** as a flattering portrait (face/head visible, not rear/side-slumped),
   behind the thin steel bars, shared across all 8 cells + the modal header and **per-breed
   coat-tinted** (keep the existing `_portrait_tint` modulate logic + the dark-band lighten).
2. **Mechanism = runtime `SubViewport`** rendering the loaded dog (the spec sanctions this;
   avoids the licensing problem of baking a licensed-dog PNG into public git — see FLAGS.md
   2026-07-05 "Kennel cell portraits use the CC0 blocky dog"). Reuse `DogBounds.measure` +
   `DogFraming` (already model-agnostic, face-on `VIEW_DIR`) to frame it; `transparent_bg = true`
   so only the dog carries the modulate tint. Render ONE shared dog → one `ViewportTexture` fed
   to every cell + the modal header (X-7: one render, 8 modulated consumers). Render the dog at a
   **neutral/desaturated coat** so the per-breed modulate reads cleanly (the current bake is
   mid-grey for exactly this reason).
3. **Retire the CC0 baked PNG path**: remove `assets/kennel/dog_portrait.png` (+ `.import`) and
   the `tools/bake_kennel_portrait.mjs` bake, and repoint `_get_portrait_texture()` at the live
   SubViewport texture. (The tinted CC0 stand-in is what the father is rejecting — don't leave it
   wired as a fallback that reappears; the SubViewport degrades to the CC0 rig LOCALLY on its own,
   which is fine — verify uses CC0, the father reviews the deployed licensed build.)
4. **Bars nudge:** the steel bars render very faint — nudge toward the spec's `#788794` @ 32–40 %.
5. **Gate green** (`nix develop -c bash verify.sh`) — the SubViewport must not error on the
   headless boot/test legs (guard `.play()`/tree-attach per the CLAUDE.md harness gotcha; attach
   the SubViewport lazily, never in `_init`).

## Notes / constraints

- Pure render/3D/asset-glue → **Visual Review**, not TDD (keep the existing kennel unit tests
  green; update any that asserted the baked-PNG path). Run `polish` + review the running build in
  a 390×844 headless-Chromium capture of the kennel grid + modal.
- Behavior ≠ inventory still holds: this changes only the *render*, not the trick lists — no
  per-breed trick faking, K-8 stays honest.
- Do **not** commit any licensed-derived still into git (that's the whole point of the SubViewport
  route). Keep `dog_licensed*` gitignored.
- Watch cost: one live 3D SubViewport shared across 8 cells is cheap; do **not** spin up 8
  viewports.

## Placeholder check
Grep the diff for the stub list; the retired CC0 `dog_portrait.png` leaving the tree is the
*removal* of a stand-in, not a new one. No new stub introduced.

---

## OUTCOME (2026-07-05, DONE)

Replaced the baked CC0 voxel-dog PNG with a single live **`SubViewport`** rendering the game's
actual dog (licensed Labrador on deploy, CC0 locally — same pick as `main._dog_path()`), shared
across all 8 cells + the modal header (X-7), neutral-coat so the per-breed `modulate` reads.
Retired `assets/kennel/dog_portrait.png` (+ `.import`), `tools/bake_kennel_portrait.mjs`, and the
`main._bake_portrait` route. Bars nudged (denser stripes @ spec `#788794`, alpha 0.38).

**Facing fix (2nd pass):** the raw idle rest pose renders side-on, so the first capture read as a
broadside profile — not the father's "framed facing the viewer". Applied the SAME camera-facing yaw
main.gd uses for the trick face-turn (061): `heading = atan2(camX-dogX, camZ-dogZ)` on the root
basis about UP, plus a `PORTRAIT_THREE_QUARTER` (~24°) offset for a flattering front-¾ portrait.

**Gate:** `✓ verify gate green` (import · boot · test · export), twice.
**Visual Review (mine, real canvas taps on `build/web`, 390×844):** PASS. Grid
(`105-kennel-01-grid.png`) + modal header (`108-kennel-modal.png`) both render the stylized-realism
Labrador facing the viewer, per-breed tinted, behind visible steel bars — X-4 cleared, no voxel dog,
no regression (`105-kennel-03-closed.png` training intact). No licensed pixels committed to git.

FLAGS.md 2026-07-05 "Kennel cell portraits use the CC0 blocky dog" → RESOLVED by this task.
Owner-gated residuals unchanged (distinct per-breed MODELS + signature clips — BUST-068 / P3-2).
