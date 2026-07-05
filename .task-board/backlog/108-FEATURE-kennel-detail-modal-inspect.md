# 108 — FEATURE: Kennel detail/inspect modal (Phase 8 K-2, + K-8 trick list)

**Type:** FEATURE (TDD for the detail data → then **Visual Review** for the modal render)
**Phase:** 8 (Kennel — current)
**Stories:** K-2 (inspect a dog), K-8 (trick list shown before adopt). Sets up K-3/K-4 (adopt).
**Depends on:** 104 (`classify_kennel_dogs`), 105 (`dog_selected(id)` signal, grid scroll).
**Source:** PO Review 2026-07-05, Change 3 — first spine story (inspect). Adopt/switch/persist
(K-3/K-4/K-5/K-6/K-7) land in the next task on top of this modal.

## What this addresses

The kennel is browse-only: tapping a cell emits `dog_selected(id)` **into a no-op**. The inspect
half of the phase's core loop (*inspect → afford → adopt → train-with → remember*) doesn't exist.
This builds **K-2**: tap a cell → a detail modal with the dog's blurb, 4 stat bars, raseegenskaper
chips, its one Unikt trekk, and (per **K-8**) the breed's trick list — the information a player needs
to judge a dog **before** adopting. It is **inspect only** — no adopt button press wiring yet (K-4);
this task deliberately does not mutate coins/roster/save, so it stays low-risk and reviewable on its
own.

## Why now

- It's the first story of the phase's unbuilt interactive spine and the **container** the adopt
  button (K-3/K-4) will live in — building it first unblocks the adopt task cleanly.
- Self-contained, PO-reviewable slice (a closable detail card), no economy mutation.

## Technical approach

**Two parts: (1) test-first detail data on `KennelDog`, (2) the modal renderer (Visual Review).**

### 1. Detail data (TDD — `tests/test_*` first)

The modal needs data the model doesn't carry yet: a **blurb** (one warm line) and **raseegenskaper
chips** (2–3 short breed-trait words) per dog. Stats (4×1–5), `unique_trait`, and `trick_ids` already
exist. Extend the `DOGS` table + `_from_row` + `classify_kennel_dogs` rows with `blurb: String` and
`traits: Array` (chips), transcribed per dog (kept in the same literal table so a typo fails a test).
Add a `detail_for(id)` (or extend the classify row) returning everything the modal reads.

**Tests (RED first):**
- `test_each_dog_has_a_blurb_and_traits` — every one of the 8 dogs has a non-empty `blurb` and ≥1
  trait chip (guards a missing transcription).
- `test_detail_row_carries_stats_trait_and_trick_list` — the detail data for a known id exposes the
  4 stats, the `unique_trait`, and the `trick_ids` (K-8: the trick list is inspectable pre-adopt).
- `test_detail_for_unknown_id_falls_back_to_starter` — mirrors `by_id`'s no-dog-less-resolve contract.

Reference the `tdd` skill for red-green-refactor.

### 2. Modal renderer (Visual Review — `scripts/kennel_screen.gd` or a `kennel_detail_modal.gd`)

Per phase8.md "Detail modal + stat panel":
- **Overlay**: a dim backdrop `rgba(20,28,38,.5)` (a `ColorRect`) + centered card (`PanelContainer`,
  radius 24, surface `#fbfbf7`). Mount on the same CanvasLayer as the grid, above it.
- **Header image** (~150px): same per-dog tint + steel bars as the cell band (reuse `_make_band`'s
  pieces / the baked portrait from 107 if landed — else the tint band; do not block on 107).
- **Blurb** — one warm line (Nunito).
- **4 stat rows** — Læreevne · Energi · Mot · Fokus, each a label + **5 pips** (filled `#4a90e2`,
  empty `#dfe5ea`) driven by the 1–5 stat. Pips drawn as small rounded `ColorRect`s / `_draw` — no
  font glyphs (no tofu).
- **Raseegenskaper chips** — the `traits` words as small pill chips.
- **Unikt trekk** — the warm-cream card (`unique_trait`).
- **Trick list (K-8)** — the breed's `trick_ids` shown as a small labelled row ("Kan lære: Sitt ·
  Ligg · Legg deg"), so the trick list is part of the adoption decision **before** adopt.
- **Adopt button placeholder is OUT of scope** — do **not** render a dead/no-op «Adopter» button
  (that's exactly the browse-only no-op the PO objected to). Leave a clearly-commented mount point /
  `_build_adopt_button()` seam the K-4 task fills. The modal this task ships is a complete **inspect**
  card; the adopt button arrives wired in K-4.
- **Close**: tap the ✕ **or** the dim backdrop closes the modal and **preserves grid scroll**
  (don't rebuild the grid on close — just hide/free the overlay). Reduced-motion respected (X-5):
  backdrop fade + card scale-from-0.96 with overshoot, skipped when `ReducedMotion.query()`.
- **Wire**: `main._on_kennel_dog_selected(id)` (currently a no-op log) opens the modal for `id`;
  the modal's `closed` signal returns to the grid.

**Headless care:** guard `.play()`/tween on `is_inside_tree()`; the modal must build lazily so a
headless wiring test can assert it opens for a tapped id without a running SceneTree.

### Before

```gdscript
# main.gd — the tap goes nowhere.
func _on_kennel_dog_selected(_id: String) -> void:
	pass   # detail modal lands in a follow-up task
```

### After

```gdscript
# main.gd — the tap opens the inspect modal for that dog.
func _on_kennel_dog_selected(id: String) -> void:
	_kennel.open_detail(id)      # renders blurb/stats/chips/trait/trick-list, closable

# kennel_dog.gd — detail data the modal reads (blurb + traits added to the table, TDD-guarded).
static func detail_for(id: String) -> Dictionary: ...
```

## Placeholder / tofu check

- No dead adopt button, no `TODO`-labelled no-op left in a shipped path (the adopt seam is a named,
  commented mount point the next task fills — allowlisted as "a stand-in an open task names").
- Stat pips + trick list are geometry/plain words — grep the diff for any non-theme glyph (`★`, `▶`,
  emoji): none.

## Acceptance criteria

- [ ] **TDD first:** the three detail-data tests above written RED (blurb/traits absent), then GREEN.
- [ ] Tapping a cell opens a centered detail modal over a dim backdrop with: blurb, 4 stat rows (5
      pips each, filled per the 1–5 stat), raseegenskaper chips, the Unikt trekk card, and the K-8
      trick list ("Kan lære: Sitt · Ligg · Legg deg") — shown **before** any adopt.
- [ ] ✕ **and** outside/backdrop tap both close the modal; **grid scroll position is preserved**.
- [ ] Reduced-motion (X-5) respected — no scale/fade tween when `ReducedMotion.query()` is true.
- [ ] No dead/no-op adopt button is shipped (adopt press wiring is the next task, K-4); the modal is
      a complete inspect card with a commented adopt mount seam.
- [ ] No economy/roster/save mutation in this task (inspect only).
- [ ] `nix develop -c bash verify.sh` green (import·boot·test·export).
- [ ] Visual Review PASS on the live web build (390×844, real canvas tap): modal opens smooth, stat
      panel legible, closes cleanly back to the grid at the same scroll spot; training page intact.
