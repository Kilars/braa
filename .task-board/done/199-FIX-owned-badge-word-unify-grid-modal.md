# 199 — Unify the owned-dog corner-badge WORD across kennel grid ↔ inspect modal (PO father-pass-74 X-6)

**Type:** FIX / DS-consistency (X-6)
**Source:** `.docs/specs/po-review.md` — PO father pass 74 (2026-07-09), the lone new buildable directive.

## The defect (PO-verified in pixels)

The identical green ownership corner-badge component renders **two different words** for the
same owned dog (Bella) across two surfaces:
- **Grid cell** badge → «Din hund» (`P74b-grid-badge.png`)
- **Inspect modal** hero badge → «Din» (`P74b-modal-badge.png`)

Same green pill, same top-left corner, same dog. Root cause is a real code divergence:
- Grid draws the badge from the classified row's `status_label` (`kennel_dog.gd` → «Din hund»).
- Modal synthesizes a row that **forces `status_label: ""`** (`kennel_screen.gd:1319-1326`),
  dropping the ownership word down the `rarity_label` path → owned resolves to «Din».

Same class of defect the pass-72 fix (task 198) closed for the «Trener nå» pill — a shared
status component that drifted between surfaces. Novel: 148 introduced the rarity badge, 149
de-duped the redundant owned *price* pill, but no pass unified this badge *word*.

Scope: the **single owned case**. Secret (Trulte «Påskeegg») already renders on both, and all
buyables («Vanlig»/«Sjelden»/«Episk») already match — do not touch those.

## Fix

Modal `rtag` synthesis passes the detail row's real `status_label` through instead of hardcoding
`""`, so owned → «Din hund» (matches grid), secret → «Påskeegg» (unchanged), buyables → "" →
`rarity_label` (unchanged). One source of truth, can't drift again — the point of the DS lever.

Keep: green ownership hue, dark-ink AA (149), corner position, pill shape. Only the word aligns.

## TDD

New `tests/test_kennel_owned_badge_word.gd`: owned modal corner badge reads «Din hund» (== the
grid's `status_label`); secret + buyable modal badges unchanged (regression guard).

Verify gate green (import·boot·test·export).
