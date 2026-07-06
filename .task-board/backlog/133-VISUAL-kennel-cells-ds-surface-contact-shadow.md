# 133 — VISUAL — Kennel cells: one DS neutral surface + grounding contact shadow

**Source:** PO Review 2026-07-06, directive **#3 [MED]** (kennel).
**Phase:** current-phase X-4 quality (preempts the Phase-10 owner-gate).

## What it addresses

The cells float on arbitrary striped, off-token backgrounds with no floor and no shadow, so the
grid has no cohesion with the garden:
- Eight clashing ad-hoc band fills (bright blue, grey, browns, orange) with vertical steel planks.
- Each dog floats with no contact shadow — nothing grounds it.

**Acceptance (PO):** one DS neutral surface (Warm Sand `#F4EFE6` / soft Sky) shared across cells,
tinted **only** by ownership state; add a soft contact shadow grounding each dog (reuse the training
garden's); keep any plank texture subtle.

## Technical approach

All in `scripts/kennel_screen.gd` `_make_band()` (~L492-568). Render glue — **Visual Review**,
not TDD.

**1. Replace the per-breed rarity `band_tint` background with one DS neutral surface.** Today
`bg.color = row.band_tint` gives each cell its own rarity colour → the "eight clashing fills" the
PO flagged. Swap to a single Warm Sand surface (`#F4EFE6`, the DS `C_MODAL_CREAM` already in file),
tinted **only** by ownership state — e.g. owned cells a faint green-warm wash, easter-egg a faint
coral wash, neutral the plain sand. Keep the per-dog *coat* tint on the portrait (`_band_dog_tint`)
untouched — that is what distinguishes the dogs; the *background* is what must unify.

Before:
```gdscript
var bg := ColorRect.new()
bg.color = row.band_tint
```
After (sketch — one shared neutral, only ownership shifts it):
```gdscript
var bg := ColorRect.new()
bg.color = _cell_surface(row)   # Warm Sand base; owned/egg get a faint state wash, else plain sand
```
Add a small helper:
```gdscript
func _cell_surface(row: Dictionary) -> Color:
    if row.owned:  return C_SURFACE_OWNED   # sand nudged toward soft green
    if row.secret: return C_SURFACE_EGG     # sand nudged toward soft coral
    return C_SURFACE_SAND                    # Warm Sand #F4EFE6
```
This *is* a tiny pure mapping → **unit-lock it** (test-first): `_cell_surface` returns the sand
base for a neutral row, the owned wash for `owned==true`, the egg wash for `secret==true`.

**2. Keep the steel planks subtle.** The `_SteelBars` overlay currently reads as loud vertical
planks. Drop its alpha / widen its pitch so it's a subtle texture on the sand, not the dominant
visual (PO: "keep any plank texture subtle"). Tune `C_STEEL` alpha or the bar draw in `_SteelBars`.

**3. Add a grounding contact shadow under each dog.** The training garden grounds the dog with a
soft shadow ellipse; reuse that treatment here. Draw a soft dark ellipse (`Color("22344a", ~0.12)`)
centred under the portrait's feet, behind the dog TextureRect, so each dog sits on the surface
instead of floating. Match the training garden's shadow softness/opacity.

Before: (no shadow — dog floats on the band)
After (sketch — a soft ellipse behind the dog, at its feet):
```gdscript
var shadow := _ContactShadow.new()   # draws a soft dark ellipse; or a pre-blurred TextureRect
band.add_child(shadow)               # added BEFORE the dog so the dog sits on top
```

## Test / review

- `_cell_surface` mapping is pure → **TDD** (add to `tests/test_kennel_screen_wiring.gd` or a new
  `tests/test_kennel_cell_surface.gd`): neutral→sand, owned→owned-wash, secret→egg-wash.
- The surface/plank/shadow rendering is glue → **Visual Review** at 390×844: re-capture the grid
  (`tools/web_capture_kennel.mjs`) and confirm one cohesive neutral surface across all cells
  (only ownership shifts it), subtle planks, and every dog grounded by a soft contact shadow.

## Acceptance criteria

- [ ] All 8 cells share one DS neutral surface (Warm Sand `#F4EFE6`), tinted **only** by ownership
      state — no more eight clashing rarity fills.
- [ ] Per-dog **coat** tint on the portrait is unchanged (that stays the dog-distinction signal).
- [ ] Steel planks are subtle (reduced alpha / wider pitch), not the dominant element.
- [ ] Each dog has a soft contact shadow grounding it (matches the training garden's treatment) —
      no floating dogs.
- [ ] `_cell_surface` covered test-first (neutral→sand, owned→wash, secret→wash); tests green.
- [ ] No new scattered `Color(...)` literals beyond the named surface/shadow tokens.
- [ ] Visual Review PASS on the full 8-cell grid capture (phone-portrait 390×844).
- [ ] verify gate green (import·boot·test·export); placeholder check clean.
