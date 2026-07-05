# 118 — FEATURE — Player-facing difficulty selector (P4-1)

**Phase:** 9 (Difficulty) — **current** (Phase 8 signed off `a2eae20`).
**Story:** P4-1 "for normal dogs I want to be able to select difficulty."
**Type:** FEATURE (logic, TDD) + Visual Review (the new menu section).

## What it addresses

The difficulty **model** is fully built and wired dormant (080–082): `Difficulty`
Normal/Hard/Expert with `window_scale / tell_intensity_scale / feint_scale /
erosion_scale / reward_scale`, stacked breed×difficulty across `main.gd`
(`_setup_window` `scale_radius`, `_apply_breed_levers` `scale_feint`,
`_erosion` `scale_erosion`, `mastery_reward`), persisted on the save blob
(`TrickStore.save/load_difficulty`), reachable only via the `?bra_difficulty=`
web seam. **There is no player-facing way to change it** — the dormancy guarantee
from the work-ahead phase. Phase 9 is now current, so the selector must land: a
single **global** Normal / Hard / Expert control the player can set, applied to all
training, persisted across reloads, re-applied live without a restart.

## Technical approach

Add a **"Vanskelighet"** section to the existing completion menu (`TrickMenu`), the
same dumb-renderer pattern as the Breeds / Marker-words sections: `main.gd`
classifies the rows and feeds them via a new `set_difficulty(rows)`; the node draws
one row per mode (Normal/Hard/Expert) with the active mode marked, exposes
`difficulty_row_count()` / `difficulty_row_center(i)` / `difficulty_id(i)` for tap
routing (mirror `breed_*` / `word_*`). Tapping a mode calls a new
`main._on_difficulty_chosen(id)`:

- guard `Difficulty.is_known(id)`; no-op if already active,
- `_difficulty = Difficulty.by_id(id)`,
- re-apply the levers live (the exact calls already used on breed-switch:
  `_setup_window()` / rebuild `_tell` / `_loop.feint_chance = _difficulty.scale_feint(...)` /
  `p.set_erosion_scale(_difficulty.erosion_scale)` for each `TrickProgress`),
- persist via `_persist()` (the blob already carries `_difficulty.id`),
- refresh the menu so the new active row highlights.

Classification is a pure static on `TrickMenu` (TDD target):

```gdscript
# BEFORE — no difficulty rows exist
# (menu shows tricks, breeds, words only)

# AFTER — TrickMenu.classify_difficulty(catalog, active_id) -> Array[Dictionary]
static func classify_difficulty(catalog: Array, active_id: String) -> Array:
	var rows := []
	for d in catalog:
		var mode := d as Difficulty
		rows.append({
			"id": mode.id,
			"name": mode.display_name,
			"active": mode.id == active_id,
		})
	return rows
```

```gdscript
# main.gd — feed the section when (re)building the menu, next to set_breeds/set_words
_menu.set_difficulty(TrickMenu.classify_difficulty(Difficulty.catalog(), _difficulty.id))
```

Keep Normal the default (identity → today's feel unchanged for players who never
open the selector). Do NOT add a separate `tell_speed_scale` lever (see
`difficulty.gd` note — the tell timing follows the window).

**Special-dog lock is task 119** — this task ships the selector for the normal case;
119 disables it when the active dog locks difficulty. Build 118 so the lock hook is
a clean seam (e.g. the section still renders, rows just become non-selectable) —
don't fake the lock here.

## Acceptance criteria

- [x] RED first: `tests/test_*` for `TrickMenu.classify_difficulty` — 3 rows in
  catalog order, exactly the active id flagged `active: true`, unknown active id →
  no row flagged (falls back safe).
- [x] RED first: a `main`-level test that `_on_difficulty_chosen("hard")` sets
  `_difficulty.id == "hard"`, re-applies the window (`ok_radius` tightens vs Normal),
  and persists (reload → `load_difficulty() == "hard"`); choosing an unknown id is a
  no-op.
- [x] GREEN: selector section renders in the completion menu; tapping Normal/Hard/Expert
  switches the global mode, re-applies levers live, persists across reload.
- [x] Normal remains the boot default; a player who never opens the selector sees
  byte-identical play (no regression).
- [x] Visual Review (390×844): the "Vanskelighet" section reads clearly in the menu —
  three legible mode rows, active mode visibly marked, consistent with the Breeds /
  Marker-words sections (DesignSystem tokens, no scattered `Color(...)`); capture via
  the existing menu capture harness.
- [x] `nix develop -c bash verify.sh` green; placeholder check clean; committed + pushed.


## Outcome
SHIPPED. TrickMenu.classify_difficulty + is_difficulty_selectable (pure, unit-locked in test_difficulty_menu.gd) + a Vanskelighet section (subheading, one row per mode, active marked Valgt) with tap routing (difficulty_chosen). main._on_difficulty_chosen switches the global mode, re-applies levers live (_apply_difficulty: erosion per trick + loop feint = breed×difficulty), persists via _save_progress. Normal stays the boot default (dormancy). Verify green 630/0. Visual Review PASS (.screenshots/118-01-menu-normal, 118-02-menu-hard — tapping Hard moves Valgt off Normal onto Hard, reads consistent with Breeds/Marker-words).
