# 069 — FIX: coin readout (tofu box · chip overlap · purpose caption)

**Type:** FIX · **Phase:** 3 (current) · **Source:** PO Review 2026-07-01 (`po-review.md`)
directives 1 + 2 + 3 · **Priority:** P0 for this phase (two live bugs on the sole Phase-3
surface + one legibility improvement, all on the same HUD element).

## What it addresses

The one live Phase-3 surface — the top-right coin readout (068) — has three rough edges the
PO caught on the running build (`ae6b0d9`). All three touch the same element, so they are one
cohesive fix:

1. **Tofu box (bug).** `_refresh_coins()` sets `"%d 🪙"` — the 🪙 emoji (U+1FA99) has **no glyph**
   in Godot's `ThemeDB.fallback_font`, so it renders as a hollow missing-glyph box beside the
   digit at both `0` and `10`. Reads as a half-built asset the instant the player looks
   top-right — fails X-4 (reads first / looks the part) / X-6 (quality gates hold).
2. **Chip overlap (bug).** The readout is anchored top-right at y=[20,60], x≈[220,370] (390 wide);
   the selector band is y=[28,80], x=[48,342] and with the full three-chip roster the rightmost
   chip (**Legg deg**, x≈[244,342]) is drawn *under* the coin count — degrading the **signed-off
   P2-1 selector**. (Confirmed from `SELECTOR_OFFSET_TOP=28`, `SELECTOR_HEIGHT=52`,
   `COIN_READOUT_MARGIN=20`, `COIN_READOUT_HEIGHT=40` in `main.gd`.)
3. **Context-free number (improvement).** The bare count climbs with no on-screen sense that
   these are coins *earned toward adopting a dog* (P3-D3 "the collection axis is visible"). The
   earn side works but its purpose is invisible.

**Out of scope (stays owner-gated):** the full adopt UI (coin price + locked state + breed
thumbnail) needs the owner-gated extra breed models — do **not** fake a breed to fill a panel
(BUST-068 residual; keep flagged).

## Technical approach

Replace the emoji `Label` with a small dumb-renderer `CoinReadout extends Control` (same
`_draw`-based split as `TrickSelector` / `LearnedBar` / `TierReadout`): it draws a **gold coin
disc** (filled circle + darker rim, so it renders on any device with no font dependency), the
**balance number**, and a small **"coins"** caption conveying purpose. Give it its **own top
line** above the chip row (push the selector down) so it can never collide with the roster at
any chip count.

**Before** (`scripts/main.gd`):
```gdscript
const SELECTOR_OFFSET_TOP := 28.0
...
func _refresh_coins() -> void:
    if _coin_readout != null:
        _coin_readout.text = "%d 🪙" % _purse.balance   # 🪙 U+1FA99 → tofu box (no glyph)
```
`_setup_coin_readout()` builds a bare `Label` anchored top-right at y=[20,60].

**After** (`scripts/coin_readout.gd`, new dumb-renderer; `scripts/main.gd` wires it):
```gdscript
# scripts/coin_readout.gd
class_name CoinReadout
extends Control
const HEIGHT := 40.0
var _balance := 0
func set_balance(n: int) -> void:
    _balance = maxi(0, n)
    queue_redraw()
## Pure, render-free: the digits the readout shows — NEVER the tofu emoji (unit-locked).
static func balance_text(n: int) -> String:
    return "%d" % maxi(0, n)
func _draw() -> void:
    # gold coin disc (no font glyph) + balance_text(_balance) + "coins" caption
    ...
```
```gdscript
# scripts/main.gd — own top line, selector pushed below it (no overlap at any chip count)
const COIN_READOUT_TOP := 10.0
const SELECTOR_OFFSET_TOP := COIN_READOUT_TOP + CoinReadout.HEIGHT + 14.0  # 64 — below the coin line
...
func _refresh_coins() -> void:
    if _coin_readout != null:
        _coin_readout.set_balance(_purse.balance)
```

Two pure seams are **test-first (TDD)**; the drawn coin + placement are **Visual Review**:
- `CoinReadout.balance_text(n)` returns only ASCII digits — assert it contains **no** `🪙`
  (U+1FA99) and formats `0`, `10`, `999` correctly (locks the tofu bug shut).
- **Non-overlap geometry** as pure constant arithmetic: assert
  `COIN_READOUT_TOP + CoinReadout.HEIGHT <= SELECTOR_OFFSET_TOP` (a regression guard so the coin
  line can never slide back into the chip row).

Follow the `tdd` skill: write both failing tests first (extend `tests/` — e.g.
`test_coin_readout.gd` and a layout assertion in an existing HUD/main test), watch them go red,
then implement. Reuse the existing shared test-mount helpers.

## Acceptance criteria

- [x] TDD: a failing `CoinReadout.balance_text()` test exists first (asserts digits only, **no**
      U+1FA99 emoji, correct for 0/10/999), then passes. *(test_coin_readout.gd — RED 5 fails → GREEN.)*
- [x] TDD: a failing non-overlap geometry test exists first
      (`COIN_READOUT_TOP + CoinReadout.HEIGHT <= SELECTOR_OFFSET_TOP`), then passes. *(RED foot
      50.0 > top 28.0 → GREEN top derived to 64.0.)*
- [x] `_refresh_coins()` no longer emits the coin emoji; no U+1FA99 glyph anywhere in `scripts/`
      (referenced by codepoint in comments only; the literal glyph lives solely in the guard test).
- [x] The coin readout renders a **drawn** gold coin (no font-glyph dependency), the balance
      number, and a **"coins"** caption conveying the collection purpose. *(new `CoinReadout`
      dumb-renderer; .screenshots/069-top-zoom.png.)*
- [x] The coin readout sits on its **own line clear of the chip row** — no overlap with the
      rightmost "Legg deg" chip at the full three-chip roster, 390×844.
- [x] Visual Review at 390×844 (licensed bundle, headless Chromium): coin readout legible over
      bright sky/sun, no tofu box, no chip collision; the P2-1 selector reads clean. Boot clean,
      zero console errors; coins earn (autotap mastered Sitt → readout ticked **0→10 coins**,
      .screenshots/069-play-top.png).
- [x] Placeholder check clean on the diff; `nix develop -c bash verify.sh` green.

## Completion note

Replaced the 068 emoji `Label` (`"%d " + coin-emoji` → tofu box) with a `CoinReadout extends
Control` dumb-renderer that draws a gold coin disc + digits + a "coins" caption (no font-glyph
dependency). Gave it its own top line (`COIN_READOUT_TOP=10`) and **derived** `SELECTOR_OFFSET_TOP`
below it (`=64`) so the chip row can never collide with the count at any roster size. Two pure
seams locked test-first (no-tofu `balance_text`, non-overlap geometry invariant); the drawn coin +
placement verified in live pixels on the licensed bundle. Verify gate green (import·boot·test·export).
