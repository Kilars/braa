# 173 — FIX: surface the adopted dog's individual kennel name (Bella) on the breed showcase + completion-menu breeds row

**Source:** PO father-pass-38 (`.docs/specs/po-review.md`, 2026-07-08) X-4 directive.

## The problem (PO, in-pixel on the live licensed rig)

The same owned starter dog carries **two different names** across surfaces:

- **Kennel** names her «Bella» (`KennelDog.dog_name`) — every dog leads with its individual name.
- **Breed showcase** header + spotlit pip and the **completion-menu breeds row** label her only by
  BREED, «Labrador» (`BreedPersonality.display_name`).

So "the moment you adopt a named dog and start training her, the game forgets her name." The two
"here is MY dog, shown off" surfaces (kennel + showcase) disagree on what the dog is even called.

## Root cause (verified in code)

Two parallel roster systems coexist and were never unified:

- `_roster` (BreedRoster) + `BreedPersonality` (ids `labrador`, `chocolate_labrador`, `display_name`
  «Labrador»/«Brun lab») drive the **showcase** (`_render_showcase`, `main.gd:2106`) and the
  **completion-menu breeds row** (`_breed_rows`, `main.gd:2354`).
- `_kennel_roster` (KennelRoster) + `KennelDog` (8 named individuals, `dog_name` «Bella»…) drive the
  **kennel** and the **actual trained dog** (`_apply_active_kennel_dog` → `KennelDog.to_personality()`).

Kennel adopt/switch touch **only** `_kennel_roster`; the showcase/menu breeds section still read the
legacy `_roster`. Unifying the two roster systems is a large, risky refactor of signed-off Phase-3/6/8
surfaces and is **out of scope**. The PO decided the direction (show individual names), so this is a
bounded **display-only** fix — no roster / economy / adoption change.

The one honest cross-system link the player actually reaches is the **starter**: legacy breed
`labrador` ↔ kennel individual `bella`. A breed with no kennel individual (`chocolate_labrador`,
adopted only via the legacy breeds-menu) keeps its breed name — it is genuinely a breed variant, not
an adopted named individual, so showing the breed there is honest.

## What "good" looks like (PO)

Surface the adopted dog's individual kennel name (Bella) on the surfaces that currently show only the
breed, **with the breed kept as a secondary subtitle** («Bella» title, «Labrador» beneath), reusing
`KennelDog.dog_name`. Keep the 172 pose, 171 chrome, 087/163 re-tint exactly as they are.

## Plan (display-only, TDD where pure)

1. **`KennelDog.name_for_breed(breed_id) -> String`** (pure, TDD): a small explicit, data-driven
   `BREED_TO_DOG` map (`{"labrador": STARTER_ID}`) → the individual `dog_name`, or `""` when the breed
   has no kennel individual. One-line add for a future breed↔dog link.
2. **Showcase** (`main._render_showcase` + `breed_showcase_view.gd`): each entry carries
   `name` = individual name if resolved else breed, plus `subtitle` = breed when an individual name is
   shown. The big name label shows the individual name; a new dimmed subtitle label beneath shows the
   breed; pips show the individual name (already read `entry.name`).
3. **Completion-menu breeds row** (`main._breed_rows` + `TrickMenu.classify_breeds` + `_draw_breed_row`):
   thread a `subtitle`; the active/owned row shows «Bella» with a dimmed «Labrador» beneath (mirrors the
   word-row two-line name+cost-hint pattern). Rows with no individual name stay single-line.

## Done when

- `KennelDog.name_for_breed` unit-tested (starter → «Bella», unmapped → «»).
- Showcase header + pip read «Bella», breed «Labrador» beneath; menu breeds row likewise.
- `verify.sh` green; Visual Review (phone-portrait) confirms the showcase + menu read the individual
  name with the breed as subtitle, 171/172 intact, no regression.

## Done (2026-07-08)

- `KennelDog.name_for_breed()` + `BREED_TO_DOG` bridge (starter `labrador`→«Bella», unmapped→«»);
  2 TDD asserts in `test_kennel_dog.gd`.
- **Showcase** (`main._render_showcase` + `breed_showcase_view.gd`): entries carry `name`/`subtitle`;
  new `_subtitle_label` + `_subtitle_of`; top band `TITLE_H` 92→116 so the breed subtitle seats on the
  dark band (legible white-on-ink), not the bright sky. 2 view tests.
- **Completion-menu breeds row** (`main._breed_rows` + `TrickMenu.classify_breeds` + `_draw_breed_row`):
  subtitle threaded; two-line name+dimmed-subtitle (mirrors the word-row cost-hint layout). 1 test.
- 789 tests (+5), verify gate GREEN. Visual Review PASS (`.screenshots/P173-01-menu.png` reads «Bella»
  / «Labrador» / «Aktiv»; `P173-02-showcase.png` top band «Bella — aktiv» + «Labrador» subtitle, pip
  «Bella»). Display-only — no roster / economy / adoption change; 171/172/087/163 intact. «Brun lab»
  (no kennel individual) correctly stays single-line by its breed name.
