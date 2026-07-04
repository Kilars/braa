# 092 — FEATURE — P5-4 load/swap the active marker word (no second verb)

**Type:** FEATURE (UI / interaction + logic) · **Phase:** 5 — **CURRENT**
**Story:** P5-4 — *As a player, I want to load/swap the active word outside the tap, so that
the round stays one tap.* Acceptance: selection via **chip cycle or swipe the BRA marker** —
**never an extra in-round button**.

**Depends on 091** (the `MarkerWords` catalog + `PayoffPlayer.set_active_word`). Build after 091 lands.

## What this addresses (spec gap)

After 091, words unlock and the active word fires, but the player has **no way to choose** which
unlocked word is active. P5-4 gives that control **outside the round** so X-2 ("one verb, always")
holds — no second in-round button. The lowest-risk, most cohesive home is the existing
completion/`TrickMenu`, which already houses a **Tricks** section and a **Breeds** section
(Active / Switch / Adopt / Locked rows). A new **"Marker words"** section mirrors that exactly.

## Why prioritized now

Makes 091's unlock meaningful and player-facing — without it, unlocking words has no visible
effect. It reuses the proven, unit-locked `TrickMenu` row/classifier pattern (Breeds section), so
it is well-scoped and low-risk. Interaction/logic, not pure visual polish (so it clears the
visual-domain-saturation filter this round).

## Route decision — menu section, NOT swipe

P5-4 permits *either* a chip cycle *or* a swipe on the BRA marker. The BRA marker is a plain
`Button` (`main.gd:1236`, `pressed` only) — there is **no** existing gesture/drag handling
anywhere, and adding drag detection risks colliding with the `pressed` signal and the anti-mash
`TapGate`. The **in-menu chip/row** route reuses the existing Breeds-section machinery and keeps
the round one tap. Choose the menu route. (This is distinct from the retired always-on *trick*
chip selector the memory warns against — that was an always-visible in-play row; this is a
row inside the modal menu, opened outside the round.)

## Technical approach

### A. `TrickMenu` — add a "Marker words" section (mirror the Breeds section)

`scripts/trick_menu.gd` is a **dumb renderer** fed rows by `main`, with each optional block
returning **zero height when empty** so trick-only geometry is unchanged. Add, symmetric to the
Breeds block:

```gdscript
enum WordState { ACTIVE, UNLOCKED, LOCKED }     # active word, a switchable unlocked word, a locked word

signal word_chosen(id)                          # new — mirrors breed_chosen

func set_words(words: Array) -> void            # rows: [{id, display, state}]
func classify_words(catalog: Array, unlocked: Array, active: String) -> Array   # pure, unit-tested
func _words_block_h() -> float                  # 0.0 when no words fed (keeps trick-only layout)
func _word_row_rect(i: int) -> Rect2
func _draw_word_row(row) -> void                # "Marker words" subheading + one row per word
```

- Insert `_words_block_h()` into `_panel_rect` height and the top-offset chain (place the section
  between the trick rows and the Breeds section, or between Breeds and the footer pills — keep it
  above the "Keep training" close button).
- In `_gui_input`, route a press on an **UNLOCKED** (non-active) word row → `word_chosen(id)`;
  ACTIVE and LOCKED rows are absorbed (no-op), exactly like the breed ACTIVE/LOCKED handling.
- Show locked words honestly greyed (never faked as available), mirroring the locked-breed row.

**TDD (pure classifier first):** `tests/test_trick_menu.gd` (or the existing menu test) —
`classify_words` marks the active word ACTIVE, other unlocked words UNLOCKED, catalog words not
in `unlocked` LOCKED; order follows the catalog; empty `unlocked` beyond base still shows base as
ACTIVE. Write red first, then implement.

### B. `main.gd` — feed the section + handle the tap (mirror `_on_breed_chosen`)

- In `_refresh_trick_menu()` (which already calls `set_rows` + `set_breeds`), add
  `_menu.set_words(_menu.classify_words(MarkerWords.CATALOG, _words.to_dict()["unlocked"], _words.active()))`.
- Wire the new signal in `_setup_trick_menu` and add the handler:

```gdscript
# mirrors _on_breed_chosen (main.gd:1654) — swap active word, persist, refresh, keep round one-tap
func _on_word_chosen(id: String) -> void:
	if not _words.set_active(id):
		return
	_payoff.set_active_word(_words.active())
	_refresh_trick_menu()          # reflect new ACTIVE row immediately
	_save_progress()
```

Keep the menu **open** after choosing a word (like adopt) so the player can see the active row
update — do NOT close (closing is for trick-select). The reopen "Tricks" button already exists.

## Visual Review (phone-portrait 390×844)

Drive the real running build (headless Chromium over the local web bundle, `tools/web_capture_*`
pattern): open the menu, confirm the **Marker words** section lists base "bra" (ACTIVE) plus any
unlocked words; tap an unlocked word → its row becomes ACTIVE and "bra" becomes switchable; the
next successful mark plays the newly-active word's clip. Locked words render honestly greyed. No
layout regression to the Tricks/Breeds sections (block-height-zero-when-empty preserved). Capture
frames under `.screenshots/092-*`.

## Definition of done / Acceptance criteria

- [x] `TrickMenu` renders a "Marker words" section (subheading + one row per catalog word: ACTIVE / UNLOCKED / LOCKED), honest greying for locked, zero height when no words fed.
- [x] **TDD:** `classify_words` tested red→green (active/unlocked/locked partition, catalog order, non-empty assertions).
- [x] Tapping an unlocked non-active word emits `word_chosen(id)`; ACTIVE/LOCKED rows absorbed.
- [x] `main._on_word_chosen` swaps the active word, re-points the payoff clip, persists, refreshes the menu (stays open); no in-round button added (X-2 holds).
- [x] Selection persists across a same-origin reload (rides 091's `words` blob).
- [x] **Visual Review PASS** on the real build at 390×844 (frames `.screenshots/092-*`), verified by eye; existing Tricks/Breeds sections unregressed.

  **Visual Review (orchestrator, 2026-07-04):** PASS. `tools/web_capture_words.mjs` (new) drove the real web
  bundle in headless Chromium at 390×844 with all-real canvas taps: autotap mastered Sitt → the menu popped
  with "dyktig" unlocked → the **Marker words** section renders correctly under Breeds, fully on-screen —
  `Bra!` ACTIVE (gold), `Dyktig!` switchable, `Flink!/Super!/Kjempebra!` honestly greyed LOCKED
  (`.screenshots/092-01`). A real tap on the Dyktig! row swapped active bra → dyktig (`__bra_active_word`
  flipped), the ACTIVE highlight moved, `Bra!` became switchable, menu stayed open (`.screenshots/092-02`).
  No layout regression. Added a `__bra_word_rows`/`__bra_active_word` capture seam + `word_count/word_row_center/word_id`
  accessors (mirroring the breed seams) for the honest-tap proof.
- [x] `nix develop -c bash verify.sh` green.
- [x] Placeholder-check clean (no un-allowlisted stub markers in the diff).
