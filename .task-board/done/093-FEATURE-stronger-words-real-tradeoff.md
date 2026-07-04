# 093 — FEATURE — P5-2 stronger words, real trade-off (wider window/bonus + cooldown)

**Type:** FEATURE (game logic) · **Phase:** 5 — **CURRENT**
**Story:** P5-2 — *As a player, I want better words to be more effective but constrained, so
that loading one is a genuine choice, not an obvious upgrade.* Acceptance: stronger = **wider
window / bonus**, but with a **cooldown / downside**; base **bra** is always the default with
**no cooldown**.

**Depends on 091** (`MarkerWords` catalog) and reads best after **092** (the player can actually
load a word). Build after both land.

## What this addresses (spec gap)

After 091/092, words unlock, fire, and can be loaded — but every word is cosmetically identical
in effect, so loading one is not yet the **genuine choice** P5-2 requires. This adds a per-word
**effect + constraint**: a stronger word widens the PERFECT window (or grants a bonus) **but**
carries a cooldown/downside, while base **bra** stays the always-available default with **no**
cooldown. That makes word choice a real trade-off rather than a free upgrade.

## Why prioritized now

Completes the Phase-5 "collection has depth" loop — variety (091) + selection (092) + meaningful
trade-off (093). Pure game logic, fully TDD-able, no new assets. Logic domain is not saturated in
a way that blocks a current-phase gap. Balancing is best tuned once the words exist and fire.

## Technical approach

### A. Per-word effect + constraint in the catalog (TDD)

Extend `MarkerWords.CATALOG` entries (091) with an **effect profile** — keep base "bra" identity
(no widening, no cooldown) so the Phase-1/2 feel is byte-identical when "bra" is active:

```gdscript
# each catalog entry gains: window_scale (>=1.0 widens PERFECT), cooldown_marks (int), and
# optionally a bonus (e.g. coin/score). base "bra": window_scale 1.0, cooldown_marks 0.
{"id": "bra",       ..., "window_scale": 1.00, "cooldown": 0},
{"id": "dyktig",    ..., "window_scale": 1.20, "cooldown": 2},   # tune in review
{"id": "super",     ..., "window_scale": 1.35, "cooldown": 3},
{"id": "kjempebra", ..., "window_scale": 1.50, "cooldown": 4},
# exact numbers are placeholders for TUNING, not stubs — set to defensible starting values and
# refine under play-test; document the intent in the model.
```

Add accessors: `window_scale(id) -> float`, `cooldown(id) -> int`.

### B. Cooldown model — stronger word disables itself for N marks after firing (TDD)

A pure cooldown tracker on the active-word state (or a small `WordCooldown` object). When a
stronger word fires on a successful mark, it enters cooldown for `cooldown(id)` successful marks;
while on cooldown the mark falls back to **base "bra"** (never a hard-fail, never blocks the tap —
the round is still one tap and always marks). Base "bra" never cools down.

**Behaviors to test first (TDD, red→green):**
- base "bra": `window_scale` 1.0, `cooldown` 0 — never enters cooldown; today's window unchanged.
- firing a stronger word puts it on cooldown for exactly `cooldown(id)` subsequent successful marks.
- while a stronger word is on cooldown, the effective fired word is "bra" (fallback), and the
  effective window is the base window (no widening from the cooling word).
- cooldown decrements only on successful marks (define precisely — decide and test: successful
  marks only vs. any tap; pick successful-marks and document).
- switching the active word away and back does not reset an in-flight cooldown (or does — decide,
  document, and test the chosen rule).

### C. Apply the window widening at the scoring seam

The PERFECT window comes from `SitWindow` (already breed×difficulty-scaled via `scale_*`
accessors from tasks 080/081). Thread the **effective** active word's `window_scale` into the
window used by `_on_bra_pressed`'s scoring, composed multiplicatively with the existing
breed×difficulty scale — but **only when the word is not on cooldown** (else scale 1.0 / base).
Keep base "bra" as an exact identity so Normal/base play is unchanged. Add a focused test that
the composed effective window widens when a fresh stronger word is active and reverts to base on
cooldown.

### D. Surface the constraint honestly (minimal)

So the trade-off is legible (not hidden): reflect cooldown state in the menu's Marker-words rows
(092) — e.g. a cooling word shows a brief "on cooldown" / greyed-but-owned treatment — OR at
minimum ensure the fired-word feedback (091/P5-3 later) shows "bra" when a stronger word is
cooling. Keep this lightweight; the full juicy on-screen pop is **P5-3 (deferred)**. Do not add an
in-round button.

## Definition of done / Acceptance criteria

- [x] `MarkerWords` catalog carries per-word `window_scale` + `cooldown`; base "bra" is identity (1.0 / 0).
- [x] **TDD:** cooldown + effect behaviors in §B written red first in `tests/test_marker_words.gd`, then green; 10 new non-empty assertions (488 total / 0 failures).
- [x] Firing a stronger word widens the effective PERFECT window (composed with breed×difficulty) **only while not on cooldown**; base "bra" play is byte-identical to today.
- [x] A fired stronger word enters cooldown for its `cooldown` marks; during cooldown the mark falls back to base "bra" (no hard-fail, round still one tap).
- [x] Base "bra" never cools down and is always available as the default.
- [x] Cooldown state is surfaced honestly: menu word rows show "Hviler" (resting, dimmed gold) when the ACTIVE word is on cooldown; `_play_payoff` plays the effective (fallback) word's clip so the player hears "bra" while the stronger word rests.
- [x] Chosen tie-break rules documented in `scripts/marker_words.gd` class comment and covered by tests: (1) cooldown decrements only on successful marks (fire_active(succeeded=true)); (2) switching away and back preserves per-word cooldown state (dict keyed by word id, not the active slot).
- [x] `nix develop -c bash verify.sh` green (488/0).
- [x] Placeholder-check: tuning values (bra 1.0/0, dyktig 1.15/2, flink 1.20/2, super 1.30/3, kjempebra 1.45/4) are documented as defensible starting values in the class comment with explicit tuning guidance; no un-allowlisted stubs in the diff.

## Implementation notes

**Tuning values chosen (tune under play-test):**
- bra: window_scale 1.00, cooldown 0 — identity, always available (Phase-1/2/3 unchanged)
- dyktig: window_scale 1.15, cooldown 2 — gentle +15% window, 2-mark rest
- flink: window_scale 1.20, cooldown 2 — +20% window, 2-mark rest
- super: window_scale 1.30, cooldown 3 — +30% window, 3-mark rest
- kjempebra: window_scale 1.45, cooldown 4 — +45% window, 4-mark rest

**Window composition seam** (`scripts/main.gd` `_begin_sit()`):
```
var _word_scale := _words.effective_window_scale()
_window = _director.trick_window(_current_trick,
    _difficulty.scale_radius(_breed.perfect_radius()) * _word_scale,
    _difficulty.scale_radius(_breed.ok_radius()))
```
Only the PERFECT radius is widened; the OK radius is unchanged (the wider window is the reward for loading a stronger word). base "bra" → scale 1.0 → byte-identical.

**Fired-word fallback seam** (`scripts/main.gd` `_play_payoff()`):
```
var fired := _words.fire_active(payoff.is_success)
_payoff.set_active_word(fired)
_payoff.play(payoff)
```
`fire_active(is_success)` returns the effective word id. While the active word is cooling, `fired == "bra"` and the base clip sounds. On a MISS/DEAD (is_success=false), no counter moves.

**Menu cooldown hint** (`scripts/trick_menu.gd` `_draw_word_row()`):
An ACTIVE word on cooldown shows "Hviler" (Norwegian: resting) as its badge in dimmed gold (Color(1.0, 0.78, 0.20, 0.70)) so the player sees the trade-off. The name also dims (gold at 0.55 alpha). No in-round button; purely informational in the menu.
