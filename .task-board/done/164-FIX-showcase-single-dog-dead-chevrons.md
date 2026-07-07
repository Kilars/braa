# 164 — FIX — Breed showcase: honest chevron/hint state for a single-dog roster

**Type:** FIX (wrong empty-state) · **Source:** PO father-pass-29 (`.docs/specs/po-review.md`, HEAD `ba74328`)
**Phase:** ongoing X-4/X-6 father polish arc on the design-system bar (Phase 9 current; 1/2/3/5/6/8/9 signed off)

## Problem

The breed showcase («Vis frem hundene», P3-4) offers ◀ ▶ cycle chevrons and a hint
«Bla med pilene eller trykk en hund» ("scroll with the arrows or tap a dog") in **every**
state. A new player owns exactly **one** dog, so the showcase's default / most-common state
is a single-dog roster — and there the chevrons draw as fully active white-on-band pills
(pixel-identical to the working 2-dog state) while a real tap on them is a verified **no-op**
(`__bra_showcase_spotlit` stays `labrador` across `next`/`next2`) because the showcase only
spotlights **owned** breeds and there is just one. Two prominent controls read as live, and
the hint actively instructs the player to use them, yet they do nothing — a wrong empty-state /
mild dead-end that undercuts the polish 163 just brought to this surface.

## Fix

When the owned roster has **≤ 1** breed, make the chevron state honest and drop the
arrow instruction from the hint. With **2+** owned dogs the chevrons stay fully active and
cycle exactly as today.

- New pure static predicates on `BreedShowcaseView` (testable without a render):
  - `chevrons_active(owned_count: int) -> bool` → `owned_count > 1`
  - `hint_text(owned_count: int) -> String` → the multi-dog «Bla med pilene eller trykk en
    hund» when `> 1`, else a single-dog line that does **not** instruct a no-op
    («Adopter flere hunder for å bla» — explains why there are no arrows).
- `_refresh()` hides the ◀ ▶ buttons (`_prev_btn.visible`/`_next_btn.visible = chevrons_active(...)`)
  and sets `_hint.text = hint_text(_entries.size())`.

### Before (`_refresh`, no roster-size awareness; `_hint` text baked once in `_build_ui`)
```gdscript
# _build_ui
_hint.text = "Bla med pilene eller trykk en hund"
# _refresh — chevrons always active, hint never changes
```

### After
```gdscript
# _refresh
var multi := chevrons_active(_entries.size())
_prev_btn.visible = multi
_next_btn.visible = multi
_hint.text = hint_text(_entries.size())
```

## Acceptance criteria

- [ ] TDD: `test_breed_showcase_view.gd` gets failing tests first, then green:
  - [ ] `chevrons_active(1) == false`, `chevrons_active(2) == true` (pure)
  - [ ] `hint_text(1)` contains no "pilene" (no arrow instruction); `hint_text(2)` == the multi-dog hint
  - [ ] a 1-entry rendered view has `_prev_btn.visible == false` and `_next_btn.visible == false`
  - [ ] a 2-entry rendered view has both chevrons visible
- [ ] Existing showcase tests (tofu/chevron/contrast/wiring) stay green
- [ ] `nix develop -c bash verify.sh` → verify gate green
