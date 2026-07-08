# 190 — FIX: kennel over-browns the light-coat dogs (Bella cream on training, brown in kennel)

**Source:** PO father-pass-64 (X-6), `.docs/specs/po-review.md` @ HEAD `1b1d6e0`. Board empty; this is the one buildable directive filed this pass.

## The directive
On the **training page** the owned/active dog **Bella** renders as a **pale cream / yellow Labrador**
(in-pixel coat ≈ rgb(206,195,178), low warm bias R−B≈28). In the **kennel** the *same* Bella cell —
and her inspect modal — renders as a **saturated medium-BROWN** (≈ rgb(114,88,48), strong warm bias
R−B≈66). Sol (Golden retriever, another light breed) is likewise browned (≈ rgb(106,77,40)). This is a
cross-surface **coat-identity break**: Bella is the one dog the player sees on *both* surfaces (owned +
active + on the training page), so she reads like a different breed depending on the screen.

The darker breeds (Nova grey, Pontus/Sniff brown) already look right — this is about **not crushing the
light coats**, NOT re-darkening the dark ones.

## Root cause
The kennel portrait pipeline renders the dog at `NEUTRAL_COAT = Color(0.62,0.62,0.62)` under the 187
portrait light rig (softened/warm), then multiplies the 2D `TextureRect.modulate` by
`_band_dog_tint(portrait_tint)` (`kennel_screen.gd:868`). For a **light** coat the tint currently passes
through **unchanged** (only *dark* coats get lightened). Bella's `portrait_tint`
`Color(0.905,0.760,0.470)` is a strongly warm/saturated tint; multiplied into a already-dark warm render
it collapses the pale coat into a medium brown. The training page, by contrast, rides the untouched
licensed atlas under the garden sun → pale cream.

## Fix (shared tint — grid + modal move together, 187 parity preserved)
Add a **light-coat branch** to `_band_dog_tint` (the SINGLE shared function both the grid cell
`:638` and the modal hero `:1220` call), mirroring the existing dark-coat branch but the other way:
for coats above a light-luminance threshold, **desaturate** the warm-brown bias (pull toward the coat's
own luminance) and **gain the exposure up** (modulate > 1.0 brightens the 2D texture) so the pale coat
reads pale/cream in the kennel — up toward Bella's training coat — instead of brown. Only light coats
(Bella, Sol, Trulte, near-white) cross the threshold; dark coats (Nova/Pontus/Balder/Sniff) are
untouched.

## Definition of done
- TDD: light coats are LIGHTENED (luminance up) + DESATURATED (R−B reduced) after `_band_dog_tint`;
  dark coats (Nova/Pontus) unchanged from today (147 hue-preservation intact). Update the now-stale
  `test_light_coat_is_unchanged` to the new light-coat contract.
- Visual Review: capture the training-page Bella coat and the kennel Bella cell + modal at 390×844
  headless Chromium; kennel Bella reads as a pale cream/yellow lab (warm bias close to the training
  coat, NOT a saturated brown); dark coats and 187 grid↔modal parity unchanged.
- verify gate green; commit + push.

## Guardrails (per MEMORY)
- Do NOT re-darken the dark coats, do NOT re-desync the modal from the grid, do NOT restore
  `_band_dog_tint`'s dark-branch lerp→white (147), do NOT touch the training-page coat (it is the
  correct reference). Change is confined to the light-coat path of the shared kennel tint.
