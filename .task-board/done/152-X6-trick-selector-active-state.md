# 152 — X-6: trick selector gets an ACTIVE state (mark the currently-trained trick)

**Source:** PO father-pass-16 (`70183fc`), `.docs/specs/po-review.md` Improvement 1.

## Problem
The completion/pause **Triks** menu is the ONE selection surface with no "active/current"
state. The trick you're training (HUD says Sitt) renders identically to the other
selectable tricks (same pale pill + «Tilgjengelig»/«Lært» badge) and tapping it silently
no-ops (`select_trick` early-returns on `id == _current_trick`, main.gd:2541). Its siblings
all mark the running item: breeds `BreedState.ACTIVE`, words `WordState.ACTIVE`
(trick_menu.gd:47-56), kennel modal «Trener nå» (151).

## Fix (buildable, no owner asset)
1. `trick_menu.gd`: add `State.ACTIVE` to the `State` enum + `BADGE[State.ACTIVE] = "Trener nå"`
   (kennel wording). ACTIVE is muted, non-tappable, absorbs its tap — `is_selectable` stays
   false for it (so `id_at` returns "" and `_gui_input` already absorbs a non-selectable trick row).
2. `classify(all_ids, performable, mastered, locked, active := "")` — a new optional `active`
   arg: a performable, non-locked id equal to `active` reads `State.ACTIVE` (takes precedence
   over LEARNED/AVAILABLE so a mastered active trick no longer reads plain «Lært»). Default ""
   keeps every existing caller/test unchanged.
3. `_draw_row`: draw the ACTIVE row in the 151 style — dark `C_TAG_INK` (#141c26) name + badge
   on a muted wash (`ROW_BG_ACTIVE`, an opaque pale-blue wash) → clears WCAG AA, reads as the
   confident "this is your current trick" row, NOT a live pressable button.
4. `main._menu_rows()` (main.gd:2315): pass `_current_trick` into `classify`.

## Tests (TDD, in test_trick_menu.gd)
- classify with `active=SITT` → SITT reads ACTIVE (even when mastered), others unchanged.
- `is_selectable(State.ACTIVE)` is false.
- `BADGE[State.ACTIVE] == "Trener nå"`.
- AA: `C_TAG_INK` on `ROW_BG_ACTIVE` ≥ 4.5:1.

## Guardrails
Do NOT make the active row look like a live pressable button; don't change the
Learned/Available/Locked rows or the breed/word/difficulty sections.
