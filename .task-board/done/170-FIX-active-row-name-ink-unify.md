# 170 — FIX: completion-menu active-row NAME ink unified onto the dark current-state ink (PO father-pass-35, X-4)

**Source:** `.docs/specs/po-review.md` — PO Review 2026-07-07 (father pass 35).

## Directive (verbatim intent)

167 unified the active-row *wash*, 168 unified the trailing *badge* ink across all
four completion-menu selection sections (tricks · breeds · marker-words · difficulty).
The last un-unified piece: the active row's **primary NAME**. The active **trick**
«Sitt» draws in the dark current-state ink `ROW_ACTIVE_INK` #141c26 (sampled (21,29,39)),
while the active **breed/marker-word/difficulty** names draw in `BLUE_INK` #2a66b3
(sampled (42,102,179) on the active Labrador). So on the same card the active trick's
name is dark charcoal and the active breed's name is action-blue.

**Fix:** repoint the active-row NAME token of the breed/word/difficulty sections to the
shared dark `ROW_ACTIVE_INK`, matching the trick row — so on the pale-blue active-row
wash all four sections render **dark name + dark badge** identically.

Constraints:
- Do NOT touch AVAILABLE/LEARNED/UNLOCKED/IDLE (non-active) row names — those sit on the
  cream wash and stay `BLUE_INK`/`SLATE` for AA.
- Keep the wash (167) and the badge ink (168) exactly as they are.
- Only the active-row NAME, on the pale-blue wash, where dark reads ≥14:1.

## Wrinkle

`WORD_NAME_ACTIVE` is reused for the word row's leading differentiation **pip** (`:1031`)
and a cooling-word name fallback (`:1046`), not just the name. To touch *only* the name:
- decouple the pip into a dedicated `WORD_PIP_ACTIVE := BLUE_INK` so the pip stays as-is;
- make the cooling (resting) active-word name a dim of the SAME now-dark ink so it doesn't
  hue-flip between active and cooling.

## TDD

Extend `tests/test_trick_menu_active_badge.gd` (or a sibling) asserting the active
breed/word/difficulty NAME token == `ROW_ACTIVE_INK` (== the active trick name ink), and
that they clear AA on the active-row wash.

## Verify
- `nix develop -c bash verify.sh` green.
- In-pixel at dsf3: the active Labrador name reads dark charcoal, matching «Sitt».
