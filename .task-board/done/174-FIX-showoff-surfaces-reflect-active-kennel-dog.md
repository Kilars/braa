# 174 — FIX: show-off surfaces name the ACTIVE KENNEL DOG, not the stale breed roster

**Type:** FIX (bug — cross-surface cohesion) · **Source:** PO father-pass-39 X-4 directive (`.docs/specs/po-review.md`)
**Phase:** signed-off surfaces (Phase 3 showcase / Phase 8 kennel cohesion). Not a phase advance.

## The bug (PO pass-39, empirical)

173 unified the dog's name across surfaces for the **starter only**. Training any of the other 7 kennel
dogs makes the two "show-off" surfaces confidently show the WRONG dog:

- Adopt Nova (grey Border collie) → «Tren med Nova». The training page correctly shows a grey Nova rig,
  and the kennel correctly badges «Nova · Trener nå».
- But the **breed showcase** spotlights that same grey rig while labelling it **«Bella — aktiv» / «Labrador»**,
  and the completion-menu **«Raser»** section marks **«Bella» «Aktiv»**.
- Published state at the point of failure: `__bra_kennel_active = "nova"` but `__bra_active_breed = "labrador"`
  and `__bra_showcase_spotlit = "labrador"`. Coat (Nova), name (Bella) and breed (Labrador) all disagree.

**Root cause:** two independent, unsynchronised rosters, last-writer-wins on the trained coat:
- `_roster` (`BreedRoster`, Phase-3) drives the showcase + «Raser» rows. `_roster.active` = a *breed* id.
- `_kennel_roster` (`KennelRoster`, Phase-8) drives the dog actually trained. `_kennel_roster.active` = a *dog* id.

`_apply_active_kennel_dog` re-tints the shared rig to the kennel dog **without** repointing `_roster.active`,
so the show-off surfaces (which read `_roster.active`) name a different individual than the one on screen.
173's `KennelDog.BREED_TO_DOG = {"labrador":"bella"}` bridge only knows the one starter.

## Fix (PO-directed: re-point the NAME SOURCE, not a new asset/economy)

The breed-showcase header + spotlit pip **and** the completion-menu active-dog marker must resolve to the
**active kennel dog** (`KennelDog.by_id(_kennel_roster.active)` → «Nova» / «Border collie») whenever the KENNEL
is the roster driving training — for all 8 dogs, not just the starter. Keep the 173 two-line name/breed
layout, the 172 pose, 171 chrome and 087/163 re-tint exactly as they are.

**Track which roster last set the trained dog** (honest last-writer): a `main._active_from_kennel` bool,
set `true` in `_apply_active_kennel_dog`, `false` in `_apply_active_breed`. Default `false` (starter boot uses
the Phase-3 breed default, per the existing K-7 boot gate at `main.gd:359-373`). This prevents a NEW mismatch
in the obscure cross-path (train Nova, then switch breed to «Brun lab» via «Raser»): that breed switch flips
the flag back to `false`, so «Raser» correctly shows «Brun lab» over the brown coat.

**Pure, testable core** — new `KennelDog.showoff_name(...)` (TDD): returns `{name, subtitle}` for a breed
entry; the active entry borrows the kennel dog's `dog_name` / `breed` when `active_from_kennel`, else the
173 `name_for_breed` bridge (breed demoted to subtitle).

**Coat coherence through showcase interactions** (Visual Review — pure 3D glue): the showcase previews breeds
by re-tinting the LIVE rig, so moving back to / dismissing onto the active dog must restore the *trained*
dog's coat, not blindly the breed coat (which today repaints a trained kennel dog — e.g. turns grey Nova
cream on «Tilbake»). New `main._active_coat_tint()` (kennel coat when `_active_from_kennel`, else `_breed`),
used in `_showcase_move` (active entry) + `_on_showcase_dismissed`.

## Technical Approach (before → after)

### 1. `scripts/kennel_dog.gd` — new pure `showoff_name` (below `name_for_breed`, ~line 158)

**After (new):**
```gdscript
## The name + breed-subtitle a "show-off" surface (breed showcase header/pip + completion-menu «Raser»
## row) should show for a legacy breed roster entry (174, PO father-pass-39 X-4). The Phase-3 breed roster
## and the Phase-8 kennel roster are independent, last-writer-wins on the trained coat. When the KENNEL is
## the roster driving training (`active_from_kennel`), the ACTIVE breed entry borrows the active kennel
## individual's NAME + BREED — «Nova» / «Border collie» — so name, breed subtitle and the coat on screen all
## agree with the kennel's «Trener nå», for all 8 dogs, not just the 173 starter. Every other entry keeps the
## 173 breed→individual bridge (name_for_breed), breed demoted to a subtitle.
static func showoff_name(breed_id: String, breed_display_name: String, is_active: bool,
		active_from_kennel: bool, active_kennel_id: String) -> Dictionary:
	if is_active and active_from_kennel:
		var kd := by_id(active_kennel_id)
		return {"name": kd.dog_name, "subtitle": kd.breed}
	var indiv := name_for_breed(breed_id)
	if indiv != "":
		return {"name": indiv, "subtitle": breed_display_name}
	return {"name": breed_display_name, "subtitle": ""}
```

### 2. `scripts/main.gd` — track the driving roster + feed both builders

Add near `_roster` (`main.gd:227`):
```gdscript
## Which roster last set the trained dog on the rig (174): the KENNEL switch («Tren med Nova») sets true, a
## Phase-3 BREED switch (`_on_breed_chosen`) sets false. Last-writer-wins mirrors the coat, so the show-off
## surfaces name the dog actually on screen. Default false: starter boot rides the Phase-3 breed default.
var _active_from_kennel := false
```
`_apply_active_kennel_dog` → set `_active_from_kennel = true`. `_apply_active_breed` → set `= false`.

`_render_showcase` (`main.gd:2105-2115`) and `_breed_rows` (`main.gd:2357-2367`) — replace the inline
indiv/shown/subtitle block with:
```gdscript
var d := KennelDog.showoff_name(id, bp.display_name, id == _roster.active, _active_from_kennel, _kennel_roster.active)
entries.append({"id": id, "name": d.name, "subtitle": d.subtitle, "tint": bp.swatch_color()})
```
(`_breed_rows` iterates `bp.id`; use `bp.id` for the entry id there.)

Add + use `_active_coat_tint()`:
```gdscript
func _active_coat_tint() -> Color:
	return KennelDog.by_id(_kennel_roster.active).coat_tint() if _active_from_kennel else _breed.coat_tint()
```
- `_showcase_move` (`main.gd:2072-2073`): `var tint := _active_coat_tint() if id == _roster.active else BreedPersonality.by_id(id).coat_tint()` then `CoatTint.apply(_dog, tint)`.
- `_on_showcase_dismissed` (`main.gd:2095`): `CoatTint.apply(_dog, _active_coat_tint())`.

## Acceptance Criteria

- [ ] **RED first** (`tdd`): add failing `test_showoff_name_*` to `tests/test_kennel_dog.gd`:
  - [ ] active + kennel-driven → `{name:"Nova", subtitle:"Border collie"}` for `showoff_name("labrador","Labrador",true,true,"nova")` (the bug case)
  - [ ] active + NOT kennel-driven (starter) → `{name:"Bella", subtitle:"Labrador"}` (173 bridge preserved)
  - [ ] NON-active entry, kennel-driven → still the 173 bridge, not the kennel dog
  - [ ] a breed with no kennel individual («Brun lab») active-not-kennel → `{name:"Brun lab", subtitle:""}`
- [ ] GREEN: `showoff_name` implemented; both `_render_showcase` + `_breed_rows` feed it.
- [ ] `_active_from_kennel` set true in `_apply_active_kennel_dog`, false in `_apply_active_breed`; boot starter default false.
- [ ] Coat coherence: `_active_coat_tint()` used in `_showcase_move` + `_on_showcase_dismissed` (no cream-repaint of a trained kennel dog).
- [ ] Visual Review: adopt Nova → «Tren med Nova» → completion-menu «Raser» reads **«Nova» «Aktiv»** (breed «Border collie» subtitle), breed showcase header **«Nova — aktiv» / «Border collie»** with a **«Nova»** pip; open+«Tilbake» leaves the dog grey (not cream). Starter path still reads «Bella»/«Labrador». «Brun lab» single-line unchanged.
- [ ] 173/172/171/087/163 intact; no roster/economy/adoption change. Placeholder check clean.
- [ ] `nix develop -c bash verify.sh` GREEN.
