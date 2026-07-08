# 184 — FIX: unify breed-showcase active-dog status label onto «Trener nå»

**Source:** PO father-pass-57 (`.docs/specs/po-review.md`, 2026-07-08, HEAD `f9f011e`) — ONE
buildable X-6 directive.

## Directive (verbatim intent)

The breed-showcase active-dog (disabled) commit button says **«Trener denne»** while its
sister dog-selection surface, the kennel modal, says **«Trener nå»** for the *identical*
"this is the dog you are currently training" state. Same-semantic-worded-differently — the
class the 151→152 unification arc closed for the four completion-menu selection sections
(tricks · breeds · words) + the kennel modal.

*What good looks like:* change the showcase active-dog label **«Trener denne» → «Trener nå»**
(`breed_showcase_view.gd:412`) so all five current-item surfaces speak one status word.
Keep the enabled action label **«Tren denne»** unchanged (action = «Tren …», status =
«Trener nå», mirroring the kennel switch «Tren med [navn]»). Copy unification only — no
fill / AA / behaviour / motion change (the pale disabled pill + dark ink already match the
151 treatment per 163).

## Plan (TDD)

1. Extract the commit label to a pure static `BreedShowcaseView.commit_label(is_active)` so
   the wording is unit-testable (mirrors `TrickMenu.BADGE[State.ACTIVE]`).
2. Failing test: `commit_label(true) == "Trener nå"` (matches `TrickMenu.BADGE[State.ACTIVE]`
   and `kennel_screen` «Trener nå»), `commit_label(false) == "Tren denne"`.
3. Repoint line 412 onto `commit_label(is_active)`; update the surrounding doc comments off
   «Trener denne».
4. Verify gate green; Visual Review of the showcase on the active dog (label reads «Trener nå»).

## Notes
- Pure copy/token unification; disabled fill (`commit_disabled_fill()`) + dark ink from 163
  stay untouched. No behaviour change.
