# 095 — FEATURE — P5-2 make the stronger-word trade-off legible (cost before loading + resting count)

**Type:** FEATURE (logic + render) · **Phase:** 5 — **CURRENT**
**Story:** P5-2 — *As a player, I want better words to be more effective but constrained, so that
loading one is a genuine choice, not an obvious upgrade.* Acceptance: stronger = **wider window /
bonus**, but with a **cooldown / downside**; base **bra** is always the default with **no cooldown**.

**Source:** PO Review 2026-07-04 (`.docs/specs/po-review.md`), Improvement 2 — the stronger-word
trade-off is **imperceptible in play**: the menu word rows show only Active / Switch / Locked, so
"a cost the player can't see isn't a trade-off — right now a stronger word looks like a pure win."
Depends on 093 (cooldown model already in `MarkerWords`). **Ship together with 094** (the fired-word
pop makes the cooldown *fallback* visible in play; this makes the cost readable at the *decision*).

## What this addresses (spec gap)

093 built the cooldown **mechanic** (a stronger word widens the PERFECT window but rests for N marks
after firing, falling back to `bra`), and the menu view (`_draw_word_row`) already renders a
`"Hviler"` badge for a **cooling active** word. But two gaps remain, both flagged by the PO:

1. **The cost is invisible at the decision point.** An UNLOCKED (not-yet-active) word row shows only
   `"Switch"` — nothing tells the player that loading it *widens the window but incurs a cooldown*.
   P5-2 asks that loading a stronger word be "a genuine choice, not an obvious upgrade"; today it
   reads as a pure win because the downside is off-screen until *after* you've already loaded and
   fired it.
2. **The resting badge has no magnitude.** `"Hviler"` says a word is resting but not for **how many
   marks**, so the player can't gauge the size of the cost.

This makes the trade-off legible **where the player decides** (the menu), so choosing a word is an
informed weigh-up of *wider window* vs *rest cost*.

## Why prioritized now

It is the PO's #2 buildable Phase-5 directive and the second sign-off blocker. It is small, mostly
menu-render + one pure accessor, and completes the P5-2 story the PO judged "illegible in play." The
PO explicitly asked to ship it **with** 094 (the pop) so that the player both *sees the stronger
word fire* (094) and *sees it rest / weighs the cost* (095). Logic domain is not blocked here — this
is menu legibility, the direct current-phase gap.

## Technical approach

### A. Expose the remaining-rest count (TDD) — `MarkerWords.cooldown_remaining(id)`

The model already tracks `_cooldown_remaining` (id → marks left) and exposes the bool
`is_on_cooldown(id)`. Add the pure integer accessor the menu needs to show a count:

```gdscript
# BEFORE — only the bool exists:
func is_on_cooldown(id: String) -> bool:
    return _cooldown_remaining.get(id, 0) > 0

# AFTER — add the magnitude accessor beside it:
## Marks of rest still owed by `id` before it is available again (093, P5-2). 0 = available.
## A word never in the dict has 0 remaining. Pairs with is_on_cooldown for the menu's "Hviler (n)".
func cooldown_remaining(id: String) -> int:
    return maxi(0, _cooldown_remaining.get(id, 0))
```

**Behaviors to test first (`tests/test_marker_words.gd`, red→green):**
- fresh word: `cooldown_remaining(id) == 0`.
- after `fire_active(true)` on a stronger word: `cooldown_remaining(id) == cooldown(id)`.
- each subsequent successful mark decrements it by 1 down to 0 (matches `is_on_cooldown` flipping false).
- base "bra" is always `0` (never cools down).
- consistency: `is_on_cooldown(id) == (cooldown_remaining(id) > 0)` across the fire/decrement cycle.

### B. Enrich the menu word rows with the trade-off data (TDD — pure `classify_words`)

`TrickMenu.classify_words` currently returns `{id, display, state}`. Enrich each row with the
per-word trade-off so the view can advertise it **before loading** — a pure change, unit-locked in
`tests/test_trick_menu.gd`:

```gdscript
# BEFORE — rows carry only id/display/state:
rows.append({"id": id, "display": display, "state": st})

# AFTER — carry the effect + constraint so the view can show the cost on every stronger word:
rows.append({
    "id": id, "display": display, "state": st,
    "window_scale": catalog_window_scale,   # e.g. 1.20  (from the catalog entry)
    "cooldown": catalog_cooldown,           # e.g. 2     (marks of rest the word costs)
})
```

`_word_rows()` in `main.gd` already appends `cooling` per row; extend it to also append the live
`remaining := _words.cooldown_remaining(id)` so the view can render `"Hviler (n)"`. (Keep the catalog
`window_scale`/`cooldown` sourced in `classify_words` from `MarkerWords.CATALOG`, and the live
`cooling`/`remaining` sourced in `_word_rows` from the instance — the same split 093 used.)

**Behaviors to test first (`tests/test_trick_menu.gd`):**
- `classify_words` marks a stronger word's row with its catalog `window_scale > 1.0` and `cooldown > 0`.
- base "bra" row carries `window_scale == 1.0` and `cooldown == 0` (no cost hint shown for it).

### C. Render the cost + resting count (`trick_menu.gd._draw_word_row`) — Visual Review

Extend the existing row renderer (which already handles ACTIVE/UNLOCKED/LOCKED + the `cooling`
"Hviler" badge). Two additions, kept legible and uncluttered on a phone row:

- **Cost hint on stronger words** (any word with `cooldown > 0`), shown on UNLOCKED **and** ACTIVE
  rows so the trade-off reads before *and* after loading — e.g. a small secondary line / suffix like
  `+20% · hviler 2` (wider window · rest cost). Base "bra" (`cooldown == 0`) shows **no** cost hint —
  it is the plain always-available default, reinforcing "bra is the free baseline."
- **Resting count**: when the ACTIVE word is cooling, the badge reads `"Hviler (n)"` using the live
  `remaining` (was a bare `"Hviler"`), so the size of the cost is legible.

```gdscript
# BEFORE — cooling badge with no count:
if st == WordState.ACTIVE and cooling:
    word_badge = "Hviler"

# AFTER — show remaining marks:
if st == WordState.ACTIVE and cooling:
    word_badge = "Hviler (%d)" % int(w.get("remaining", 0))
```

Keep the palette/geometry consistent with the breeds-section cost read (079's `Adopt 30` style):
the cost is informational, dimmed relative to the name, never a new button. Do **not** widen the
panel or add an in-round verb (X-2 / P5-4 hold).

### D. No new in-round surface

All of this lives in the completion menu (092's Marker-words section) — the between-rounds decision
surface. No in-round button, no change to the one-tap round (X-2). 094 handles the in-round *pop*;
this is purely the menu-side legibility of the cost.

## Definition of done / Acceptance criteria

- [x] `MarkerWords.cooldown_remaining(id) -> int` added; **TDD** §A behaviors red first in `tests/test_marker_words.gd`, then green (each test ≥1 real assertion).
- [x] `TrickMenu.classify_words` enriches each row with catalog `window_scale` + `cooldown`; **TDD** §B in `tests/test_trick_menu.gd` (stronger word carries the cost; base "bra" carries 1.0/0).
- [x] `_word_rows()` (main) appends live `remaining` (and keeps `cooling`) so the view can show the count.
- [x] Menu word rows show the stronger-word **cost before loading** (a wider-window + cooldown hint on any word with `cooldown > 0`); base "bra" shows **no** cost hint (plain always-available default).
- [x] A cooling ACTIVE word's badge reads **"Hviler (n)"** with the live remaining count (was a bare "Hviler").
- [x] No in-round button added and the panel is not widened; X-2 / P5-4 hold (selection stays in the menu).
- [x] **Visual Review PASS** at 390×844 (`.screenshots/095-01-cost-before-load.png`, `095-02-dyktig-active.png`): the menu's Marker-words section shows **Dyktig!** carrying the cost hint **"+15% · hviler 2"** below its name (dimmed) while UNLOCKED — the cost is readable **before loading** — and the same hint on the ACTIVE row after loading; base **Bra!** carries no hint (free default), Flink!/Super!/Kjempebra! read Locked. Clean layout, no collision. Reviewed by eye. The "Hviler (n)" resting-count is a `%d` on the already-PO-confirmed "Hviler" badge path (093) fed by the unit-tested `cooldown_remaining` decrement — deterministically locked, so no separate cooling-state pixel run was spent.
- [x] `nix develop -c bash verify.sh` green (import → boot → test → export) — 502/0.
- [x] Placeholder-check: no un-allowlisted stub markers in the added `scripts/`/`assets/` diff (grep CLEAN; "hviler" is real Norwegian, allowlisted as UI copy).

## Implementation notes

- The renderer already supports the `cooling` field and the dimmed-gold "Hviler" treatment (093);
  this task adds the **count** and the **pre-load cost hint** — mostly additive text, no new geometry
  home beyond what 092/093 established.
- Keep the cost string terse and Norwegian-consistent with the rest of the menu (`Hviler` = resting).
  Exact wording/format of the cost hint is the author's to make readable on a 340-px-wide row —
  the acceptance bar is that a player can weigh *wider window* vs *rest cost* **before** loading.
- Source of truth split (unchanged from 093): catalog constants (`window_scale`, `cooldown`) come
  from `MarkerWords.CATALOG` via `classify_words`; live state (`cooling`, `remaining`) comes from the
  `MarkerWords` instance via `_word_rows`. The view stays a dumb renderer.

## Resolution (DONE 2026-07-04)

Shipped. Three seams: `MarkerWords.cooldown_remaining(id) -> int` (marks of rest owed);
`TrickMenu.classify_words` rows now carry catalog `window_scale` + `cooldown` (sourced from the entry,
not a new instance); `main._word_rows()` appends the live `remaining` alongside `cooling`. The view
(`_draw_word_row`) draws a dimmed cost hint `"+15% · hviler 2"` below the name for any stronger word
(cooldown > 0) on UNLOCKED and ACTIVE rows so the trade-off reads before AND after loading; base "bra"
(cooldown 0) shows none; the cooling-active badge now reads **"Hviler (n)"** with the live count.

- **TDD:** 7 red-first tests (5 in `test_marker_words.gd` for `cooldown_remaining`, 2 in
  `test_trick_menu.gd` for the row enrichment) → green.
- **Verify:** `✓ verify gate green` — **502/0**, no SCRIPT ERRORs.
- **Visual Review PASS** (`095-01`/`095-02`): the "cost before loading" hint pixel-proven on Dyktig!.
- Paired with 094 per the PO ("ship together"): 094 makes the cooldown *fallback* visible in play (the
  pop reads "Bra!" when a stronger word rests), 095 makes the *cost* legible at the menu decision point.
- No in-round verb, panel not widened (X-2 / P5-4 hold). Placeholder-clean.
