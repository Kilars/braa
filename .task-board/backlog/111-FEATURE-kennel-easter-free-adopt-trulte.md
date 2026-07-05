# 111 — FEATURE: Find the hidden dog — Trulte's free-adopt easter egg

**Type:** FEATURE (TDD for the free-adopt gate → **Visual Review** for the coral ribbon + button)
**Phase:** 8 (Kennel — current)
**Stories:** K-6 (find the hidden dog).
**Depends on:** 109 (adopt spine — spend/persist), 110 (train-with switch). Trulte is `price == 0`
(«Gratis», Hemmelig rarity) and already carries the `secret` flag + «Påskeegg» tag (106).
**Source:** PO Review 2026-07-05 — completes the kennel's browse-and-adopt roster with its surprise.

## What this addresses

Trulte (Malchi) already renders in the grid with her coral «★ Påskeegg» tag (106) and «Gratis» price
chip, and her inspect modal opens (108). But there is no **free-adopt** button — her modal falls through
109's priced-button path, which only shows «Adopter · N mynt» / disabled. K-6: her modal gets the coral
ribbon above the stats and an **«Adopter gratis ♥»** button that costs nothing; after adopting she
becomes owned and trainable like any other dog (via 110's switch).

## Why now

- Small, self-contained capstone once the adopt (109) + switch (110) spine exists — it's the same flow
  with a `price == 0` branch and a coral skin.
- Discoverable by browsing (she's already in the grid) — no external hint, reads as special not broken.

## Technical approach

### 1. Free-adopt gate (TDD first)

The 109 adopt flow already treats `price == 0` as always-affordable (the gate is `price > 0 and not
can_afford`). Assert Trulte's free path explicitly:
- `test_free_adopt_costs_nothing_and_marks_owned` — adopting a `price == 0` secret dog leaves the balance
  unchanged and adds her to the owned set.
- `test_free_adopt_still_guarded_against_double_fire` — the `_kennel_adopt_busy` guard covers her too.

(These extend the 109 adopt-mutation tests; no new economy logic — the branch already exists, this pins
the secret dog's behaviour so a regression fails a test.)

### 2. Coral ribbon + «Adopter gratis ♥» button (Visual Review — `kennel_screen.gd`)

In `_build_adopt_button(detail)` / the modal builder, branch on `detail.secret`:
- Render the **coral ribbon** (`#ff7a85`) above the stat panel (a small labelled band «★ Påskeegg»,
  the star drawn as the 106 `_StarPip` geometry — **not** a font glyph, no tofu).
- The adopt button reads **«Adopter gratis ♥»** on a coral fill; the ♥ is drawn geometry or an approved
  in-font glyph verified to render (reuse the 106 pip approach if the heart risks tofu). It emits the
  same `adopt_requested(id)` → `main._on_kennel_adopt`, which spends 0 and marks her owned.
- After adopt she flips to the owned treatment and (via 110) shows «Tren med Trulte».

### Before
```gdscript
# Trulte's modal falls through the priced-button path — no free-adopt affordance.
func _build_adopt_button(detail): # 109: only «Adopter · N mynt» / disabled
```
### After
```gdscript
func _build_adopt_button(detail):
	if detail.secret:
		return _build_free_adopt_button(detail)   # coral «Adopter gratis ♥» + ribbon, emits adopt_requested
	...
```

## Placeholder / tofu check

- Grep the diff for the placeholder list — none. The star is the 106 `_StarPip` geometry, not `★`;
  verify the ♥ renders in the theme font on the real web build or draw it as geometry (no tofu box).
- No dead button, no faked model (Trulte is a tinted `#e6dccb` stand-in, the honest BUST-068 render).

## Acceptance criteria

- [ ] **TDD first:** the free-adopt (cost-nothing + owned) and double-fire-guard tests written RED → GREEN.
- [ ] Trulte appears in the grid with the coral «★ Påskeegg» tag + «Gratis» price (already shipped 106 —
      regression-check it still reads).
- [ ] Her modal shows the coral ribbon above the stats and an «Adopter gratis ♥» button on a coral fill.
- [ ] Adopting her costs nothing (balance unchanged), marks her owned, and she becomes trainable via the
      110 «Tren med Trulte» switch.
- [ ] She's discoverable by browsing — no external hint — and reads as special, not broken.
- [ ] No tofu: the ★ is drawn geometry (106 `_StarPip`); the ♥ renders correctly or is drawn geometry.
- [ ] `nix develop -c bash verify.sh` green (import·boot·test·export).
- [ ] Visual Review PASS (390×844, real canvas tap): scroll to Trulte → open modal → coral ribbon +
      «Adopter gratis ♥» → adopt → owned treatment, balance unchanged, «Tren med Trulte» available.
