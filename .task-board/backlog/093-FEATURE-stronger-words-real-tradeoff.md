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

- [ ] `MarkerWords` catalog carries per-word `window_scale` + `cooldown`; base "bra" is identity (1.0 / 0).
- [ ] **TDD:** cooldown + effect behaviors in §B written red first in `tests/test_marker_words.gd` (or a new `tests/test_word_cooldown.gd`), then green; non-empty assertions.
- [ ] Firing a stronger word widens the effective PERFECT window (composed with breed×difficulty) **only while not on cooldown**; base "bra" play is byte-identical to today.
- [ ] A fired stronger word enters cooldown for its `cooldown` marks; during cooldown the mark falls back to base "bra" (no hard-fail, round still one tap).
- [ ] Base "bra" never cools down and is always available as the default.
- [ ] Cooldown state is surfaced honestly (menu row treatment and/or fired-word feedback) — no hidden mechanic, no in-round button.
- [ ] Chosen tie-break rules (what decrements cooldown; switch-away behavior) are documented in the model and covered by a test.
- [ ] `nix develop -c bash verify.sh` green.
- [ ] Placeholder-check: the tuning numbers are defensible starting values documented as tunable — not un-attempted stubs; no un-allowlisted marker in the diff.
