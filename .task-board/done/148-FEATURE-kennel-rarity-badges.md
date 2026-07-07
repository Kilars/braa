# 148 — FEATURE: surface the rarity ladder on the six buyable kennel dogs (PO father-pass-12, X-4)

**Phase:** 8 (KENNEL) — signed off; this is an X-4 polish directive on the signed surface.
**Source:** `.docs/specs/po-review.md` PO Review 2026-07-07 (father pass 12), single Improvement.

## Problem
The roster is built around a rarity ladder (`enum Rarity { OWNED, COMMON, RARE, EPIC, SECRET }`
per dog in `kennel_dog.gd`), but rarity is invisible to the player for the **six buyable dogs**:
only OWNED («Din hund») and SECRET («Påskeegg») draw a corner badge. Nova (EPIC), Balder/Sol
(RARE), Pontus/Lykke/Sniff (COMMON) carry no rarity cue in the grid or the modal, so the collect
hierarchy the phase is built on doesn't land — an EPIC dog reads interchangeable with a COMMON one.

## What "good" looks like (PO)
Surface each dog's rarity as a small **text badge** reusing the **same corner-badge component** the
OWNED/SECRET cases already use. Map the enum to Norwegian labels («Vanlig» / «Sjelden» / «Episk»,
with «Din»/«Påskeegg» kept as owned/secret), place it in the grid cell (and echo near the name in
the modal), tinted to a **calm rarity accent** — NOT a return to the loud full-cell band fills the
PO removed. Buildable, no owner asset: badge component + rarity data both already exist.

## Plan
- **`kennel_dog.gd`** (TDD): pure static `rarity_label(rarity) -> String` (OWNED→"Din",
  COMMON→"Vanlig", RARE→"Sjelden", EPIC→"Episk", SECRET→"Påskeegg"); add a `rarity_label` field to
  `classify_kennel_dogs` rows and `detail_for`.
- **`kennel_screen.gd`** (Visual Review): the six buyable dogs (empty `status_label`) draw the
  rarity badge via the same corner-badge component, tinted by a calm per-rarity accent
  (COMMON→slate, RARE→calm blue, EPIC→calm violet). Owned/secret keep their existing badges. Echo a
  small rarity badge in the modal band top-left for all dogs.

## Acceptance
- [x] `rarity_label` maps all five enum values to the Norwegian labels (pure, TDD).
- [x] classify + detail rows carry `rarity_label`.
- [x] Grid: each of the six buyable dogs shows a rarity text badge with a calm accent; owned/secret unchanged.
- [x] Modal echoes the rarity near the name.
- [x] No loud full-cell band fills reintroduced.
- [x] verify gate green; placeholder grep clean.

## Outcome
- `kennel_dog.gd`: pure `rarity_label(rarity)` static + `rarity_label` field on classify/detail rows.
  3 new TDD asserts (test_kennel_dog.gd) — 702 tests, 0 failures.
- `kennel_screen.gd`: `_make_tag` generalized to one corner-badge component drawing ownership AND
  rarity — owned green «Din hund», secret coral «★ Påskeegg», every buyable dog its rarity word on a
  calm accent (`_rarity_accent`: COMMON→slate `C_STATUS_NEUTRAL`, RARE→calm blue #5b8fd0,
  EPIC→calm violet #9b7bd4). Grid draws the badge for all dogs; modal band echoes it top-left near name.
- Visual Review PASS: `105-kennel-01-grid.png` (all 8 cells read the ladder) + `140-modal-nova.png`
  (violet «Episk» echoed in the modal). Small corner badges, NOT the loud full-cell fills the PO
  removed. 146 coin prices + 147 cool-coat parity both intact (Nova cool-grey in grid and modal).
